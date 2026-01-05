import { z } from 'zod';

export const customerCreateSchema = z.object({
  nombre: z.string().min(2).max(200),
  telefono: z.string().min(5).max(50),
  email: z.string().email().max(180).optional().nullable(),
  direccion: z.string().max(300).optional().nullable(),
  ubicacion_mapa: z.string().max(500).optional().nullable(),
  tags: z.array(z.string().max(50)).optional().nullable(),
  notas: z.string().max(2000).optional().nullable(),
  origen: z.string().max(50).optional(),
});

export const customerUpdateSchema = z.object({
  nombre: z.string().min(2).max(200).optional(),
  telefono: z.string().min(5).max(50).optional(),
  email: z.string().email().max(180).optional().nullable(),
  direccion: z.string().max(300).optional().nullable(),
  ubicacion_mapa: z.string().max(500).optional().nullable(),
  tags: z.array(z.string().max(50)).optional().nullable(),
  notas: z.string().max(2000).optional().nullable(),
  origen: z.string().max(50).optional(),
});

export const customerListQuerySchema = z.object({
  q: z.string().max(200).optional(), // unified search
  search: z.string().max(200).optional(), // legacy
  tags: z
    .union([z.string(), z.array(z.string())])
    .optional()
    .transform((v) => {
      if (v == null) return undefined;
      const arr = Array.isArray(v) ? v : v.split(',');
      return arr.map((x) => x.trim()).filter(Boolean);
    }),
  productId: z.string().max(100).optional(),
  status: z.string().max(50).optional(),
  dateFrom: z.string().optional(),
  dateTo: z.string().optional(),
  limit: z
    .string()
    .optional()
    .transform((v) => (v ? Number(v) : 50))
    .refine((n) => Number.isFinite(n) && n > 0 && n <= 200, 'Invalid limit'),
  offset: z
    .string()
    .optional()
    .transform((v) => (v ? Number(v) : 0))
    .refine((n) => Number.isFinite(n) && n >= 0 && n <= 100000, 'Invalid offset'),
});
