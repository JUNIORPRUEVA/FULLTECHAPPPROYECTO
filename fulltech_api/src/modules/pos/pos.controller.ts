import type { Request, Response } from 'express';
import { Prisma, type Prisma as PrismaTypes } from '@prisma/client';

import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import {
  posCreatePurchaseSchema,
  posCreateSaleSchema,
  posInventoryAdjustSchema,
  posListCreditSchema,
  posListMovementsSchema,
  posListProductsSchema,
  posListPurchasesSchema,
  posListSalesSchema,
  posNextNcfSchema,
  posReceivePurchaseSchema,
  posPaySaleSchema,
  posReportsRangeSchema,
  posListSuppliersSchema,
  posCreateSupplierSchema,
  posUpdateSupplierSchema,
  posRefundSaleSchema,
} from './pos.schema';
import { parseDateOrNull, round2, suggestReorderQty, wouldBlockStock } from './pos.logic';

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

const ITBIS_RATE = 0.18;

function formatNcf(docType: string, num: bigint, series?: string | null, prefix?: string | null): string {
  // Dominican NCF commonly: B01 + 8 digits.
  // We keep it predictable and configurable with optional series/prefix.
  const padded = String(num).padStart(8, '0');
  return `${series ?? ''}${prefix ?? ''}${docType}${padded}`;
}

async function generateNextNcf(tx: PrismaTypes.TransactionClient, empresa_id: string, doc_type: string) {
  // One-statement atomic increment: UPDATE ... RETURNING.
  // Avoids race conditions without requiring explicit SELECT FOR UPDATE.
  const rows = await tx.$queryRaw<
    Array<{
      id: string;
      current_number: bigint;
      max_number: bigint | null;
      active: boolean;
      series: string | null;
      prefix: string | null;
    }>
  >`
    UPDATE pos_fiscal_sequences
    SET current_number = current_number + 1,
        updated_at = now()
    WHERE empresa_id = ${empresa_id}::uuid
      AND doc_type = ${doc_type}
      AND active = true
      AND (max_number IS NULL OR current_number < max_number)
    RETURNING id, current_number, max_number, active, series, prefix;
  `;

  if (!rows || rows.length === 0) {
    throw new ApiError(400, 'NCF sequence not configured or exhausted');
  }

  const row = rows[0];
  return {
    sequence_id: row.id,
    ncf: formatNcf(doc_type, row.current_number, row.series, row.prefix),
    current_number: row.current_number,
  };
}

export async function listPosProducts(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = posListProductsSchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const { search, lowStock, categoryId, take, skip } = parsed.data;

  const q = (search ?? '').trim();

  const items = await prisma.producto.findMany({
    where: {
      empresa_id,
      is_active: true,
      ...(q.length > 0 ? { nombre: { contains: q, mode: 'insensitive' } } : {}),
      ...(categoryId ? { categoria_id: categoryId } : {}),
    },
    include: {
      categoria: { select: { id: true, nombre: true } },
    },
    orderBy: [{ search_count: 'desc' }, { nombre: 'asc' }],
    take: take ?? 200,
    skip: skip ?? 0,
  });

  const filtered = lowStock
    ? items.filter((p) => Number(p.stock_qty) <= Number(p.min_stock))
    : items;

  const data = filtered.map((p) => {
    const stockQty = Number(p.stock_qty);
    const minStock = Number(p.min_stock);
    const maxStock = Number(p.max_stock);

    return {
      id: p.id,
      nombre: p.nombre,
      precio_venta: Number(p.precio_venta),
      cost_price: Number(p.precio_compra),
      stock_qty: stockQty,
      // min_stock is used as low-stock threshold in POS.
      min_stock: minStock,
      max_stock: maxStock,
      min_purchase_qty: (p as any).min_purchase_qty ?? 1,
      low_stock_threshold: minStock,
      allow_negative_stock: p.allow_negative_stock,
      low_stock: stockQty <= minStock,
      suggested_reorder_qty: suggestReorderQty({ stockQty, minStock, maxStock }),
      categoria: p.categoria ? { id: p.categoria.id, nombre: p.categoria.nombre } : null,
      imagen_url: p.imagen_url,
    };
  });

  ok(res, data);
}

export async function listPosSuppliers(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = posListSuppliersSchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const q = (parsed.data.search ?? '').trim();

  const items = await prisma.posSupplier.findMany({
    where: {
      empresa_id,
      ...(q.length > 0
        ? {
            OR: [
              { name: { contains: q, mode: 'insensitive' } },
              { phone: { contains: q, mode: 'insensitive' } },
              { rnc: { contains: q, mode: 'insensitive' } },
              { email: { contains: q, mode: 'insensitive' } },
            ],
          }
        : {}),
    },
    orderBy: [{ name: 'asc' }],
    take: 200,
  });

  ok(res, items);
}

