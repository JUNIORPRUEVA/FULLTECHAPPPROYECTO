import { z } from 'zod';

const uuidSchema = z.string().uuid();

function intFromUnknown(v: unknown): number {
  if (typeof v === 'number') return Math.trunc(v);
  if (typeof v === 'string') {
    const n = Number(v);
    return Number.isFinite(n) ? Math.trunc(n) : NaN;
  }
  return NaN;
}

export const createCategoriaProductoSchema = z.object({
  nombre: z.string().min(1).max(120),
  descripcion: z.string().max(500).optional(),
  is_active: z.boolean().optional(),
});

export const updateCategoriaProductoSchema = createCategoriaProductoSchema.partial();

const productoCommonSchema = z.object({
  nombre: z.string().min(1).max(180),
  imagen_url: z.string().min(1).max(500),
  categoria_id: uuidSchema,
  is_active: z.boolean().optional(),
  product_type: z.enum(['simple', 'servicio']),

  // Stock fields (POS/TPV)
  stock_qty: z.preprocess(intFromUnknown, z.number().int().min(0)).optional(),
  min_purchase_qty: z.preprocess(intFromUnknown, z.number().int().min(1)).optional(),
  low_stock_threshold: z.preprocess(intFromUnknown, z.number().int().min(0)).optional(),

  // Optional inventory metadata
  supplier_id: uuidSchema.optional().nullable(),
  brand: z.string().trim().max(120).optional().nullable(),
});

const productoSimpleSchema = productoCommonSchema
  .extend({
    product_type: z.literal('simple'),
    precio_compra: z.number().nonnegative(),
    precio_venta: z.number().nonnegative(),
  });

export const productoItemInputSchema = z.object({
  child_producto_id: uuidSchema,
  cantidad: z.number().positive().default(1),
  costo_unitario: z.number().nonnegative(),
  precio_unitario: z.number().nonnegative(),
});

const productoServicioSchema = productoCommonSchema.extend({
  product_type: z.literal('servicio'),
  items: z.array(productoItemInputSchema).min(1),
});

export const createProductoSchema = z.discriminatedUnion('product_type', [
  productoSimpleSchema,
  productoServicioSchema,
]).superRefine((v, ctx) => {
  if (v.product_type === 'simple' && v.precio_venta < v.precio_compra) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'precio_venta must be >= precio_compra',
      path: ['precio_venta'],
    });
  }
});

export const updateProductoSchema = z
  .object({
    nombre: z.string().min(1).max(180).optional(),
    imagen_url: z.string().min(1).max(500).optional(),
    categoria_id: uuidSchema.optional(),
    is_active: z.boolean().optional(),
    product_type: z.enum(['simple', 'servicio']).optional(),
    precio_compra: z.number().nonnegative().optional(),
    precio_venta: z.number().nonnegative().optional(),
    items: z.array(productoItemInputSchema).optional(),
  })
  .refine(
    (v) =>
      v.precio_compra === undefined ||
      v.precio_venta === undefined ||
      v.precio_venta >= v.precio_compra,
    {
      message: 'precio_venta must be >= precio_compra',
      path: ['precio_venta'],
    },
  )
  .refine(
    (v) => {
      if (v.product_type === 'simple' && v.items && v.items.length > 0) return false;
      if (v.product_type === 'servicio' && v.items && v.items.length === 0) return false;
      return true;
    },
    {
      message: 'Invalid items for product_type',
      path: ['items'],
    },
  );
