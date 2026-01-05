import type { Request, Response } from 'express';

import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
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