export async function createPosSupplier(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = posCreateSupplierSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const body = parsed.data;

  const created = await prisma.posSupplier.create({
    data: {
      empresa_id,
      name: body.name,
      phone: body.phone ?? null,
      rnc: body.rnc ?? null,
      email: body.email ?? null,
      address: body.address ?? null,
    },
  });

  ok(res, created, 'Created', 201);
}

export async function updatePosSupplier(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const id = String(req.params.id);

  const parsed = posUpdateSupplierSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const existing = await prisma.posSupplier.findFirst({ where: { id, empresa_id } });
  if (!existing) throw new ApiError(404, 'Supplier not found');

  const body = parsed.data;

  const updated = await prisma.posSupplier.update({
    where: { id },
    data: {
      ...(body.name !== undefined ? { name: body.name } : {}),
      ...(body.phone !== undefined ? { phone: body.phone } : {}),
      ...(body.rnc !== undefined ? { rnc: body.rnc } : {}),
      ...(body.email !== undefined ? { email: body.email } : {}),
      ...(body.address !== undefined ? { address: body.address } : {}),
    },
  });

  ok(res, updated);
}

export async function deletePosSupplier(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const id = String(req.params.id);

  const existing = await prisma.posSupplier.findFirst({ where: { id, empresa_id } });
  if (!existing) throw new ApiError(404, 'Supplier not found');

  await prisma.$transaction(async (tx: PrismaTypes.TransactionClient) => {
    await tx.posPurchaseOrder.updateMany({
      where: { empresa_id, supplier_id: id },
      data: { supplier_id: null },
    });

    await tx.posSupplier.delete({ where: { id } });
  });

  ok(res, { id });
}

export async function createPosSale(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const createdBy = actorUserId(req);

  const parsed = posCreateSaleSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const body = parsed.data;

  const productIds = [...new Set(body.items.map((it) => it.product_id))];
  const products = await prisma.producto.findMany({
    where: { empresa_id, id: { in: productIds } },
    select: { id: true, nombre: true },
  });

  if (products.length !== productIds.length) {
    throw new ApiError(400, 'One or more products not found');
  }

  const byId = new Map(products.map((p) => [p.id, p]));

  // Invoice number: stable + unique enough per empresa.
  const now = new Date();
  const ymd = now.toISOString().slice(0, 10).replace(/-/g, '');
  const invoice_no = `POS-${ymd}-${String(now.getTime()).slice(-6)}`;

  const itemsComputed = body.items.map((it) => {
    const prod = byId.get(it.product_id)!;
    const qty = round2(it.qty);
    const unit = round2(it.unit_price);
    const disc = round2(it.discount_amount ?? 0);

    const lineSub = Math.max(0, round2(qty * unit - disc));
    const itbis = round2(lineSub * ITBIS_RATE);
    const lineTotal = round2(lineSub + itbis);

    return {
      product_id: it.product_id,
      product_name: prod.nombre,
      qty,
      unit_price: unit,
      discount_amount: disc,
      itbis_amount: itbis,
      line_total: lineTotal,
    };
  });

  const subtotal = round2(itemsComputed.reduce((acc, it) => acc + it.qty * it.unit_price, 0));
  const baseAfterLineDiscounts = round2(
    itemsComputed.reduce((acc, it) => acc + Math.max(0, it.qty * it.unit_price - it.discount_amount), 0),
  );

  const discount_total = round2(body.discount_total ?? 0);
  const taxable = Math.max(0, round2(baseAfterLineDiscounts - discount_total));
  const itbis_total = round2(taxable * ITBIS_RATE);
  const total = round2(taxable + itbis_total);

  const created = await prisma.$transaction(async (tx: PrismaTypes.TransactionClient) => {
    const sale = await tx.posSale.create({
      data: {
        empresa_id,
        invoice_no,
        invoice_type: body.invoice_type,
        ncf: null,
        customer_id: body.customer_id ?? null,
        customer_name: body.customer_name ?? null,
        customer_rnc: body.customer_rnc ?? null,
        status: 'DRAFT',
        payment_method: null,
        subtotal,
        discount_total,
        itbis_total,
        total,
        paid_amount: 0,
        change_amount: 0,
        note: body.note ?? null,
        created_by_user_id: createdBy,
        updated_at: new Date(),
        items: {
          createMany: {
            data: itemsComputed.map((it) => ({
              empresa_id,
              product_id: it.product_id,
              product_name: it.product_name,
              qty: it.qty,
              unit_price: it.unit_price,
              discount_amount: it.discount_amount,
              itbis_amount: it.itbis_amount,
              line_total: it.line_total,
            })),
          },
        },
      },
      include: { items: true },
    });

    return sale;
  });

  ok(res, created, 'Created', 201);
}

