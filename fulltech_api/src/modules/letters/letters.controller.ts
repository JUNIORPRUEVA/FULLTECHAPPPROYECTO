import type { Request, Response } from 'express';
import PDFDocument from 'pdfkit';

import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { AiLetterService } from '../../services/aiLetterService';
import { EvolutionClient } from '../../services/evolution/evolution_client';
import {
  createLetterExportSchema,
  createLetterSchema,
  letterIdParamsSchema,
  listLettersQuerySchema,
  updateLetterSchema,
} from './letters.schema';

function parseDayBoundary(iso: string | undefined, mode: 'start' | 'end'): Date | undefined {
  if (!iso) return undefined;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return undefined;
  if (mode === 'start') d.setHours(0, 0, 0, 0);
  if (mode === 'end') d.setHours(23, 59, 59, 999);
  return d;
}

export async function listLetters(req: Request, res: Response) {
  const { empresaId } = req.user!;
  const query = listLettersQuerySchema.parse(req.query);

  const where: any = {
    empresa_id: empresaId,
  };

  if (query.status) where.status = query.status;
  if (query.letterType) where.letter_type = query.letterType;

  const from = parseDayBoundary(query.from, 'start');
  const to = parseDayBoundary(query.to, 'end');
  if (from || to) {
    where.created_at = {
      ...(from ? { gte: from } : {}),
      ...(to ? { lte: to } : {}),
    };
  }

  if (query.q && query.q.trim().length > 0) {
    const q = query.q.trim();
    where.OR = [
      { customer_name: { contains: q, mode: 'insensitive' } },
      { customer_phone: { contains: q, mode: 'insensitive' } },
      { subject: { contains: q, mode: 'insensitive' } },
    ];
  }

  const [items, total] = await Promise.all([
    prisma.letter.findMany({
      where,
      orderBy: { created_at: 'desc' },
      take: query.limit,
      skip: query.offset,
      include: {
        exports: { orderBy: { created_at: 'desc' }, take: 1 },
      },
    }),
    prisma.letter.count({ where }),
  ]);

  res.json({ items, total, limit: query.limit, offset: query.offset });
}

export async function getLetter(req: Request, res: Response) {
  const { empresaId } = req.user!;
  const params = letterIdParamsSchema.parse(req.params);

  const item = await prisma.letter.findFirst({
    where: { id: params.id, empresa_id: empresaId },
    include: { exports: { orderBy: { created_at: 'desc' } } },
  });

  if (!item) throw new ApiError(404, 'Letter not found');

  res.json({ item });
}

export async function createLetter(req: Request, res: Response) {
  const { empresaId, userId } = req.user!;
  const body = createLetterSchema.parse(req.body);

  const created = await prisma.letter.create({
    data: {
      empresa_id: empresaId,
      user_id: userId,
      quotation_id: body.quotationId ?? null,

      customer_name: body.customerName,
      customer_phone: body.customerPhone ?? null,
      customer_email: body.customerEmail ?? null,

      letter_type: body.letterType,
      subject: body.subject,
      body: body.body,
      status: body.status,
    },
  });

  res.status(201).json({ item: created });
}

export async function updateLetter(req: Request, res: Response) {
  const { empresaId } = req.user!;
  const params = letterIdParamsSchema.parse(req.params);
  const patch = updateLetterSchema.parse(req.body);

  const existing = await prisma.letter.findFirst({
    where: { id: params.id, empresa_id: empresaId },
  });
  if (!existing) throw new ApiError(404, 'Letter not found');

  const updated = await prisma.letter.update({
    where: { id: params.id },
    data: {
      quotation_id: typeof patch.quotationId !== 'undefined' ? patch.quotationId : undefined,

      customer_name: typeof patch.customerName !== 'undefined' ? patch.customerName : undefined,
      customer_phone: typeof patch.customerPhone !== 'undefined' ? (patch.customerPhone ?? null) : undefined,
      customer_email: typeof patch.customerEmail !== 'undefined' ? (patch.customerEmail ?? null) : undefined,

      letter_type: typeof patch.letterType !== 'undefined' ? patch.letterType : undefined,
      subject: typeof patch.subject !== 'undefined' ? patch.subject : undefined,
      body: typeof patch.body !== 'undefined' ? patch.body : undefined,
      status: typeof patch.status !== 'undefined' ? patch.status : undefined,
    },
  });

  res.json({ item: updated });
}

