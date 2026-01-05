import type { Request, Response } from 'express';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { addEvidenceSchema, createSaleSchema, listSalesSchema, updateSaleSchema } from './sales.schema';

function actorEmpresaId(req: Request): string {
  const actor = req.user;
  if (!actor?.empresaId) throw new ApiError(401, 'Unauthorized');
  return actor.empresaId;
}

function ok(res: Response, data: any, message = 'OK', status = 200) {
  return res.status(status).json({ ok: true, data, message });
}

function parseDate(value: unknown): Date | null {
  if (typeof value !== 'string' || value.trim().length === 0) return null;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return d;
}

function computeAmountFromDetails(details: any): number | null {
  const items = details?.items;
  if (!Array.isArray(items) || items.length === 0) return null;
  const total = items.reduce((acc: number, it: any) => {
    const qty = typeof it?.quantity === 'number' ? it.quantity : NaN;
    const unit = typeof it?.unitPrice === 'number' ? it.unitPrice : NaN;
    if (!Number.isFinite(qty) || !Number.isFinite(unit)) return acc;
    return acc + qty * unit;
  }, 0);
  if (!Number.isFinite(total) || total <= 0) return null;
  return total;
}

function computeProductSummaryFromDetails(details: any): string | null {
  const items = details?.items;
  if (!Array.isArray(items) || items.length === 0) return null;
  const firstNameRaw = items?.[0]?.name;
  const firstName = typeof firstNameRaw === 'string' ? firstNameRaw.trim() : '';
  if (firstName.length === 0) return null;
  const extraCount = Math.max(0, items.length - 1);
  return extraCount > 0 ? `${firstName} +${extraCount}` : firstName;
}

export async function createSale(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const actor = req.user;
  if (!actor?.userId) throw new ApiError(401, 'Unauthorized');

  const parsed = createSaleSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const body = parsed.data;
  const isLegacy = !!body.thread_id || (!!body.total && !body.product_or_service);

  if (isLegacy) {
    const { thread_id, customer_id, total, detalles } = body;

    const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      let customerId: string | null = customer_id ?? null;
      let threadId: string | null = thread_id ?? null;

      let thread: any = null;

      if (threadId) {
        thread = await tx.crmThread.findFirst({
          where: { id: threadId, empresa_id, deleted_at: null },
        });
        if (!thread) throw new ApiError(404, 'Thread not found');

        if (customerId) {
          const cust = await tx.customer.findFirst({
            where: { id: customerId, empresa_id, deleted_at: null },
          });
          if (!cust) throw new ApiError(404, 'Customer not found');
        }

        if (!customerId) {
          if (thread.customer_id) {
            customerId = thread.customer_id;
          } else {
            const phone = thread.phone_number;
            let cust = await tx.customer.findFirst({
              where: { empresa_id, telefono: phone, deleted_at: null },
            });

            if (!cust) {
              const name =
                thread.display_name && thread.display_name.trim().length > 0
                  ? thread.display_name.trim()
                  : `Cliente WhatsApp ${phone}`;

              cust = await tx.customer.create({
                data: {
                  empresa_id,
                  nombre: name,
                  telefono: phone,
                  origen: 'whatsapp',
                },
              });
            }

            customerId = cust.id;

            thread = await tx.crmThread.update({
              where: { id: threadId },
              data: {
                customer_id: cust.id,
                estado_crm: 'compro',
                sync_version: { increment: 1 },
              },
            });
          }
        } else {
          if (!thread.customer_id) {
            thread = await tx.crmThread.update({
              where: { id: threadId },
              data: {
                customer_id: customerId,
                estado_crm: 'compro',
                sync_version: { increment: 1 },
              },
            });
          } else {
            thread = await tx.crmThread.update({
              where: { id: threadId },
              data: {
                estado_crm: 'compro',
                sync_version: { increment: 1 },
              },
            });
          }
        }
      }

      if (customerId) {
        const cust = await tx.customer.findFirst({
          where: { id: customerId, empresa_id, deleted_at: null },
        });
        if (!cust) throw new ApiError(404, 'Customer not found');
      }

      const sale = await tx.sale.create({
        data: {
          empresa_id,
          thread_id: threadId,
          customer_id: customerId,
          total: total as any,
          detalles: detalles ?? null,
          created_by_user_id: actor?.userId ?? null,
        },
      });

      return { sale, thread };
    });

    return ok(res, { legacy: true, item: result.sale, thread: result.thread }, 'Sale created', 201);
  }

  const soldAt = parseDate(body.sold_at) ?? new Date();

  const computedAmount = body.details ? computeAmountFromDetails(body.details) : null;
  const computedProductOrService = body.details
    ? computeProductSummaryFromDetails(body.details)
    : null;

  const amount = body.amount ?? computedAmount;
  const productOrService = body.product_or_service ?? computedProductOrService;
  if (!amount || !productOrService) {
    throw new ApiError(400, 'Invalid payload: missing amount/product or details.items');
  }

  const created = await prisma.salesRecord.create({
    data: {
      ...(body.id ? { id: body.id } : {}),
      empresa_id,
      user_id: actor.userId,
      customer_name: body.customer_name ?? null,
      customer_phone: body.customer_phone ?? null,
      customer_document: (body as any).customer_document ?? null,
      product_or_service: productOrService,
      amount: amount as any,
      details: (body.details as any) ?? null,
      payment_method: (body.payment_method as any) ?? 'other',
      channel: (body.channel as any) ?? 'other',
      status: (body.status as any) ?? 'confirmed',
      notes: body.notes ?? null,
      sold_at: soldAt,
      evidence_required: body.evidence_required ?? true,
    },
  });

  return ok(res, { item: created }, 'Sale created', 201);
}