export async function getPosSale(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const id = String(req.params.id);

  const sale = await prisma.posSale.findFirst({
    where: { id, empresa_id },
    include: { items: { orderBy: { product_name: 'asc' } } },
  });

  if (!sale) throw new ApiError(404, 'Sale not found');
  ok(res, sale);
}

export async function listPosSales(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = posListSalesSchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const from = parseDateOrNull(parsed.data.from);
  const to = parseDateOrNull(parsed.data.to);
  const status = parsed.data.status?.trim();

  const items = await prisma.posSale.findMany({
    where: {
      empresa_id,
      ...(status && status.length > 0 ? { status } : {}),
      ...(from || to
        ? {
            created_at: {
              ...(from ? { gte: from } : {}),
              ...(to ? { lte: to } : {}),
            },
          }
        : {}),
    },
    orderBy: { created_at: 'desc' },
    take: 200,
  });

  ok(res, items);
}

export async function payPosSale(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const actorId = actorUserId(req);

  const saleId = String(req.params.id);

  const parsed = posPaySaleSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const body = parsed.data;

  const result = await prisma.$transaction(async (tx: PrismaTypes.TransactionClient) => {
    const sale = await tx.posSale.findFirst({
      where: { id: saleId, empresa_id },
      include: { items: true },
    });

    if (!sale) throw new ApiError(404, 'Sale not found');
    if (sale.status !== 'DRAFT') throw new ApiError(409, 'Sale is not in DRAFT');

    // Fiscal validation
    let ncfToUse: string | null = sale.ncf ?? null;

    if (sale.invoice_type === 'FISCAL') {
      const rnc = (body.customer_rnc ?? sale.customer_rnc ?? '').trim();
      if (!rnc) throw new ApiError(400, 'customer_rnc is required for FISCAL invoices');

      if (!ncfToUse) {
        const docType = (body.doc_type ?? '').trim();
        if (!docType) throw new ApiError(400, 'doc_type is required to generate NCF');
        const next = await generateNextNcf(tx, empresa_id, docType);
        ncfToUse = next.ncf;
      }
    }

    const items = sale.items;
    if (!items || items.length === 0) throw new ApiError(400, 'Sale has no items');

    // Aggregate qty per product (integer semantics)
    const qtyByProduct = new Map<string, number>();
    for (const it of items) {
      const qty = Math.trunc(Number(it.qty));
      qtyByProduct.set(it.product_id, (qtyByProduct.get(it.product_id) ?? 0) + qty);
    }

    const productIds = [...qtyByProduct.keys()];

    // Lock products for stock check/update.
    const lockedProducts = await tx.$queryRaw<
      Array<{ id: string; stock_qty: any; allow_negative_stock: boolean }>
    >(Prisma.sql`
      SELECT id, stock_qty, allow_negative_stock
      FROM "Producto"
      WHERE empresa_id = ${empresa_id}::uuid
        AND id IN (${Prisma.join(productIds.map((id) => Prisma.sql`${id}::uuid`))})
      FOR UPDATE
    `);

    if (lockedProducts.length !== productIds.length) {
      throw new ApiError(400, 'One or more products not found for this empresa');
    }

    const insufficient: Array<{ product_id: string; requested: number; available: number }> = [];
    for (const p of lockedProducts) {
      const qtyOut = qtyByProduct.get(p.id) ?? 0;
      const stockQty = Math.trunc(Number(p.stock_qty));

      // Safety-first: do not allow oversell (ignore allow_negative_stock).
      const block = wouldBlockStock({ allow_negative_stock: false, stock_qty: stockQty }, qtyOut);
      if (block) {
        insufficient.push({ product_id: p.id, requested: qtyOut, available: Math.max(0, stockQty) });
      }
    }
    if (insufficient.length > 0) {
      throw new ApiError(409, 'Insufficient stock', { items: insufficient }, 'INSUFFICIENT_STOCK');
    }

    // Payment calculations
    const total = Number(sale.total);
    const paidAmount = body.payment_method === 'CREDIT' ? Number(body.initial_payment ?? 0) : Number(body.paid_amount ?? body.received_amount ?? 0);

    if (body.payment_method !== 'CREDIT' && paidAmount + 1e-9 < total) {
      throw new ApiError(400, 'paid_amount must be >= total for non-credit payments');
    }

    const changeAmount = body.payment_method === 'CASH' ? Math.max(0, round2(paidAmount - total)) : 0;

    // Apply stock updates + movements.
    for (const p of lockedProducts) {
      const qtyOut = qtyByProduct.get(p.id) ?? 0;
      if (qtyOut <= 0) continue;

      const beforeStock = Math.trunc(Number(p.stock_qty));
      const afterStock = beforeStock - qtyOut;

      await tx.producto.update({
        where: { id: p.id },
        data: {
          stock_qty: { decrement: qtyOut },
        },
      });

      await tx.posStockMovement.create({
        data: {
          empresa_id,
          product_id: p.id,
          ref_type: 'SALE',
          ref_id: sale.id,
          qty_change: -qtyOut,
          movement_type: 'SALE_DEDUCT',
          qty: qtyOut,
          before_stock: beforeStock,
          after_stock: afterStock,
          unit_cost: 0,
          note: 'POS sale',
          created_by_user_id: actorId,
        },
      });
    }

    const status = body.payment_method === 'CREDIT' ? 'CREDIT' : 'PAID';

    const updated = await tx.posSale.update({
      where: { id: sale.id },
      data: {
        ncf: ncfToUse,
        customer_rnc: body.customer_rnc ?? sale.customer_rnc,
        status,
        payment_method: body.payment_method,
        paid_amount: round2(paidAmount),
        change_amount: round2(changeAmount),
        note: body.note ?? sale.note,
        updated_at: new Date(),
      },
      include: { items: true },
    });

    if (status === 'CREDIT') {
      const due = parseDateOrNull(body.due_date) ?? null;
      const paid = round2(Number(body.initial_payment ?? 0));
      const balance = round2(Math.max(0, total - paid));

      await tx.posCreditAccount.create({
        data: {
          empresa_id,
          sale_id: sale.id,
          customer_id: sale.customer_id,
          customer_name: sale.customer_name ?? 'Cliente',
          total,
          paid,
          balance,
          due_date: due,
          status: balance <= 0 ? 'PAID' : paid > 0 ? 'PARTIAL' : 'OPEN',
        },
      });
    }

    return updated;
  });

  ok(res, result);
}

