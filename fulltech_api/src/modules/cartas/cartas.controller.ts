import type { Request, Response } from 'express';
import path from 'path';
import fs from 'fs';
import { randomUUID } from 'crypto';

import { prisma } from '../../config/prisma';
import { env } from '../../config/env';
import { ApiError } from '../../middleware/errorHandler';
import { AiLetterService } from '../../services/aiLetterService';
import { EvolutionClient } from '../../services/evolution/evolution_client';
import { normalizeWhatsAppIdentity } from '../../utils/whatsapp_identity';

import {
  cartaIdParamsSchema,
  cartasListQuerySchema,
  generateCartaSchema,
  sendCartaWhatsappSchema,
} from './cartas.schema';
import { buildCartaPdfBuffer } from './cartas.pdfkit';

// Prisma client typings can be stale in some deployments (custom SQL migrations in-place).
// In this module we intentionally access columns added via SQL migrations.
const prismaAny = prisma as any;

function typeLabel(t: string): string {
  switch (t) {
    case 'GARANTIA':
      return 'Garantía';
    case 'AGRADECIMIENTO':
      return 'Agradecimiento';
    case 'SEGUIMIENTO':
      return 'Seguimiento';
    case 'COTIZACION_FORMAL':
      return 'Cotización formal';
    case 'DISCULPA_INCIDENCIA':
      return 'Disculpa / Incidencia';
    case 'CONFIRMACION_SERVICIO':
      return 'Confirmación de servicio';
    default:
      return t;
  }
}

function fmtDateEsDo(d: Date): string {
  try {
    return d.toLocaleDateString('es-DO', { year: 'numeric', month: 'long', day: 'numeric' });
  } catch {
    return d.toISOString().slice(0, 10);
  }
}

function uploadsRootAbs(): string {
  return path.resolve(process.cwd(), env.UPLOADS_DIR || 'uploads');
}

function ensureDir(abs: string) {
  fs.mkdirSync(abs, { recursive: true });
}

function safeUnlink(abs: string) {
  try {
    if (fs.existsSync(abs)) fs.unlinkSync(abs);
  } catch {
    // ignore
  }
}

async function getEvolutionClientForUser(opts: { empresaId: string; userId: string }): Promise<EvolutionClient> {
  // Prefer CRM multi-instancia if available.
  try {
    const rows = await prisma.$queryRawUnsafe<any[]>(
      `SELECT nombre_instancia, evolution_base_url, evolution_api_key
       FROM crm_instancias
       WHERE empresa_id = $1::uuid AND user_id = $2::uuid AND is_active = TRUE
       LIMIT 1`,
      opts.empresaId,
      opts.userId,
    );

    const inst = rows?.[0];
    if (inst?.evolution_base_url && inst?.evolution_api_key) {
      return new EvolutionClient({
        baseUrl: String(inst.evolution_base_url),
        apiKey: String(inst.evolution_api_key),
        instanceName: String(inst.nombre_instancia ?? ''),
      });
    }
  } catch {
    // ignore and fall back to env-based Evolution
  }

  return new EvolutionClient();
}

function cartaPdfRelPath(letterId: string): { rel: string; urlPath: string } {
  const now = new Date();
  const ym = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  const rel = path.posix.join('letters', ym, `carta_${letterId}.pdf`);
  const urlPath = `/uploads/${rel}`;
  return { rel, urlPath };
}

