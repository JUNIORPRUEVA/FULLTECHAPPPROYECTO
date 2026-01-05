import type { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import {
  createQuotationSchema,
  listQuotationsQuerySchema,
  quotationIdParamsSchema,
  sendQuotationSchema,
  updateQuotationSchema,
} from './quotations.schema';

const prismaAny = prisma as any;

function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

function computeTotals(input: {
  items: Array<{ cantidad: number; unit_price: number; unit_cost?: number; discount_pct?: number }>;
  itbis_enabled: boolean;
  itbis_rate: number;
}) {
  const items = input.items.map((it) => {
    const qty = it.cantidad;
    const unitPrice = it.unit_price;
    const unitCost = it.unit_cost ?? 0;
    const discountPct = it.discount_pct ?? 0;

    const lineSubtotal = round2(qty * unitPrice);
    const discountAmount = round2(lineSubtotal * (discountPct / 100));
    const lineTotal = round2(lineSubtotal - discountAmount);

    return {
      cantidad: qty,
      unit_price: unitPrice,
      unit_cost: unitCost,
      discount_pct: discountPct,
      discount_amount: discountAmount,
      line_subtotal: lineSubtotal,
      line_total: lineTotal,
    };
  });

  const subtotal = round2(items.reduce((acc, it) => acc + it.line_total, 0));
  const itbisAmount = input.itbis_enabled ? round2(subtotal * input.itbis_rate) : 0;
  const total = round2(subtotal + itbisAmount);

  return {
    items,
    subtotal,
    itbis_amount: itbisAmount,
    total,
  };
}

function normalizePhoneForWhatsapp(phone: string): string {
  // Keep digits only; WhatsApp wa.me expects full international number.
  // We don't force a country code here.
  return phone.replace(/\D+/g, '');
}

function parseDayBoundary(dateStr: string, which: 'start' | 'end'): Date | null {
  // Supports YYYY-MM-DD or full ISO date. Returns UTC boundary.
  if (!dateStr) return null;
  const s = String(dateStr).trim();
  if (!s) return null;
  const iso = s.length === 10 ? `${s}T${which === 'start' ? '00:00:00.000' : '23:59:59.999'}Z` : s;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  return d;
}

async function generateNumero(empresaId: string): Promise<string> {
  // Simple unique-ish number: Q-YYYYMMDD-XXXX
  // (Backed by unique constraint per empresa; collision retries are extremely unlikely)
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const rand = Math.floor(Math.random() * 10000)
    .toString()
    .padStart(4, '0');
  const base = `Q-${y}${m}${day}-${rand}`;

  const exists = await prismaAny.quotation.findFirst({
    where: { empresa_id: empresaId, numero: base },
    select: { id: true },
  });

  if (!exists) return base;
  return generateNumero(empresaId);
}

export async function listQuotations(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const parsed = listQuotationsQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid query', parsed.error.flatten());
  }

  const limit = parsed.data.limit ?? 20;
  const offset = parsed.data.offset ?? 0;
  const q = parsed.data.q?.trim();
  const status = parsed.data.status?.trim();

  const from = parsed.data.from ? parseDayBoundary(parsed.data.from, 'start') : null;
  const to = parsed.data.to ? parseDayBoundary(parsed.data.to, 'end') : null;
  if ((parsed.data.from && !from) || (parsed.data.to && !to)) {
    throw new ApiError(400, 'Invalid date range');
  }

  const where: any = {
    empresa_id: empresaId,
    ...(q
      ? {
          OR: [
            { numero: { contains: q, mode: 'insensitive' } },
            { customer_name: { contains: q, mode: 'insensitive' } },
            { customer_phone: { contains: q, mode: 'insensitive' } },
          ],
        }
      : {}),
    ...(status ? { status } : {}),
    ...(from || to
      ? {
          created_at: {
            ...(from ? { gte: from } : {}),
            ...(to ? { lte: to } : {}),
          },
        }
      : {}),
  };

  const [items, total] = await Promise.all([
    prismaAny.quotation.findMany({
      where,
      orderBy: [{ created_at: 'desc' }, { id: 'desc' }],
      skip: offset,
      take: limit,
      include: { items: true },
    }),
    prismaAny.quotation.count({ where }),
  ]);

  res.json({ items, total, limit, offset });

}


export async function getQuotation(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const parsedParams = quotationIdParamsSchema.safeParse(req.params);
  if (!parsedParams.success) {
    throw new ApiError(400, 'Invalid id', parsedParams.error.flatten());
  }
  const { id } = parsedParams.data;

  const item = await prismaAny.quotation.findFirst({
    where: { id, empresa_id: empresaId },
    include: { items: true },
  });

  if (!item) throw new ApiError(404, 'Quotation not found');
  res.json({ item });
}