export async function cancelPosSale(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const actorId = actorUserId(req);
  const saleId = String(req.params.id);

  const result = await prisma.$transaction(async (tx: PrismaTypes.TransactionClient) => {
    const sale = await tx.posSale.findFirst({
      where: { id: saleId, empresa_id },
      include: { items: true },
    });

    if (!sale) throw new ApiError(404, 'Sale not found');
    if (sale.status === 'CANCELLED') return sale;

    // Only revert stock if already affected.
    const shouldRevert = sale.status === 'PAID' || sale.status === 'CREDIT';

    if (shouldRevert) {
      const qtyByProduct = new Map<string, number>();
      for (const it of sale.items) {
        qtyByProduct.set(it.product_id, (qtyByProduct.get(it.product_id) ?? 0) + Number(it.qty));
      }
      const productIds = [...qtyByProduct.keys()];

      const lockedProducts = await tx.$queryRaw<Array<{ id: string; stock_qty: any }>>(
        Prisma.sql`
          SELECT id, stock_qty
          FROM "Producto"
          WHERE empresa_id = ${empresa_id}::uuid
            AND id IN (${Prisma.join(productIds.map((id) => Prisma.sql`${id}::uuid`))})
          FOR UPDATE
        `,
      );

      for (const p of lockedProducts) {
        const qtyIn = qtyByProduct.get(p.id) ?? 0;
        if (qtyIn <= 0) continue;

        const beforeStock = Math.trunc(Number(p.stock_qty));
        const afterStock = beforeStock + qtyIn;

        await tx.producto.update({
          where: { id: p.id },
          data: {
            stock_qty: { increment: qtyIn },
          },
        });

        await tx.posStockMovement.create({
          data: {
            empresa_id,
            product_id: p.id,
            ref_type: 'RETURN',
            ref_id: sale.id,
            qty_change: qtyIn,
            movement_type: 'CANCEL_RESTORE',
            qty: qtyIn,
            before_stock: beforeStock,
            after_stock: afterStock,
            unit_cost: 0,
            note: 'POS sale cancel',
            created_by_user_id: actorId,
          },
        });
      }

      // If credit exists, remove it.
      await tx.posCreditAccount.deleteMany({ where: { empresa_id, sale_id: sale.id } });
    }

    const updated = await tx.posSale.update({
      where: { id: sale.id },
      data: { status: 'CANCELLED', updated_at: new Date() },
      include: { items: true },
    });

    return updated;
  });

  ok(res, result);
}

