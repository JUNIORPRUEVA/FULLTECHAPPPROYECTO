import type { Request, Response } from 'express';
import { Prisma, type Prisma as PrismaTypes } from '@prisma/client';

import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import {
  inventoryAddStockSchema,
  inventoryAdjustStockSchema,
  inventoryKardexSchema,
  inventoryListProductsSchema,
  inventoryMinMaxSchema,
} from './inventory.schema';
import { assertMinMax, parseDateOrNull, round2 } from './inventory.logic';

function actorEmpresaId(req: Request): string {
  const actor = req.user;
  if (!actor?.empresaId) throw new ApiError(401, 'Unauthorized');
  return actor.empresaId;
}

function actorUserId(req: Request): string | null {
  const actor = req.user;
  return actor?.userId ?? null;
}

function ok(res: Response, data: any, message = 'OK', status = 200): void {
  res.status(status).json({ ok: true, data, message });
}

export async function listInventoryProducts(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = inventoryListProductsSchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const { search, category_id, brand, supplier_id, status, sort, page, pageSize } = parsed.data;

  const q = (search ?? '').trim();
  const brandQ = (brand ?? '').trim();

  const offset = (page - 1) * pageSize;

  const whereParts: Prisma.Sql[] = [
    Prisma.sql`p.empresa_id = ${empresa_id}::uuid`,
    Prisma.sql`p.is_active = true`,
  ];

  if (q.length > 0) {
    const like = `%${q}%`;
    whereParts.push(
      Prisma.sql`(p.nombre ILIKE ${like} OR p.id::text ILIKE ${like})`,
    );
  }
  if (category_id) whereParts.push(Prisma.sql`p.categoria_id = ${category_id}::uuid`);
  if (brandQ.length > 0) {
    const like = `%${brandQ}%`;
    whereParts.push(Prisma.sql`COALESCE(p.brand, '') ILIKE ${like}`);
  }
  if (supplier_id) whereParts.push(Prisma.sql`p.supplier_id = ${supplier_id}::uuid`);

  if (status === 'low') whereParts.push(Prisma.sql`p.stock_qty <= p.min_stock AND p.stock_qty > 0`);
  if (status === 'out') whereParts.push(Prisma.sql`p.stock_qty = 0`);
  if (status === 'negative') whereParts.push(Prisma.sql`p.stock_qty < 0`);

  let whereSql = Prisma.sql`WHERE ${whereParts[0]}`;
  for (let i = 1; i < whereParts.length; i++) {
    whereSql = Prisma.sql`${whereSql} AND ${whereParts[i]}`;
  }

  const orderSql = (() => {
    switch (sort) {
      case 'name':
        return Prisma.sql`ORDER BY p.nombre ASC`;
      case 'stock':
        return Prisma.sql`ORDER BY p.stock_qty DESC, p.nombre ASC`;
      case 'updated':
      default:
        return Prisma.sql`ORDER BY p.updated_at DESC, p.nombre ASC`;
    }
  })();

  const totalRows = await prisma.$queryRaw<Array<{ total: bigint }>>(
    Prisma.sql`
      SELECT COUNT(*)::bigint as total
      FROM "Producto" p
      ${whereSql};
    `,
  );

  const total = Number(totalRows?.[0]?.total ?? 0);

  const rows = await prisma.$queryRaw<
    Array<{
      id: string;
      nombre: string;
      categoria_id: string;
      categoria_nombre: string;
      brand: string | null;
      supplier_id: string | null;
      supplier_name: string | null;
      stock_qty: any;
      min_stock: any;
      max_stock: any;
      precio_compra: any;
      precio_venta: any;
      updated_at: Date;
    }>
  >(
    Prisma.sql`
      SELECT p.id,
             p.nombre,
             p.categoria_id,
             c.nombre as categoria_nombre,
             p.brand,
             p.supplier_id,
             s.name as supplier_name,
             p.stock_qty,
             p.min_stock,
             p.max_stock,
             p.precio_compra,
             p.precio_venta,
             p.updated_at
      FROM "Producto" p
      JOIN "CategoriaProducto" c ON c.id = p.categoria_id
      LEFT JOIN pos_suppliers s ON s.id = p.supplier_id
      ${whereSql}
      ${orderSql}
      LIMIT ${pageSize}
      OFFSET ${offset};
    `,
  );

  const items = rows.map((r) => ({
    id: r.id,
    nombre: r.nombre,
    categoria_id: r.categoria_id,
    categoria_nombre: r.categoria_nombre,
    brand: r.brand,
    supplier_id: r.supplier_id,
    supplier_name: r.supplier_name,
    stock_qty: Number(r.stock_qty),
    min_stock: Number(r.min_stock),
    max_stock: Number(r.max_stock),
    precio_compra: Number(r.precio_compra),
    precio_venta: Number(r.precio_venta),
    updated_at: r.updated_at,
  }));

  ok(res, { items, total, page, pageSize });
}