function absFromUploadsUrl(urlPath: string): string {
  // urlPath is like /uploads/letters/2026-01/carta_x.pdf
  const rel = urlPath.replace(/^\/uploads\//, '');
  return path.join(uploadsRootAbs(), rel);
}

export async function generateCarta(req: Request, res: Response) {
  const actor = req.user!;
  const parsed = generateCartaSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid carta payload', parsed.error.flatten());
  }
  const body = parsed.data;

  if (body.attachQuotation) {
    if (!body.cotizacionId) throw new ApiError(400, 'cotizacionId is required when attachQuotation=true');
  }

  // Load company settings
  const company = await prismaAny.empresa.findUnique({
    where: { id: actor.empresaId },
    include: { company_settings: true },
  });
  if (!company) throw new ApiError(404, 'Company not found');

  const settings = company.company_settings;
  const companyProfile = {
    nombre: company.nombre,
    rnc: settings?.rnc ?? '',
    telefono: settings?.telefono ?? '',
    direccion: settings?.direccion ?? '',
    email: settings?.email ?? '',
    sitio_web: settings?.sitio_web ?? '',
    instagram_url: settings?.instagram_url ?? null,
    facebook_url: settings?.facebook_url ?? null,
    logo_url: settings?.logo_url ?? null,
  };

  // Optional customer record
  let customer: { id: string; nombre: string; telefono: string } | null = null;
  if (body.clienteId) {
    customer = await prisma.customer.findFirst({
      where: { id: body.clienteId, empresa_id: actor.empresaId },
      select: { id: true, nombre: true, telefono: true },
    });
  }

  // Optional quotation
  let quotation: any | null = null;
  if (body.cotizacionId) {
    quotation = await prisma.quotation.findFirst({
      where: { id: body.cotizacionId, empresa_id: actor.empresaId },
      include: { items: true },
    });
    if (!quotation) throw new ApiError(404, 'Cotización no encontrada');
  }

  // Resolve customer info (prefill from quotation/customer if available)
  const resolvedCustomerName =
    (body.customerName ?? '').trim() ||
    (customer?.nombre ?? '').trim() ||
    (quotation?.customer_name ?? '').trim();

  const resolvedCustomerPhone =
    (body.customerPhone ?? '').trim() ||
    (customer?.telefono ?? '').trim() ||
    (quotation?.customer_phone ?? '').trim() ||
    null;

  if (!resolvedCustomerName) {
    throw new ApiError(400, 'customerName is required (no customer found to prefill)');
  }

  // If quotation is not attached, ensure we have phone (per requirements)
  if (!body.attachQuotation) {
    if (!resolvedCustomerPhone) {
      throw new ApiError(400, 'customerPhone is required when attachQuotation=false and no phone is available');
    }
  }

  // AI
  const ai = new AiLetterService();
  if (!ai.isEnabled) throw new ApiError(503, 'AI service is not enabled');

  const quotationSummary = quotation
    ? {
        numero: quotation.numero,
        total: Number(quotation.total ?? 0),
        items: (quotation.items ?? []).slice(0, 12).map((it: any) => ({
          nombre: String(it.nombre ?? ''),
          cantidad: Number(it.cantidad ?? 0),
          unit_price: Number(it.unit_price ?? 0),
          line_total: Number(it.line_total ?? 0),
        })),
      }
    : null;

  const aiContent = await ai.generateCartaContent({
    companyProfile,
    letterType: body.letterType,
    subject: body.subject,
    userInstructions: body.userInstructions,
    customer: { name: resolvedCustomerName, phone: resolvedCustomerPhone },
    quotationSummary: body.attachQuotation ? quotationSummary : null,
  });

  const combinedBody = [
    aiContent.greeting,
    '',
    ...aiContent.bodyParagraphs,
    '',
    aiContent.closing,
    aiContent.signatureSuggestion,
  ]
    .join('\n')
    .trim();

  const cartaId = randomUUID();

  // PDF
  const date = new Date();
  const pdf = await buildCartaPdfBuffer({
    company: companyProfile,
    dateLabel: fmtDateEsDo(date),
    letterTypeLabel: typeLabel(body.letterType),
    subject: body.subject,
    customerName: resolvedCustomerName,
    customerPhone: resolvedCustomerPhone,
    ai: {
      greeting: aiContent.greeting,
      bodyParagraphs: aiContent.bodyParagraphs,
      closing: aiContent.closing,
      signatureSuggestion: aiContent.signatureSuggestion,
    },
    quotation: body.attachQuotation ? quotationSummary : null,
  });

  const { urlPath } = cartaPdfRelPath(cartaId);
  const absPdf = absFromUploadsUrl(urlPath);
  ensureDir(path.dirname(absPdf));
  fs.writeFileSync(absPdf, pdf);

  const created = await prismaAny.letter.create({
    data: {
      id: cartaId,
      empresa_id: actor.empresaId,
      user_id: actor.userId,
      presupuesto_id: body.presupuestoId,
      cliente_id: customer?.id ?? null,
      quotation_id: body.attachQuotation ? body.cotizacionId ?? null : null,
      customer_name: resolvedCustomerName,
      customer_phone: resolvedCustomerPhone,
      customer_email: null,
      letter_type: body.letterType as any,
      subject: body.subject,
      body: combinedBody,
      status: 'DRAFT',
      user_instructions: body.userInstructions,
      ai_content_json: aiContent as any,
      pdf_path: urlPath,
    } as any,
  });

  res.status(201).json({
    ok: true,
    item: created,
    pdfUrl: `/api/cartas/${created.id}/pdf`,
  });
}