export async function refundPosSale(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const actorId = actorUserId(req);
  const saleId = String(req.params.id);

  const parsed = posRefundSaleSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const body = parsed.data;

  const result = await prisma.$transaction(async (tx: PrismaTypes.TransactionClient) => {
    const sale = await tx.posSale.findFirst({
      where: { id: saleId, empresa_id },
      include: { items: true },
    });
    if (!sale) throw new ApiError(404, 'Sale not found');

    // Only sales that already affected stock can be refunded.
    const stockAffected = sale.status === 'PAID' || sale.status === 'CREDIT' || sale.status === 'PARTIAL_REFUNDED';
    if (!stockAffected && sale.status !== 'REFUNDED') {
      throw new ApiError(409, 'Sale is not refundable', { status: sale.status }, 'SALE_NOT_REFUNDABLE');
    }

    if (sale.status === 'REFUNDED') return sale;

    const soldQtyByProduct = new Map<string, number>();
    for (const it of sale.items) {
      soldQtyByProduct.set(it.product_id, (soldQtyByProduct.get(it.product_id) ?? 0) + Math.trunc(Number(it.qty)));
    }

    // Sum previously refunded quantities (idempotency + partial refunds)
    const prevRefundRows = await tx.posStockMovement.groupBy({
      by: ['product_id'],
      where: {
        empresa_id,
        ref_type: 'REFUND',
        ref_id: sale.id,
      },
      _sum: { qty: true, qty_change: true },
    });

    const refundedQtyByProduct = new Map<string, number>();
    for (const r of prevRefundRows) {
      const q = r._sum.qty ?? Math.trunc(Number(r._sum.qty_change ?? 0));
      refundedQtyByProduct.set(r.product_id, Math.trunc(Number(q ?? 0)));
    }

    const remainingByProduct = new Map<string, number>();
    for (const [pid, soldQty] of soldQtyByProduct.entries()) {
      const already = refundedQtyByProduct.get(pid) ?? 0;
      remainingByProduct.set(pid, Math.max(0, soldQty - already));
    }

    const requestedItemsRaw = (body.items ?? undefined) as Array<{ product_id: string; qty: number }> | undefined;
    const refundItems: Array<{ product_id: string; qty: number }> = [];

    if (!requestedItemsRaw || requestedItemsRaw.length === 0) {
      // Full refund of all remaining quantities.
      for (const [pid, rem] of remainingByProduct.entries()) {
        if (rem > 0) refundItems.push({ product_id: pid, qty: rem });
      }
    } else {
      for (const it of requestedItemsRaw) {
        const rem = remainingByProduct.get(it.product_id);
        if (rem === undefined) {
          throw new ApiError(400, 'Refund item is not part of sale', { product_id: it.product_id }, 'INVALID_REFUND_ITEM');
        }
        if (it.qty <= 0) continue;
        if (it.qty > rem) {
          throw new ApiError(
            409,
            'Refund qty exceeds remaining',
            { product_id: it.product_id, requested: it.qty, remaining: rem },
            'REFUND_QTY_EXCEEDS_REMAINING',
          );
        }
        refundItems.push({ product_id: it.product_id, qty: it.qty });
      }
    }

    if (refundItems.length === 0) {
      // Nothing left to refund -> idempotent.
      return sale;
    }

    const productIds = refundItems.map((i) => i.product_id);
    const lockedProducts = await tx.$queryRaw<Array<{ id: string; stock_qty: any }>>(
      Prisma.sql`
        SELECT id, stock_qty
        FROM "Producto"
        WHERE empresa_id = ${empresa_id}::uuid
          AND id IN (${Prisma.join(productIds.map((id) => Prisma.sql`${id}::uuid`))})
        FOR UPDATE
      `,
    );

    const qtyByProduct = new Map(refundItems.map((i) => [i.product_id, i.qty]));
    for (const p of lockedProducts) {
      const qtyIn = qtyByProduct.get(p.id) ?? 0;
      if (qtyIn <= 0) continue;

      const beforeStock = Math.trunc(Number(p.stock_qty));
      const afterStock = beforeStock + qtyIn;

      await tx.producto.update({
        where: { id: p.id },
        data: { stock_qty: { increment: qtyIn } },
      });

      await tx.posStockMovement.create({
        data: {
          empresa_id,
          product_id: p.id,
          ref_type: 'REFUND',
          ref_id: sale.id,
          qty_change: qtyIn,
          movement_type: 'REFUND_RESTORE',
          qty: qtyIn,
          before_stock: beforeStock,
          after_stock: afterStock,
          unit_cost: 0,
          note: body.note ?? 'POS refund',
          created_by_user_id: actorId,
        },
      });
    }

    // Compute remaining after this refund
    let anyRemaining = false;
    for (const [pid, soldQty] of soldQtyByProduct.entries()) {
      const already = (refundedQtyByProduct.get(pid) ?? 0) + (qtyByProduct.get(pid) ?? 0);
      if (soldQty - already > 0) {
        anyRemaining = true;
        break;
      }
    }

    const updated = await tx.posSale.update({
      where: { id: sale.id },
      data: {
        status: anyRemaining ? 'PARTIAL_REFUNDED' : 'REFUNDED',
        updated_at: new Date(),
      },
      include: { items: true },
    });

    return updated;
  });

  ok(res, result);
}