export async function deleteLetter(req: Request, res: Response) {
  const { empresaId } = req.user!;
  const params = letterIdParamsSchema.parse(req.params);

  const existing = await prisma.letter.findFirst({
    where: { id: params.id, empresa_id: empresaId },
  });
  if (!existing) throw new ApiError(404, 'Letter not found');

  await prisma.letter.delete({ where: { id: params.id } });
  res.json({ ok: true });
}

export async function markLetterSent(req: Request, res: Response) {
  const { empresaId } = req.user!;
  const params = letterIdParamsSchema.parse(req.params);

  const existing = await prisma.letter.findFirst({
    where: { id: params.id, empresa_id: empresaId },
  });
  if (!existing) throw new ApiError(404, 'Letter not found');

  const updated = await prisma.letter.update({
    where: { id: params.id },
    data: { status: 'SENT' },
  });

  res.json({ item: updated });
}

export async function createLetterExport(req: Request, res: Response) {
  const { empresaId } = req.user!;
  const params = letterIdParamsSchema.parse(req.params);
  const body = createLetterExportSchema.parse(req.body);

  const letter = await prisma.letter.findFirst({
    where: { id: params.id, empresa_id: empresaId },
  });
  if (!letter) throw new ApiError(404, 'Letter not found');

  const created = await prisma.letterExport.create({
    data: {
      letter_id: params.id,
      format: body.format,
      file_url: body.fileUrl ?? null,
    },
  });

  res.status(201).json({ item: created });
}

export async function generateWithAI(req: Request, res: Response) {
  const { empresaId, userId } = req.user!;
  const body = req.body;

  // Get company profile
  const company = await prisma.empresa.findUnique({
    where: { id: empresaId },
    include: { company_settings: true },
  });

  if (!company) throw new ApiError(404, 'Company not found');

  const companyProfile = {
    nombre: company.nombre,
    rnc: company.company_settings?.rnc || '',
    telefono: company.company_settings?.telefono || '',
    direccion: company.company_settings?.direccion || '',
    email: company.company_settings?.email || '',
    sitio_web: company.company_settings?.sitio_web || '',
    gerente_nombre: company.company_settings?.nombre_representante || '',
    gerente_cargo: company.company_settings?.cargo_representante || '',
  };

  // Get quotation if provided
  let quotation = null;
  if (body.quotationId) {
    quotation = await prisma.quotation.findFirst({
      where: { id: body.quotationId, empresa_id: empresaId },
      include: { items: true },
    });
  }

  const aiService = new AiLetterService();
  if (!aiService.isEnabled) {
    throw new ApiError(503, 'AI service is not enabled');
  }

  const result = await aiService.generateLetter({
    companyProfile,
    letterType: body.letterType || 'general',
    tone: body.tone || 'Formal',
    quotation: quotation ? {
      numero: quotation.numero,
      total: Number(quotation.total),
      customer_name: quotation.customer_name,
    } : null,
    manualCustomer: body.customer ? {
      name: body.customer.name,
      phone: body.customer.phone || null,
      email: body.customer.email || null,
    } : null,
    manualContext: body.context || body.details || null,
  });

  res.json({ subject: result.subject, body: result.body });
}

async function collectPdfBuffer(doc: PDFKit.PDFDocument): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    doc.end();
  });
}

