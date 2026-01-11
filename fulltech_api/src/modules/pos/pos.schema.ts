import { z } from 'zod';

export const posListProductsSchema = z.object({
  search: z.string().optional(),
  lowStock: z
    .union([z.string(), z.boolean()])
    .optional()
    .transform((v) => (v === true || v === 'true' ? true : false)),
  categoryId: z.string().uuid().optional(),
  take: z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().int().min(1).max(1000))
    .optional(),
  skip: z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().int().min(0).max(100000))
    .optional(),
});

export const posCreateSaleSchema = z.object({
  invoice_type: z.enum(['NORMAL', 'FISCAL']),
  customer_id: z.string().uuid().optional().nullable(),
  customer_name: z.string().trim().min(1).optional().nullable(),
  customer_rnc: z.string().trim().min(1).optional().nullable(),
  note: z.string().trim().optional().nullable(),
  discount_total: z.number().min(0).optional().default(0),
  items: z
    .array(
      z.object({
        product_id: z.string().uuid(),
        qty: z.number().positive(),
        unit_price: z.number().min(0),
        discount_amount: z.number().min(0).optional().default(0),
      }),
    )
    .min(1),
});

export const posPaySaleSchema = z.object({
  payment_method: z.enum(['CASH', 'CARD', 'TRANSFER', 'MIXED', 'CREDIT']),
  paid_amount: z.number().min(0).optional().default(0),
  received_amount: z.number().min(0).optional(), // cash convenience
  due_date: z.string().optional().nullable(),
  initial_payment: z.number().min(0).optional().default(0),
  note: z.string().trim().optional().nullable(),

  // Fiscal (optional; required when invoice_type=FISCAL and sale lacks ncf)
  doc_type: z.string().trim().optional().nullable(),
  customer_rnc: z.string().trim().optional().nullable(),
});

export const posListSalesSchema = z.object({
  from: z.string().optional(),
  to: z.string().optional(),
  status: z.string().optional(),
});

export const posNextNcfSchema = z.object({
  doc_type: z.string().trim().min(2),
});

// === NCF sequences (CRUD) ===
export const posCreateFiscalSequenceSchema = z.object({
  doc_type: z.string().trim().min(2),
  series: z.string().trim().optional().nullable(),
  prefix: z.string().trim().optional().nullable(),
  current_number: z
    .preprocess((v) => {
      if (v === undefined || v === null || v === '') return undefined;
      if (typeof v === 'bigint') return v;
      if (typeof v === 'number') return BigInt(Math.max(0, Math.floor(v)));
      if (typeof v === 'string') return BigInt(v);
      return v;
    }, z.bigint().min(0n))
    .optional(),
  max_number: z
    .preprocess((v) => {
      if (v === null || v === undefined || v === '') return null;
      if (typeof v === 'bigint') return v;
      if (typeof v === 'number') return BigInt(Math.max(0, Math.floor(v)));
      if (typeof v === 'string') return BigInt(v);
      return v;
    }, z.bigint().min(0n).nullable())
    .optional(),
  active: z.boolean().optional(),
});

export const posUpdateFiscalSequenceSchema = posCreateFiscalSequenceSchema.partial();

export const posListFiscalSequencesSchema = z.object({
  active: z
    .union([z.string(), z.boolean()])
    .optional()
    .transform((v) => (v === true || v === 'true' ? true : v === false || v === 'false' ? false : undefined)),
});

// === Cashbox (Caja) ===
export const posOpenCashboxSchema = z.object({
  opening_amount: z.number().min(0).optional().default(0),
  note: z.string().trim().optional().nullable(),
});

export const posCashboxMovementSchema = z.object({
  type: z.enum(['IN', 'OUT']),
  amount: z.number().positive(),
  reason: z.string().trim().optional().nullable(),
});

export const posCloseCashboxSchema = z.object({
  counted_cash: z.number(),
  note: z.string().trim().optional().nullable(),
});

export const posListCashboxClosuresSchema = z.object({
  from: z.string().optional(),
  to: z.string().optional(),
});

export const posCreatePurchaseSchema = z.object({
  supplier_id: z.string().uuid().optional().nullable(),
  supplier_name: z.string().trim().min(1),
  status: z.enum(['DRAFT', 'SENT']).optional().default('DRAFT'),
  expected_date: z.string().optional().nullable(),
  note: z.string().trim().optional().nullable(),
  items: z
    .array(
      z.object({
        product_id: z.string().uuid(),
        qty: z.number().positive(),
        unit_cost: z.number().min(0),
      }),
    )
    .min(1),
});

export const posReceivePurchaseSchema = z.object({
  // allow override quantities later; for now receive as-is
  note: z.string().trim().optional().nullable(),
});

export const posListPurchasesSchema = z.object({
  from: z.string().optional(),
  to: z.string().optional(),
  status: z.string().optional(),
});

export const posInventoryAdjustSchema = z.object({
  product_id: z.string().uuid(),
  qty_change: z.number().refine((n) => n !== 0, 'qty_change must be != 0'),
  note: z.string().trim().optional().nullable(),
});

export const posListMovementsSchema = z.object({
  product_id: z.string().uuid().optional(),
  from: z.string().optional(),
  to: z.string().optional(),
});

export const posListCreditSchema = z.object({
  status: z.string().optional(),
  search: z.string().optional(),
});

export const posReportsRangeSchema = z.object({
  from: z.string().optional(),
  to: z.string().optional(),
});

export const posListSuppliersSchema = z.object({
  search: z.string().optional(),
});

export const posCreateSupplierSchema = z.object({
  name: z.string().trim().min(1),
  phone: z.string().trim().optional().nullable(),
  rnc: z.string().trim().optional().nullable(),
  email: z.string().trim().optional().nullable(),
  address: z.string().trim().optional().nullable(),
});

export const posUpdateSupplierSchema = z.object({
  name: z.string().trim().min(1).optional(),
  phone: z.string().trim().optional().nullable(),
  rnc: z.string().trim().optional().nullable(),
  email: z.string().trim().optional().nullable(),
  address: z.string().trim().optional().nullable(),
});