export async function listSales(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = listSalesSchema.safeParse({
    q: typeof req.query.q === 'string' ? req.query.q : undefined,
    channel: typeof req.query.channel === 'string' ? req.query.channel : undefined,
    status: typeof req.query.status === 'string' ? req.query.status : undefined,
    payment_method:
      typeof req.query.payment_method === 'string' ? req.query.payment_method : undefined,
    from: typeof req.query.from === 'string' ? req.query.from : undefined,
    to: typeof req.query.to === 'string' ? req.query.to : undefined,
    page: typeof req.query.page === 'string' ? req.query.page : undefined,
    pageSize: typeof req.query.pageSize === 'string' ? req.query.pageSize : undefined,
  });
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid query', parsed.error.flatten());
  }

  const page = Math.max(1, Number(parsed.data.page ?? '1') || 1);
  const pageSize = Math.min(100, Math.max(1, Number(parsed.data.pageSize ?? '20') || 20));
  const skip = (page - 1) * pageSize;

  const from = parseDate(parsed.data.from);
  const to = parseDate(parsed.data.to);

  const where: Prisma.SalesRecordWhereInput = {
    empresa_id,
    deleted: false,
  };

  if (parsed.data.channel) where.channel = parsed.data.channel as any;
  if (parsed.data.status) where.status = parsed.data.status as any;
  if (parsed.data.payment_method) where.payment_method = parsed.data.payment_method as any;
  if (from || to) {
    where.sold_at = {
      ...(from ? { gte: from } : {}),
      ...(to ? { lte: to } : {}),
    };
  }
  if (parsed.data.q) {
    const q = parsed.data.q;
    where.OR = [
      { customer_name: { contains: q, mode: 'insensitive' } },
      { customer_phone: { contains: q, mode: 'insensitive' } },
      { product_or_service: { contains: q, mode: 'insensitive' } },
      { notes: { contains: q, mode: 'insensitive' } },
    ];
  }

  const [items, total] = await Promise.all([
    prisma.salesRecord.findMany({
      where,
      orderBy: [{ sold_at: 'desc' }, { created_at: 'desc' }],
      skip,
      take: pageSize,
      include: {
        user: { select: { id: true, nombre_completo: true, email: true, rol: true } },
        _count: { select: { evidence: true } },
      },
    }),
    prisma.salesRecord.count({ where }),
  ]);

  const normalized = items.map((it: any) => ({
    ...it,
    evidence_count: it?._count?.evidence ?? 0,
    _count: undefined,
  }));

  return ok(res, { items: normalized, page, pageSize, total }, 'OK');
}