export async function listCartas(req: Request, res: Response) {
  const actor = req.user!;
  const query = cartasListQuerySchema.parse(req.query);

  const where: any = { empresa_id: actor.empresaId };
  if (query.presupuestoId) where.presupuesto_id = query.presupuestoId;
  if (query.clienteId) where.cliente_id = query.clienteId;

  const [items, total] = await Promise.all([
    prismaAny.letter.findMany({
      where,
      orderBy: { created_at: 'desc' },
      take: query.limit,
      skip: query.offset,
    }),
    prismaAny.letter.count({ where }),
  ]);

  res.json({ items, total, limit: query.limit, offset: query.offset });
}

export async function getCarta(req: Request, res: Response) {
  const actor = req.user!;
  const params = cartaIdParamsSchema.parse(req.params);

  const item = await prismaAny.letter.findFirst({
    where: { id: params.id, empresa_id: actor.empresaId },
  });
  if (!item) throw new ApiError(404, 'Carta no encontrada');

  res.json({
    item,
    pdfUrl: `/api/cartas/${item.id}/pdf`,
  });
}

export async function getCartaPdf(req: Request, res: Response) {
  const actor = req.user!;
  const params = cartaIdParamsSchema.parse(req.params);

  const item = await prismaAny.letter.findFirst({
    where: { id: params.id, empresa_id: actor.empresaId },
    select: { id: true, pdf_path: true },
  });
  if (!item) throw new ApiError(404, 'Carta no encontrada');

  const urlPath = String(item.pdf_path ?? '').trim();
  if (!urlPath.startsWith('/uploads/')) {
    throw new ApiError(409, 'Carta PDF no disponible');
  }

  const abs = absFromUploadsUrl(urlPath);
  if (!fs.existsSync(abs)) {
    throw new ApiError(404, 'PDF no encontrado');
  }

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `inline; filename="carta-${item.id}.pdf"`);
  fs.createReadStream(abs).pipe(res);
}

export async function deleteCarta(req: Request, res: Response) {
  const actor = req.user!;
  const params = cartaIdParamsSchema.parse(req.params);

  const existing = await prismaAny.letter.findFirst({
    where: { id: params.id, empresa_id: actor.empresaId },
    select: { id: true, pdf_path: true },
  });
  if (!existing) throw new ApiError(404, 'Carta no encontrada');

  await prismaAny.letter.delete({ where: { id: params.id } });

  const urlPath = String(existing.pdf_path ?? '').trim();
  if (urlPath.startsWith('/uploads/')) {
    safeUnlink(absFromUploadsUrl(urlPath));
  }

  res.json({ ok: true });
}

export async function sendCartaWhatsApp(req: Request, res: Response) {
  const actor = req.user!;
  const params = cartaIdParamsSchema.parse(req.params);
  const parsed = sendCartaWhatsappSchema.safeParse(req.body ?? {});
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const carta = await prismaAny.letter.findFirst({
    where: { id: params.id, empresa_id: actor.empresaId },
    include: { empresa: { include: { company_settings: true } } },
  });
  if (!carta) throw new ApiError(404, 'Carta no encontrada');

  const toRaw = (parsed.data.toPhone ?? carta.customer_phone ?? '').trim();
  if (!toRaw) throw new ApiError(400, 'Carta no tiene teléfono de cliente');

  const normalized = normalizeWhatsAppIdentity({ phone: toRaw });
  if (!normalized.phoneE164Digits) throw new ApiError(400, 'Teléfono inválido para WhatsApp');

  const pdfPath = String(carta.pdf_path ?? '').trim();
  if (!pdfPath.startsWith('/uploads/')) throw new ApiError(409, 'Carta PDF no disponible');

  const abs = absFromUploadsUrl(pdfPath);
  if (!fs.existsSync(abs)) throw new ApiError(404, 'PDF no encontrado');

  const pdfBase64 = fs.readFileSync(abs).toString('base64');
  const filename = `Carta_${carta.id}.pdf`;
  const caption = `${typeLabel(String(carta.letter_type))} - ${String(carta.subject ?? '').trim()}`.slice(0, 400);

  const evo = await getEvolutionClientForUser({ empresaId: actor.empresaId, userId: actor.userId });
  const result = await evo.sendDocumentBase64({
    toPhone: normalized.phoneE164Digits,
    toWaId: normalized.waId ?? undefined,
    base64: pdfBase64,
    fileName: filename,
    caption,
    mimeType: 'application/pdf',
  });

  // Best-effort status update
  try {
    await prismaAny.letter.update({ where: { id: carta.id }, data: { status: 'SENT' } });
  } catch {
    // ignore
  }

  res.json({ ok: true, messageId: result.messageId, to: normalized.waId ?? normalized.phoneE164Digits, raw: result.raw });
}
