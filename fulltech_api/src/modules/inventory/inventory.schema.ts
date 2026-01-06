import { z } from 'zod';

const numberFromUnknown = (v: unknown): number | undefined => {
  if (v === undefined || v === null || v === '') return undefined;
  const n = typeof v === 'number' ? v : Number(v);
  return Number.isFinite(n) ? n : undefined;
};

const intFromUnknown = (v: unknown): number | undefined => {
  const n = numberFromUnknown(v);
  if (n === undefined) return undefined;
  return Math.trunc(n);
};

export const inventoryListProductsSchema = z.object({
  search: z.string().optional(),
  category_id: z.string().uuid().optional(),
  brand: z.string().trim().max(120).optional(),
  supplier_id: z.string().uuid().optional(),
  status: z.enum(['all', 'low', 'out', 'negative']).optional().default('all'),
  sort: z.enum(['name', 'stock', 'updated']).optional().default('updated'),
  page: z.preprocess(intFromUnknown, z.number().int().min(1).default(1)),
  pageSize: z.preprocess(intFromUnknown, z.number().int().min(1).max(200).default(50)),
});

export const inventoryKardexSchema = z.object({
  from: z.string().optional(),
  to: z.string().optional(),
  type: z.enum(['SALE', 'ADJUSTMENT', 'PURCHASE_RECEIPT', 'RETURN']).optional(),
});

export const inventoryAddStockSchema = z.object({
  product_id: z.string().uuid(),
  qty: z.number().positive(),
  ref_type: z.enum(['PURCHASE_RECEIPT', 'ADJUSTMENT', 'RETURN']).default('PURCHASE_RECEIPT'),
  supplier_id: z.string().uuid().optional().nullable(),
  unit_cost: z.number().min(0).optional().nullable(),
  note: z.string().trim().optional().nullable(),
  ref_doc: z.string().trim().optional().nullable(),
});

export const inventoryAdjustStockSchema = z.object({
  product_id: z.string().uuid(),
  qty_change: z.number().refine((n) => n !== 0, 'qty_change must be != 0'),
  note: z.string().trim().optional().nullable(),
});

export const inventoryMinMaxSchema = z.object({
  min_stock: z.number().min(0),
  max_stock: z.number().min(0).optional().nullable(),
  brand: z.string().trim().max(120).optional().nullable(),
  supplier_id: z.string().uuid().optional().nullable(),
});