export async function generatePDF(req: Request, res: Response) {
  const { empresaId } = req.user!;
  const params = letterIdParamsSchema.parse(req.params);

  const letter = await prisma.letter.findFirst({
    where: { id: params.id, empresa_id: empresaId },
    include: {
      empresa: { include: { company_settings: true } },
      quotation: { include: { items: true } },
    },
  });

  if (!letter) throw new ApiError(404, 'Letter not found');

  const settings = letter.empresa.company_settings;
  const doc = new PDFDocument({ size: 'A4', margin: 50 });

  // Header - Company info
  doc.fontSize(18).fillColor('#0D47A1').text(letter.empresa.nombre, { align: 'center' });
  if (settings?.rnc) {
    doc.fontSize(10).fillColor('#666').text(`RNC: ${settings.rnc}`, { align: 'center' });
  }
  if (settings?.telefono) {
    doc.text(`Tel: ${settings.telefono}`, { align: 'center' });
  }
  if (settings?.direccion) {
    doc.text(settings.direccion, { align: 'center' });
  }

  doc.moveDown(2);

  // Letter date
  const fecha = letter.created_at.toLocaleDateString('es-DO', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
  doc.fontSize(10).fillColor('#333').text(fecha, { align: 'right' });
  doc.moveDown();

  // Customer info
  doc.fontSize(12).fillColor('#000');
  doc.text(`Para: ${letter.customer_name}`);
  if (letter.customer_phone) {
    doc.fontSize(10).text(`Tel: ${letter.customer_phone}`);
  }
  doc.moveDown();

  // Subject
  doc.fontSize(14).fillColor('#0D47A1').text(letter.subject, { align: 'center', underline: true });
  doc.moveDown();

  // Body
  doc.fontSize(11).fillColor('#000');
  const lines = letter.body.split('\n');
  lines.forEach((line) => {
    doc.text(line.trim(), { align: 'justify' });
    if (line.trim() === '') doc.moveDown(0.5);
  });

  doc.moveDown(2);

  // Quotation summary if attached
  if (letter.quotation) {
    doc.fontSize(10).fillColor('#666');
    doc.text('---');
    doc.text(`Cotización adjunta: ${letter.quotation.numero}`);
    doc.text(`Total: RD$ ${Number(letter.quotation.total).toLocaleString('es-DO')}`);
  }

  // Footer - Signature
  const pageHeight = doc.page.height;
  const bottomMargin = 80;
  doc.y = pageHeight - bottomMargin;

  doc.fontSize(11).fillColor('#000');
  if (settings?.nombre_representante) {
    doc.text(`Atentamente,`, { align: 'left' });
    doc.moveDown(0.5);
    doc.text(settings.nombre_representante, { align: 'left' });
    if (settings.cargo_representante) {
      doc.fontSize(9).fillColor('#666').text(settings.cargo_representante, { align: 'left' });
    }
  }

  // Social media footer
  doc.moveDown();
  doc.fontSize(8).fillColor('#666');
  if (settings?.sitio_web) {
    doc.text(settings.sitio_web, { align: 'center' });
  }

  const buffer = await collectPdfBuffer(doc);

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `inline; filename="carta-${letter.id}.pdf"`);
  res.send(buffer);
}