export async function getSale(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const { id } = req.params;

  const item = await prisma.salesRecord.findFirst({
    where: { id, empresa_id, deleted: false },
    include: {
      user: { select: { id: true, nombre_completo: true, email: true, rol: true } },
      evidence: { orderBy: { created_at: 'desc' } },
    },
  });
  if (!item) throw new ApiError(404, 'Sale not found');

  return ok(res, { item }, 'OK');
}

export async function updateSale(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const { id } = req.params;

  const parsed = updateSaleSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const existing = await prisma.salesRecord.findFirst({
    where: { id, empresa_id, deleted: false },
  });
  if (!existing) throw new ApiError(404, 'Sale not found');

  const soldAt = parsed.data.sold_at !== undefined ? parseDate(parsed.data.sold_at) : null;
  if (parsed.data.sold_at !== undefined && !soldAt) {
    throw new ApiError(400, 'Invalid sold_at');
  }

  const computedAmount = parsed.data.details
    ? computeAmountFromDetails(parsed.data.details)
    : null;
  const computedProductOrService = parsed.data.details
    ? computeProductSummaryFromDetails(parsed.data.details)
    : null;

  const updated = await prisma.salesRecord.update({
    where: { id },
    data: {
      ...(parsed.data.customer_name !== undefined
        ? { customer_name: parsed.data.customer_name }
        : {}),
      ...(parsed.data.customer_phone !== undefined
        ? { customer_phone: parsed.data.customer_phone }
        : {}),
      ...(parsed.data.customer_document !== undefined
        ? { customer_document: parsed.data.customer_document }
        : {}),
      ...(parsed.data.product_or_service !== undefined
        ? { product_or_service: parsed.data.product_or_service }
        : {}),
      ...(parsed.data.amount !== undefined
        ? { amount: parsed.data.amount as any }
        : computedAmount
          ? { amount: computedAmount as any }
          : {}),
      ...(parsed.data.details !== undefined
        ? { details: (parsed.data.details as any) ?? null }
        : {}),
      ...(parsed.data.product_or_service === undefined && computedProductOrService
        ? { product_or_service: computedProductOrService }
        : {}),
      ...(parsed.data.payment_method !== undefined
        ? { payment_method: parsed.data.payment_method as any }
        : {}),
      ...(parsed.data.channel !== undefined ? { channel: parsed.data.channel as any } : {}),
      ...(parsed.data.status !== undefined ? { status: parsed.data.status as any } : {}),
      ...(parsed.data.notes !== undefined ? { notes: parsed.data.notes } : {}),
      ...(soldAt ? { sold_at: soldAt } : {}),
      ...(parsed.data.evidence_required !== undefined
        ? { evidence_required: parsed.data.evidence_required }
        : {}),
    },
  });

  return ok(res, { item: updated }, 'Sale updated');
}

export async function deleteSale(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const { id } = req.params;

  const existing = await prisma.salesRecord.findFirst({
    where: { id, empresa_id, deleted: false },
  });
  if (!existing) throw new ApiError(404, 'Sale not found');

  await prisma.salesRecord.update({
    where: { id },
    data: { deleted: true, deleted_at: new Date() },
  });

  return ok(res, { id }, 'Sale deleted');
}

export async function addSaleEvidence(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const { id } = req.params;

  const parsed = addEvidenceSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const sale = await prisma.salesRecord.findFirst({
    where: { id, empresa_id, deleted: false },
  });
  if (!sale) throw new ApiError(404, 'Sale not found');

  const urlOrPath =
    (parsed.data as any).file_path ??
    (parsed.data as any).url ??
    (parsed.data as any).text ??
    (parsed.data as any).url_or_path;
  if (!urlOrPath || typeof urlOrPath !== 'string' || urlOrPath.trim().length === 0) {
    throw new ApiError(400, 'Missing evidence value');
  }

  const caption =
    (parsed.data as any).caption ??
    (parsed.data as any).mime_type ??
    (parsed.data as any).text ??
    null;

  const evidence = await prisma.salesEvidence.create({
    data: {
      sale_id: id,
      type: parsed.data.type as any,
      url_or_path: urlOrPath,
      caption: caption ? String(caption).slice(0, 500) : null,
    },
  });

  return ok(res, { item: evidence }, 'Evidence added', 201);
}