export async function createQuotation(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const userId = req.user!.userId;

  const parsed = createQuotationSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid quotation payload', parsed.error.flatten());
  }

  const itbisEnabled = parsed.data.itbis_enabled ?? true;
  const itbisRate = parsed.data.itbis_rate ?? 0.18;

  const totals = computeTotals({
    items: parsed.data.items.map((it) => ({
      cantidad: it.cantidad,
      unit_price: it.unit_price,
      unit_cost: it.unit_cost,
      discount_pct: it.discount_pct,
    })),
    itbis_enabled: itbisEnabled,
    itbis_rate: itbisRate,
  });

  const numero = await generateNumero(empresaId);

  const created = await prisma.$transaction(async (tx) => {
    const txAny = tx as any;

    const quotation = await txAny.quotation.create({
      data: {
        empresa_id: empresaId,
        numero,
        customer_id: parsed.data.customer_id ?? null,
        customer_name: parsed.data.customer_name,
        customer_phone: parsed.data.customer_phone ?? null,
        customer_email: parsed.data.customer_email ?? null,
        itbis_enabled: itbisEnabled,
        itbis_rate: itbisRate,
        subtotal: totals.subtotal,
        itbis_amount: totals.itbis_amount,
        total: totals.total,
        notes: parsed.data.notes ?? null,
        status: 'draft',
        created_by_user_id: userId,
      },
    });

    await txAny.quotationItem.createMany({
      data: parsed.data.items.map((it, idx) => {
        const computed = totals.items[idx];
        return {
          quotation_id: quotation.id,
          product_id: it.product_id ?? null,
          nombre: it.nombre,
          cantidad: computed.cantidad,
          unit_cost: computed.unit_cost,
          unit_price: computed.unit_price,
          discount_pct: computed.discount_pct,
          discount_amount: computed.discount_amount,
          line_subtotal: computed.line_subtotal,
          line_total: computed.line_total,
        };
      }),
    });

    const full = await txAny.quotation.findFirst({
      where: { id: quotation.id },
      include: { items: true },
    });

    return full!;
  });

  res.status(201).json({ item: created });
}

export async function updateQuotation(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const parsedParams = quotationIdParamsSchema.safeParse(req.params);
  if (!parsedParams.success) {
    throw new ApiError(400, 'Invalid id', parsedParams.error.flatten());
  }
  const { id } = parsedParams.data;

  const parsed = updateQuotationSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid quotation payload', parsed.error.flatten());
  }

  const existing = await prismaAny.quotation.findFirst({
    where: { id, empresa_id: empresaId },
    select: { id: true },
  });
  if (!existing) throw new ApiError(404, 'Quotation not found');

  const itbisEnabled = parsed.data.itbis_enabled ?? true;
  const itbisRate = parsed.data.itbis_rate ?? 0.18;

  const totals = computeTotals({
    items: parsed.data.items.map((it) => ({
      cantidad: it.cantidad,
      unit_price: it.unit_price,
      unit_cost: it.unit_cost,
      discount_pct: it.discount_pct,
    })),
    itbis_enabled: itbisEnabled,
    itbis_rate: itbisRate,
  });

  const updated = await prisma.$transaction(async (tx) => {
    const txAny = tx as any;

    await txAny.quotation.update({
      where: { id },
      data: {
        customer_id: parsed.data.customer_id ?? null,
        customer_name: parsed.data.customer_name,
        customer_phone: parsed.data.customer_phone ?? null,
        customer_email: parsed.data.customer_email ?? null,
        itbis_enabled: itbisEnabled,
        itbis_rate: itbisRate,
        subtotal: totals.subtotal,
        itbis_amount: totals.itbis_amount,
        total: totals.total,
        notes: parsed.data.notes ?? null,
        ...(parsed.data.status ? { status: parsed.data.status } : {}),
      },
    });

    await txAny.quotationItem.deleteMany({ where: { quotation_id: id } });
    await txAny.quotationItem.createMany({
      data: parsed.data.items.map((it, idx) => {
        const computed = totals.items[idx];
        return {
          quotation_id: id,
          product_id: it.product_id ?? null,
          nombre: it.nombre,
          cantidad: computed.cantidad,
          unit_cost: computed.unit_cost,
          unit_price: computed.unit_price,
          discount_pct: computed.discount_pct,
          discount_amount: computed.discount_amount,
          line_subtotal: computed.line_subtotal,
          line_total: computed.line_total,
        };
      }),
    });

    const full = await txAny.quotation.findFirst({
      where: { id },
      include: { items: true },
    });

    return full!;
  });

  res.json({ item: updated });
}