export async function sendWhatsApp(req: Request, res: Response) {
  const { empresaId } = req.user!;
  const params = letterIdParamsSchema.parse(req.params);
  const body = req.body;

  const letter = await prisma.letter.findFirst({
    where: { id: params.id, empresa_id: empresaId },
    include: {
      empresa: { include: { company_settings: true } },
      quotation: { include: { items: true } },
    },
  });

  if (!letter) throw new ApiError(404, 'Letter not found');

  // Get chat info
  const chatId = body.chatId;
  if (!chatId) throw new ApiError(400, 'chatId is required');

  const chat = await prisma.crmChat.findFirst({
    where: { id: chatId, empresa_id: empresaId },
  });

  if (!chat) throw new ApiError(404, 'Chat not found');

  const toWaId = String(chat.wa_id ?? '').trim();
  const toPhone = String(chat.phone ?? '').trim();

  if (!toWaId && !toPhone) {
    throw new ApiError(400, 'Chat has no destination (wa_id/phone)');
  }

  // Generate PDF
  const settings = letter.empresa.company_settings;
  const doc = new PDFDocument({ size: 'A4', margin: 50 });

  // Same PDF generation as above
  doc.fontSize(18).fillColor('#0D47A1').text(letter.empresa.nombre, { align: 'center' });
  if (settings?.rnc) {
    doc.fontSize(10).fillColor('#666').text(`RNC: ${settings.rnc}`, { align: 'center' });
  }
  if (settings?.telefono) {
    doc.text(`Tel: ${settings.telefono}`, { align: 'center' });
  }
  if (settings?.direccion) {
    doc.text(settings.direccion, { align: 'center' });
  }

  doc.moveDown(2);

  const fecha = letter.created_at.toLocaleDateString('es-DO', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
  doc.fontSize(10).fillColor('#333').text(fecha, { align: 'right' });
  doc.moveDown();

  doc.fontSize(12).fillColor('#000');
  doc.text(`Para: ${letter.customer_name}`);
  if (letter.customer_phone) {
    doc.fontSize(10).text(`Tel: ${letter.customer_phone}`);
  }
  doc.moveDown();

  doc.fontSize(14).fillColor('#0D47A1').text(letter.subject, { align: 'center', underline: true });
  doc.moveDown();

  doc.fontSize(11).fillColor('#000');
  const lines = letter.body.split('\n');
  lines.forEach((line) => {
    doc.text(line.trim(), { align: 'justify' });
    if (line.trim() === '') doc.moveDown(0.5);
  });

  doc.moveDown(2);

  if (letter.quotation) {
    doc.fontSize(10).fillColor('#666');
    doc.text('---');
    doc.text(`Cotización adjunta: ${letter.quotation.numero}`);
    doc.text(`Total: RD$ ${Number(letter.quotation.total).toLocaleString('es-DO')}`);
  }

  const pageHeight = doc.page.height;
  const bottomMargin = 80;
  doc.y = pageHeight - bottomMargin;

  doc.fontSize(11).fillColor('#000');
  if (settings?.nombre_representante) {
    doc.text(`Atentamente,`, { align: 'left' });
    doc.moveDown(0.5);
    doc.text(settings.nombre_representante, { align: 'left' });
    if (settings.cargo_representante) {
      doc.fontSize(9).fillColor('#666').text(settings.cargo_representante, { align: 'left' });
    }
  }

  doc.moveDown();
  doc.fontSize(8).fillColor('#666');
  if (settings?.sitio_web) {
    doc.text(settings.sitio_web, { align: 'center' });
  }

  const pdfBuffer = await collectPdfBuffer(doc);
  const base64Pdf = pdfBuffer.toString('base64');

  // Send via Evolution API
  let evo: EvolutionClient;
  try {
    evo = new EvolutionClient();
  } catch (e) {
    throw new ApiError(500, `Evolution is not configured: ${String((e as any)?.message ?? e)}`);
  }

  const filename = `carta-${letter.customer_name.replace(/[^a-zA-Z0-9]/g, '_')}.pdf`;
  const caption = `${letter.subject}`;

  const result = await evo.sendDocumentBase64({
    toWaId: toWaId || undefined,
    toPhone: toPhone || undefined,
    base64: base64Pdf,
    fileName: filename,
    caption,
    mimeType: 'application/pdf',
  });

  // Mark as sent
  await prisma.letter.update({
    where: { id: params.id },
    data: { status: 'SENT' },
  });

  res.json({
    ok: true,
    messageId: result.messageId,
    channel: 'whatsapp',
    to: toWaId || toPhone,
    filename,
    raw: result.raw,
  });
}