export async function nextFiscalNcf(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = posNextNcfSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const { doc_type } = parsed.data;

  const result = await prisma.$transaction(async (tx: PrismaTypes.TransactionClient) => {
    return generateNextNcf(tx, empresa_id, doc_type);
  });

  ok(res, result);
}

export async function createPurchase(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const createdBy = actorUserId(req);

  const parsed = posCreatePurchaseSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const body = parsed.data;

  const productIds = [...new Set(body.items.map((it) => it.product_id))];
  const products = await prisma.producto.findMany({
    where: { empresa_id, id: { in: productIds } },
    select: { id: true, nombre: true },
  });

  if (products.length !== productIds.length) {
    throw new ApiError(400, 'One or more products not found');
  }

  const byId = new Map(products.map((p) => [p.id, p]));

  const itemsComputed = body.items.map((it) => {
    const prod = byId.get(it.product_id)!;
    const qty = round2(it.qty);
    const cost = round2(it.unit_cost);
    const lineTotal = round2(qty * cost);
    return {
      product_id: it.product_id,
      product_name: prod.nombre,
      qty,
      unit_cost: cost,
      line_total: lineTotal,
    };
  });

  const subtotal = round2(itemsComputed.reduce((acc, it) => acc + it.line_total, 0));
  const itbis_total = 0;
  const total = round2(subtotal + itbis_total);

  const expected = parseDateOrNull(body.expected_date) ?? null;

  const created = await prisma.posPurchaseOrder.create({
    data: {
      empresa_id,
      supplier_id: body.supplier_id ?? null,
      supplier_name: body.supplier_name,
      status: body.status,
      expected_date: expected,
      subtotal,
      itbis_total,
      total,
      note: body.note ?? null,
      created_by_user_id: createdBy,
      updated_at: new Date(),
      items: {
        createMany: {
          data: itemsComputed.map((it) => ({
            empresa_id,
            product_id: it.product_id,
            product_name: it.product_name,
            qty: it.qty,
            unit_cost: it.unit_cost,
            line_total: it.line_total,
          })),
        },
      },
    },
    include: { items: true },
  });

  ok(res, created, 'Created', 201);
}

export async function listPurchases(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = posListPurchasesSchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const from = parseDateOrNull(parsed.data.from);
  const to = parseDateOrNull(parsed.data.to);
  const status = parsed.data.status?.trim();

  const items = await prisma.posPurchaseOrder.findMany({
    where: {
      empresa_id,
      ...(status && status.length > 0 ? { status } : {}),
      ...(from || to
        ? {
            created_at: {
              ...(from ? { gte: from } : {}),
              ...(to ? { lte: to } : {}),
            },
          }
        : {}),
    },
    orderBy: { created_at: 'desc' },
    take: 200,
  });

  ok(res, items);
}

export async function getPurchase(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const id = String(req.params.id);

  const po = await prisma.posPurchaseOrder.findFirst({
    where: { id, empresa_id },
    include: { items: true },
  });

  if (!po) throw new ApiError(404, 'Purchase order not found');
  ok(res, po);
}

export async function receivePurchase(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const actorId = actorUserId(req);

  const poId = String(req.params.id);

  const parsed = posReceivePurchaseSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const result = await prisma.$transaction(async (tx: PrismaTypes.TransactionClient) => {
    const po = await tx.posPurchaseOrder.findFirst({
      where: { id: poId, empresa_id },
      include: { items: true },
    });

    if (!po) throw new ApiError(404, 'Purchase order not found');
    if (po.status === 'RECEIVED') throw new ApiError(409, 'Purchase already received');
    if (po.status === 'CANCELLED') throw new ApiError(409, 'Purchase is cancelled');

    const qtyByProduct = new Map<string, number>();
    const costByProduct = new Map<string, number>();

    for (const it of po.items) {
      qtyByProduct.set(it.product_id, (qtyByProduct.get(it.product_id) ?? 0) + Number(it.qty));
      costByProduct.set(it.product_id, Number(it.unit_cost));
    }

    const productIds = [...qtyByProduct.keys()];

    await tx.$queryRaw<Array<{ id: string }>>(
      Prisma.sql`
        SELECT id
        FROM "Producto"
        WHERE empresa_id = ${empresa_id}::uuid
          AND id IN (${Prisma.join(productIds.map((id) => Prisma.sql`${id}::uuid`))})
        FOR UPDATE
      `,
    );

    for (const productId of productIds) {
      const qtyIn = qtyByProduct.get(productId) ?? 0;
      const unitCost = costByProduct.get(productId) ?? 0;

      await tx.producto.update({
        where: { id: productId },
        data: {
          stock_qty: { increment: qtyIn },
          precio_compra: round2(unitCost),
        },
      });

      await tx.posStockMovement.create({
        data: {
          empresa_id,
          product_id: productId,
          ref_type: 'PURCHASE_RECEIPT',
          ref_id: po.id,
          qty_change: qtyIn,
          unit_cost: round2(unitCost),
          note: parsed.data.note ?? 'PO received',
          created_by_user_id: actorId,
        },
      });
    }

    const updated = await tx.posPurchaseOrder.update({
      where: { id: po.id },
      data: {
        status: 'RECEIVED',
        updated_at: new Date(),
      },
      include: { items: true },
    });

    return updated;
  });

  ok(res, result);
}