export async function duplicateQuotation(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const userId = req.user!.userId;

  const parsedParams = quotationIdParamsSchema.safeParse(req.params);
  if (!parsedParams.success) {
    throw new ApiError(400, 'Invalid id', parsedParams.error.flatten());
  }
  const { id } = parsedParams.data;

  const existing = await prismaAny.quotation.findFirst({
    where: { id, empresa_id: empresaId },
    include: { items: true },
  });
  if (!existing) throw new ApiError(404, 'Quotation not found');

  const numero = await generateNumero(empresaId);
  const itbisEnabled = Boolean(existing.itbis_enabled);
  const itbisRate = Number(existing.itbis_rate ?? 0.18);

  const totals = computeTotals({
    items: (existing.items ?? []).map((it: any) => ({
      cantidad: Number(it.cantidad),
      unit_price: Number(it.unit_price),
      unit_cost: Number(it.unit_cost ?? 0),
      discount_pct: Number(it.discount_pct ?? 0),
    })),
    itbis_enabled: itbisEnabled,
    itbis_rate: itbisRate,
  });

  const created = await prisma.$transaction(async (tx) => {
    const txAny = tx as any;

    const quotation = await txAny.quotation.create({
      data: {
        empresa_id: empresaId,
        numero,
        customer_id: existing.customer_id ?? null,
        customer_name: existing.customer_name,
        customer_phone: existing.customer_phone ?? null,
        customer_email: existing.customer_email ?? null,
        itbis_enabled: itbisEnabled,
        itbis_rate: itbisRate,
        subtotal: totals.subtotal,
        itbis_amount: totals.itbis_amount,
        total: totals.total,
        notes: existing.notes ?? null,
        status: 'draft',
        created_by_user_id: userId,
      },
    });

    await txAny.quotationItem.createMany({
      data: (existing.items ?? []).map((it: any, idx: number) => {
        const computed = totals.items[idx];
        return {
          quotation_id: quotation.id,
          product_id: it.product_id ?? null,
          nombre: it.nombre,
          cantidad: computed.cantidad,
          unit_cost: computed.unit_cost,
          unit_price: computed.unit_price,
          discount_pct: computed.discount_pct,
          discount_amount: computed.discount_amount,
          line_subtotal: computed.line_subtotal,
          line_total: computed.line_total,
        };
      }),
    });

    const full = await txAny.quotation.findFirst({
      where: { id: quotation.id },
      include: { items: true },
    });

    return full!;
  });

  res.status(201).json({ item: created });
}

export async function deleteQuotation(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const parsedParams = quotationIdParamsSchema.safeParse(req.params);
  if (!parsedParams.success) {
    throw new ApiError(400, 'Invalid id', parsedParams.error.flatten());
  }
  const { id } = parsedParams.data;

  const result = await prismaAny.quotation.deleteMany({
    where: { id, empresa_id: empresaId },
  });

  if ((result?.count ?? 0) < 1) throw new ApiError(404, 'Quotation not found');
  res.json({ ok: true });
}

export async function sendQuotation(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const parsedParams = quotationIdParamsSchema.safeParse(req.params);
  if (!parsedParams.success) {
    throw new ApiError(400, 'Invalid id', parsedParams.error.flatten());
  }
  const { id } = parsedParams.data;

  const parsed = sendQuotationSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid send payload', parsed.error.flatten());
  }

  const quotation = await prismaAny.quotation.findFirst({
    where: { id, empresa_id: empresaId },
    include: { items: true },
  });
  if (!quotation) throw new ApiError(404, 'Quotation not found');

  const channel = parsed.data.channel;
  const defaultMessage = `Hola ${quotation.customer_name}, le comparto la cotización ${quotation.numero} por un total de ${quotation.total}.`;
  const message = (parsed.data.message ?? defaultMessage).trim();

  let to: string | null = parsed.data.to ?? null;
  let url: string;

  if (channel === 'whatsapp') {
    const phone = to ?? quotation.customer_phone ?? '';
    const normalized = normalizePhoneForWhatsapp(phone);
    if (!normalized) throw new ApiError(400, 'Missing customer phone');
    to = normalized;
    url = `https://wa.me/${normalized}?text=${encodeURIComponent(message)}`;
  } else {
    const email = to ?? quotation.customer_email ?? '';
    if (!email) throw new ApiError(400, 'Missing customer email');
    to = email;
    const subject = `Cotización ${quotation.numero}`;
    url = `mailto:${encodeURIComponent(email)}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(message)}`;
  }

  // Best-effort status update (do not fail link generation)
  try {
    await prismaAny.quotation.update({ where: { id }, data: { status: 'sent' } });
  } catch (_) {}

  res.json({ ok: true, channel, to, url });
}
