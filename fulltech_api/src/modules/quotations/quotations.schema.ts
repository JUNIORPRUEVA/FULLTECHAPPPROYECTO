import { z } from 'zod';

export const quotationItemInputSchema = z.object({
  product_id: z.string().uuid().optional().nullable(),
  nombre: z.string().min(1),
  cantidad: z.number().positive(),
  unit_price: z.number().nonnegative(),
  unit_cost: z.number().nonnegative().optional(),
  discount_pct: z.number().min(0).max(100).optional(),
});

export const createQuotationSchema = z.object({
  customer_id: z.string().uuid().optional().nullable(),
  customer_name: z.string().min(1),
  customer_phone: z.string().optional().nullable(),
  customer_email: z.string().email().optional().nullable(),

  itbis_enabled: z.boolean().optional(),
  itbis_rate: z.number().min(0).max(1).optional(),

  notes: z.string().optional().nullable(),

  items: z.array(quotationItemInputSchema).min(1),
});

export const updateQuotationSchema = createQuotationSchema.extend({
  status: z.string().min(1).optional(),
});

export const quotationIdParamsSchema = z.object({
  id: z.string().uuid(),
});

export const sendQuotationSchema = z.object({
  channel: z.enum(['whatsapp', 'email']),
  to: z.string().optional().nullable(),
  message: z.string().optional().nullable(),
});

export const listQuotationsQuerySchema = z.object({
  q: z.string().optional(),
  status: z.string().optional(),
  from: z.string().optional(),
  to: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
  offset: z.coerce.number().int().min(0).optional(),
});
