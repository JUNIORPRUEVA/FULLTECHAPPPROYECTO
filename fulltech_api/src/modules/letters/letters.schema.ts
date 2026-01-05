import { z } from 'zod';

export const letterTypeSchema = z.enum([
  'GARANTIA',
  'AGRADECIMIENTO',
  'SEGUIMIENTO',
  'CONFIRMACION_INSTALACION',
  'RECORDATORIO_PAGO',
  'RECHAZO',
  'PERSONALIZADA',
]);

export const letterStatusSchema = z.enum(['DRAFT', 'SENT']);

export const letterIdParamsSchema = z.object({
  id: z.string().uuid(),
});

export const listLettersQuerySchema = z.object({
  q: z.string().max(200).optional(),
  letterType: letterTypeSchema.optional(),
  status: letterStatusSchema.optional(),
  from: z.string().datetime().optional(),
  to: z.string().datetime().optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});

export const createLetterSchema = z.object({
  quotationId: z.string().uuid().optional().nullable(),

  customerName: z.string().min(2).max(200),
  customerPhone: z.string().max(50).optional().nullable(),
  customerEmail: z.string().email().max(180).optional().nullable(),

  letterType: letterTypeSchema,
  subject: z.string().min(1).max(400),
  body: z.string().min(1).max(20000),
  status: letterStatusSchema.optional().default('DRAFT'),
});

export const updateLetterSchema = createLetterSchema.partial().extend({
  status: letterStatusSchema.optional(),
});

export const createLetterExportSchema = z.object({
  format: z.enum(['PDF']).default('PDF'),
  fileUrl: z.string().max(500).optional().nullable(),
});