export async function inventoryAdjust(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const actorId = actorUserId(req);

  const parsed = posInventoryAdjustSchema.safeParse(req.body);
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

    await tx.producto.update({
      where: { id: product_id },
      data: { stock_qty: { increment: qty_change } },
    });

    const mv = await tx.posStockMovement.create({
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

    return mv;
  });

  ok(res, result);
}

export async function listInventoryMovements(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = posListMovementsSchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const from = parseDateOrNull(parsed.data.from);
  const to = parseDateOrNull(parsed.data.to);
  const productId = parsed.data.product_id;

  const rows = await prisma.$queryRaw<
    Array<{
      id: string;
      product_id: string;
      product_name: string;
      ref_type: string;
      ref_id: string | null;
      qty_change: any;
      unit_cost: any;
      note: string | null;
      created_at: Date;
    }>
  >`
    SELECT m.id,
           m.product_id,
           p.nombre as product_name,
           m.ref_type,
           m.ref_id,
           m.qty_change,
           m.unit_cost,
           m.note,
           m.created_at
    FROM pos_stock_movements m
    JOIN "Producto" p ON p.id = m.product_id
    WHERE m.empresa_id = ${empresa_id}::uuid
      AND (${productId ?? null}::uuid IS NULL OR m.product_id = ${productId ?? null}::uuid)
      AND (${from ?? null}::timestamp IS NULL OR m.created_at >= ${from ?? null}::timestamp)
      AND (${to ?? null}::timestamp IS NULL OR m.created_at <= ${to ?? null}::timestamp)
    ORDER BY m.created_at DESC
    LIMIT 300;
  `;

  const data = rows.map((r) => ({
    ...r,
    qty_change: Number(r.qty_change),
    unit_cost: Number(r.unit_cost),
  }));

  ok(res, data);
}

export async function listCredit(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = posListCreditSchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const status = parsed.data.status?.trim();
  const search = parsed.data.search?.trim();

  const rows = await prisma.$queryRaw<
    Array<{
      id: string;
      sale_id: string;
      customer_name: string;
      total: any;
      paid: any;
      balance: any;
      due_date: Date | null;
      status: string;
      created_at: Date;
      invoice_no: string;
    }>
  >`
    SELECT c.id,
           c.sale_id,
           c.customer_name,
           c.total,
           c.paid,
           c.balance,
           c.due_date,
           c.status,
           c.created_at,
           s.invoice_no
    FROM pos_credit_accounts c
    JOIN pos_sales s ON s.id = c.sale_id
    WHERE c.empresa_id = ${empresa_id}::uuid
      AND (${status ?? null}::text IS NULL OR c.status = ${status ?? null})
      AND (
        ${search ?? null}::text IS NULL
        OR c.customer_name ILIKE ('%' || ${search ?? ''} || '%')
        OR s.invoice_no ILIKE ('%' || ${search ?? ''} || '%')
      )
    ORDER BY c.created_at DESC
    LIMIT 300;
  `;

  const data = rows.map((r) => ({
    ...r,
    total: Number(r.total),
    paid: Number(r.paid),
    balance: Number(r.balance),
  }));

  ok(res, data);
}

export async function getCredit(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const id = String(req.params.id);

  const credit = await prisma.posCreditAccount.findFirst({ where: { id, empresa_id } });
  if (!credit) throw new ApiError(404, 'Credit account not found');

  const sale = await prisma.posSale.findFirst({
    where: { id: credit.sale_id, empresa_id },
    include: { items: true },
  });

  ok(res, { credit, sale });
}