export async function getProductKardex(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const productId = String(req.params.id || '').trim();
  if (!productId) throw new ApiError(400, 'Missing product id');

  const parsed = inventoryKardexSchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const from = parseDateOrNull(parsed.data.from);
  const to = parseDateOrNull(parsed.data.to);
  const type = parsed.data.type;

  const product = await prisma.producto.findFirst({
    where: { id: productId, empresa_id },
    include: {
      categoria: { select: { id: true, nombre: true } },
    },
  });
  if (!product) throw new ApiError(404, 'Product not found');

  const rows = await prisma.$queryRaw<
    Array<{
      id: string;
      ref_type: string;
      ref_id: string | null;
      qty_change: any;
      unit_cost: any;
      note: string | null;
      created_at: Date;
      created_by_user_id: string | null;
      user_name: string | null;
    }>
  >`
    SELECT m.id,
           m.ref_type,
           m.ref_id,
           m.qty_change,
           m.unit_cost,
           m.note,
           m.created_at,
           m.created_by_user_id,
           u.name as user_name
    FROM pos_stock_movements m
    LEFT JOIN "Usuario" u ON u.id = m.created_by_user_id
    WHERE m.empresa_id = ${empresa_id}::uuid
      AND m.product_id = ${productId}::uuid
      AND (${from ?? null}::timestamp IS NULL OR m.created_at >= ${from ?? null}::timestamp)
      AND (${to ?? null}::timestamp IS NULL OR m.created_at <= ${to ?? null}::timestamp)
      AND (${type ?? null}::text IS NULL OR m.ref_type = ${type ?? null})
    ORDER BY m.created_at DESC
    LIMIT 500;
  `;

  const movements = rows.map((r) => ({
    id: r.id,
    ref_type: r.ref_type,
    ref_id: r.ref_id,
    qty_change: Number(r.qty_change),
    unit_cost: Number(r.unit_cost),
    note: r.note,
    created_at: r.created_at,
    created_by_user_id: r.created_by_user_id,
    user_name: r.user_name,
  }));

  ok(res, {
    product: {
      id: product.id,
      nombre: product.nombre,
      categoria_id: product.categoria_id,
      categoria_nombre: product.categoria?.nombre ?? '',
      brand: (product as any).brand ?? null,
      supplier_id: (product as any).supplier_id ?? null,
      stock_qty: Number(product.stock_qty),
      min_stock: Number(product.min_stock),
      max_stock: Number(product.max_stock),
      precio_compra: Number(product.precio_compra),
      precio_venta: Number(product.precio_venta),
      updated_at: product.updated_at,
    },
    movements,
  });
}

