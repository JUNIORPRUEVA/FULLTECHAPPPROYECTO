import { z } from 'zod';

const paymentMethodSchema = z.enum(['cash', 'card', 'transfer', 'other']);
const channelSchema = z.enum(['whatsapp', 'instagram', 'facebook', 'call', 'walkin', 'other']);
const statusSchema = z.enum(['confirmed', 'pending', 'cancelled']);

const salesLineItemSchema = z
  .object({
    id: z.string().uuid().nullable().optional(),
    productId: z.string().uuid().nullable().optional(),
    name: z.string().trim().min(1),
    quantity: z.number().positive(),
    unitPrice: z.number().nonnegative(),
  })
  .strict();

const salesDetailsSchema = z
  .object({
    items: z.array(salesLineItemSchema).min(1),
  })
  .strict();

export const createSaleSchema = z.object({
  id: z.string().uuid().optional(),
  // New API
  customer_name: z.string().trim().min(1).optional(),
  customer_phone: z.string().trim().min(1).optional(),
  customer_document: z.string().trim().min(1).optional(),
  product_or_service: z.string().trim().min(1).optional(),
  amount: z.number().positive().optional(),
  payment_method: paymentMethodSchema.optional(),
  channel: channelSchema.optional(),
  status: statusSchema.optional(),
  notes: z.string().trim().optional(),
  sold_at: z.union([z.string().datetime(), z.string().min(1)]).optional(),
  evidence_required: z.boolean().optional(),
  details: salesDetailsSchema.optional().nullable(),

  // Legacy compatibility
  thread_id: z.string().uuid().optional(),
  customer_id: z.string().uuid().optional(),
  total: z.number().positive().optional(),
  detalles: z.any().optional(),
}).refine(
  (b) =>
    (b.details !== undefined && b.details !== null) ||
    (b.product_or_service !== undefined && b.amount !== undefined) ||
    (b.total !== undefined && b.total > 0),
  {
    message: 'Provide details.items, (product_or_service + amount), or legacy total',
  },
);

export const updateSaleSchema = z.object({
  customer_name: z.string().trim().min(1).optional(),
  customer_phone: z.string().trim().min(1).optional(),
  customer_document: z.string().trim().min(1).optional(),
  product_or_service: z.string().trim().min(1).optional(),
  amount: z.number().positive().optional(),
  payment_method: paymentMethodSchema.optional(),
  channel: channelSchema.optional(),
  status: statusSchema.optional(),
  notes: z.string().trim().optional(),
  sold_at: z.union([z.string().datetime(), z.string().min(1)]).optional(),
  evidence_required: z.boolean().optional(),
  details: salesDetailsSchema.optional().nullable(),
}).refine((b) => Object.keys(b).length > 0, { message: 'No fields to update' });

export const listSalesSchema = z.object({
  q: z.string().trim().optional(),
  channel: channelSchema.optional(),
  status: statusSchema.optional(),
  payment_method: paymentMethodSchema.optional(),
  from: z.string().optional(),
  to: z.string().optional(),
  page: z.string().optional(),
  pageSize: z.string().optional(),
});

export const addEvidenceSchema = z.object({
  type: z.enum(['image', 'pdf', 'link', 'text']),
  url: z.string().trim().min(1).optional(),
  text: z.string().trim().min(1).optional(),
  file_path: z.string().trim().min(1).optional(),
  mime_type: z.string().trim().min(1).optional(),
}).refine(
  (b) => {
    if (b.type === 'link') return !!b.url;
    if (b.type === 'text') return !!b.text;
    if (b.type === 'image' || b.type === 'pdf') return !!b.file_path;
    return false;
  },
  { message: 'Evidence payload is incomplete for the selected type' },
);