export async function reportSalesSummary(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = posReportsRangeSchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const from = parseDateOrNull(parsed.data.from);
  const to = parseDateOrNull(parsed.data.to);

  const rows = await prisma.$queryRaw<
    Array<{ total: any; count: bigint; avg: any }>
  >`
    SELECT COALESCE(SUM(total), 0) AS total,
           COUNT(*)::bigint AS count,
           COALESCE(AVG(total), 0) AS avg
    FROM pos_sales
    WHERE empresa_id = ${empresa_id}::uuid
      AND status IN ('PAID', 'CREDIT')
      AND (${from ?? null}::timestamp IS NULL OR created_at >= ${from ?? null}::timestamp)
      AND (${to ?? null}::timestamp IS NULL OR created_at <= ${to ?? null}::timestamp);
  `;

  const r = rows[0] ?? { total: 0, count: BigInt(0), avg: 0 };
  ok(res, { total: Number(r.total), count: Number(r.count), avg_ticket: Number(r.avg) });
}

export async function reportTopProducts(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = posReportsRangeSchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const from = parseDateOrNull(parsed.data.from);
  const to = parseDateOrNull(parsed.data.to);

  const rows = await prisma.$queryRaw<
    Array<{ product_id: string; product_name: string; qty: any; amount: any }>
  >`
    SELECT i.product_id,
           MAX(i.product_name) AS product_name,
           COALESCE(SUM(i.qty), 0) AS qty,
           COALESCE(SUM(i.line_total), 0) AS amount
    FROM pos_sale_items i
    JOIN pos_sales s ON s.id = i.sale_id
    WHERE s.empresa_id = ${empresa_id}::uuid
      AND s.status IN ('PAID', 'CREDIT')
      AND (${from ?? null}::timestamp IS NULL OR s.created_at >= ${from ?? null}::timestamp)
      AND (${to ?? null}::timestamp IS NULL OR s.created_at <= ${to ?? null}::timestamp)
    GROUP BY i.product_id
    ORDER BY amount DESC
    LIMIT 20;
  `;

  ok(
    res,
    rows.map((r) => ({
      product_id: r.product_id,
      product_name: r.product_name,
      qty: Number(r.qty),
      amount: Number(r.amount),
    })),
  );
}

export async function reportInventoryLowStock(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const rows = await prisma.$queryRaw<
    Array<{ id: string; nombre: string; stock_qty: any; min_stock: any; max_stock: any }>
  >`
    SELECT id, nombre, stock_qty, min_stock, max_stock
    FROM "Producto"
    WHERE empresa_id = ${empresa_id}::uuid
      AND is_active = true
      AND stock_qty <= min_stock
    ORDER BY stock_qty ASC, nombre ASC
    LIMIT 200;
  `;

  ok(
    res,
    rows.map((p) => {
      const stockQty = Number(p.stock_qty);
      const minStock = Number(p.min_stock);
      const maxStock = Number(p.max_stock);
      return {
        id: p.id,
        nombre: p.nombre,
        stock_qty: stockQty,
        min_stock: minStock,
        max_stock: maxStock,
        suggested_reorder_qty: suggestReorderQty({ stockQty, minStock, maxStock }),
      };
    }),
  );
}

export async function reportPurchasesSummary(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const parsed = posReportsRangeSchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const from = parseDateOrNull(parsed.data.from);
  const to = parseDateOrNull(parsed.data.to);

  const rows = await prisma.$queryRaw<Array<{ total: any; count: bigint }>>`
    SELECT COALESCE(SUM(total), 0) AS total,
           COUNT(*)::bigint AS count
    FROM pos_purchase_orders
    WHERE empresa_id = ${empresa_id}::uuid
      AND status = 'RECEIVED'
      AND (${from ?? null}::timestamp IS NULL OR created_at >= ${from ?? null}::timestamp)
      AND (${to ?? null}::timestamp IS NULL OR created_at <= ${to ?? null}::timestamp);
  `;

  const r = rows[0] ?? { total: 0, count: BigInt(0) };
  ok(res, { total: Number(r.total), count: Number(r.count) });
}

export async function reportCreditAging(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  // Buckets: current (not due), 1-30 overdue, 31-60, 61+.
  const rows = await prisma.$queryRaw<
    Array<{ bucket: string; balance: any }>
  >`
    SELECT
      CASE
        WHEN due_date IS NULL THEN 'no_due_date'
        WHEN due_date >= CURRENT_DATE THEN 'current'
        WHEN due_date >= CURRENT_DATE - INTERVAL '30 days' THEN '1_30'
        WHEN due_date >= CURRENT_DATE - INTERVAL '60 days' THEN '31_60'
        ELSE '61_plus'
      END AS bucket,
      COALESCE(SUM(balance), 0) AS balance
    FROM pos_credit_accounts
    WHERE empresa_id = ${empresa_id}::uuid
      AND status IN ('OPEN', 'PARTIAL', 'OVERDUE')
    GROUP BY 1
    ORDER BY 1;
  `;

  ok(
    res,
    rows.map((r) => ({ bucket: r.bucket, balance: Number(r.balance) })),
  );
}