export async function addStock(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const actorId = actorUserId(req);

  const parsed = inventoryAddStockSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const { product_id, qty, ref_type, supplier_id, unit_cost, note, ref_doc } = parsed.data;

  const result = await prisma.$transaction(async (tx: PrismaTypes.TransactionClient) => {
    const locked = await tx.$queryRaw<Array<{ id: string; stock_qty: any; allow_negative_stock: boolean }>>`
      SELECT id, stock_qty, allow_negative_stock
      FROM "Producto"
      WHERE empresa_id = ${empresa_id}::uuid AND id = ${product_id}::uuid
      FOR UPDATE;
    `;

    if (!locked || locked.length === 0) throw new ApiError(404, 'Product not found');

    // qty is positive by schema.
    await tx.producto.updateMany({
      where: { id: product_id, empresa_id },
      data: {
        stock_qty: { increment: qty },
        ...(supplier_id ? { supplier_id: supplier_id } : {}),
        ...(unit_cost != null ? { precio_compra: unit_cost } : {}),
      } as any,
    });

    const fullNote = [note?.trim(), ref_doc?.trim() ? `Ref: ${ref_doc.trim()}` : null]
      .filter((s) => !!s && String(s).trim().length > 0)
      .join(' · ');

    await tx.posStockMovement.create({
      data: {
        empresa_id,
        product_id,
        ref_type,
        ref_id: null,
        qty_change: round2(qty),
        unit_cost: round2(unit_cost ?? 0),
        note: fullNote.trim().length == 0 ? null : fullNote.trim(),
        created_by_user_id: actorId,
      },
    });

    const updated = await tx.producto.findFirst({
      where: { id: product_id, empresa_id },
      include: { categoria: { select: { id: true, nombre: true } } },
    });

    return updated;
  });

  ok(res, result);
}

export async function adjustStock(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const actorId = actorUserId(req);

  const parsed = inventoryAdjustStockSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const { product_id, qty_change, note } = parsed.data;

  const result = await prisma.$transaction(async (tx: PrismaTypes.TransactionClient) => {
    const locked = await tx.$queryRaw<Array<{ id: string; stock_qty: any; allow_negative_stock: boolean }>>`
      SELECT id, stock_qty, allow_negative_stock
      FROM "Producto"
      WHERE empresa_id = ${empresa_id}::uuid AND id = ${product_id}::uuid
      FOR UPDATE;
    `;

    if (!locked || locked.length === 0) throw new ApiError(404, 'Product not found');

    const p = locked[0];
    const stockQty = Number(p.stock_qty);

    if (!p.allow_negative_stock && stockQty + qty_change < 0) {
      throw new ApiError(409, 'Stock cannot go below 0 for this product');
    }

    await tx.producto.updateMany({
      where: { id: product_id, empresa_id },
      data: { stock_qty: { increment: qty_change } },
    });

    await tx.posStockMovement.create({
      data: {
        empresa_id,
        product_id,
        ref_type: 'ADJUSTMENT',
        ref_id: null,
        qty_change: round2(qty_change),
        unit_cost: 0,
        note: note ?? null,
        created_by_user_id: actorId,
      },
    });

    const updated = await tx.producto.findFirst({
      where: { id: product_id, empresa_id },
      include: { categoria: { select: { id: true, nombre: true } } },
    });

    return updated;
  });

  ok(res, result);
}

export async function updateProductMinMax(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const productId = String(req.params.id || '').trim();
  if (!productId) throw new ApiError(400, 'Missing product id');

  const parsed = inventoryMinMaxSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const min_stock = parsed.data.min_stock;
  const max_stock = parsed.data.max_stock;
  assertMinMax(min_stock, max_stock ?? undefined);

  const data: Record<string, any> = {
    min_stock,
  };

  if (max_stock != null) data.max_stock = max_stock;
  if (parsed.data.brand !== undefined) data.brand = parsed.data.brand;
  if (parsed.data.supplier_id !== undefined) data.supplier_id = parsed.data.supplier_id;

  const existing = await prisma.producto.findFirst({ where: { id: productId, empresa_id } });
  if (!existing) throw new ApiError(404, 'Product not found');

  await prisma.producto.updateMany({
    where: { id: productId, empresa_id },
    data: data as any,
  });

  const updated = await prisma.producto.findFirst({ where: { id: productId, empresa_id } });
  ok(res, updated);
}
