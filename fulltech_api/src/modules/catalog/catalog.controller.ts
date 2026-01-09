import type { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import {
  createCategoriaProductoSchema,
  createProductoSchema,
  productoItemInputSchema,
  updateCategoriaProductoSchema,
  updateProductoSchema,
} from './catalog.schema';

function parseBooleanQuery(value: unknown): boolean {
  if (typeof value !== 'string') return false;
  const normalized = value.trim().toLowerCase();
  return normalized === 'true' || normalized === '1' || normalized === 'yes';
}

function parseProductType(value: unknown): 'simple' | 'servicio' | undefined {
  if (typeof value !== 'string') return undefined;
  const v = value.trim().toLowerCase();
  if (v === 'simple' || v === 'servicio') return v;
  return undefined;
}

function parseNumberQuery(value: unknown): number | undefined {
  if (typeof value !== 'string') return undefined;
  const v = value.trim();
  if (v === '') return undefined;
  const n = Number(v);
  if (!Number.isFinite(n)) return undefined;
  return n;
}

function parseIntQuery(value: unknown): number | undefined {
  const n = parseNumberQuery(value);
  if (n === undefined) return undefined;
  const i = Math.trunc(n);
  if (!Number.isFinite(i)) return undefined;
  return i;
}

function parseOrderQuery(value: unknown): 'most_used' | 'recent' | 'price_asc' | 'price_desc' | undefined {
  if (typeof value !== 'string') return undefined;
  const v = value.trim().toLowerCase();
  if (v === 'most_used' || v === 'recent' || v === 'price_asc' || v === 'price_desc') return v;
  return undefined;
}

function calculateTotals(items: Array<{ cantidad: number; costo_unitario: number; precio_unitario: number }>) {
  const totalCost = items.reduce((acc, it) => acc + it.cantidad * it.costo_unitario, 0);
  const totalPrice = items.reduce((acc, it) => acc + it.cantidad * it.precio_unitario, 0);
  return { totalCost, totalPrice };
}

async function assertCategoriaActiva(empresaId: string, categoriaId: string) {
  const categoria = await prisma.categoriaProducto.findFirst({
    where: { id: categoriaId, empresa_id: empresaId, is_active: true },
    select: { id: true },
  });
  if (!categoria) {
    throw new ApiError(400, 'categoria_id not found (or inactive) for this empresa');
  }
}

async function assertServicioParent(empresaId: string, parentId: string) {
  const parent = await prisma.producto.findFirst({
    where: { id: parentId, empresa_id: empresaId },
    select: { id: true, product_type: true },
  });
  if (!parent) throw new ApiError(404, 'Producto not found');
  if (parent.product_type !== 'servicio') throw new ApiError(400, 'Producto is not a servicio');
}

export async function listCategoriasProducto(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const includeInactive = parseBooleanQuery(req.query.include_inactive);

  const items = await prisma.categoriaProducto.findMany({
    where: {
      empresa_id: empresaId,
      ...(includeInactive ? {} : { is_active: true }),
    },
    orderBy: { nombre: 'asc' },
  });

  res.json({ items });
}

export async function createCategoriaProducto(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const parsed = createCategoriaProductoSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid categoria payload', parsed.error.flatten());
  }

  const item = await prisma.categoriaProducto.create({
    data: {
      empresa_id: empresaId,
      nombre: parsed.data.nombre,
      descripcion: parsed.data.descripcion,
      is_active: parsed.data.is_active ?? true,
    },
  });

  res.status(201).json({ item });
}

export async function getCategoriaProducto(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const item = await prisma.categoriaProducto.findFirst({
    where: { id, empresa_id: empresaId },
  });

  if (!item) {
    throw new ApiError(404, 'Categoria not found');
  }

  res.json({ item });
}

export async function updateCategoriaProducto(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const parsed = updateCategoriaProductoSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid categoria payload', parsed.error.flatten());
  }

  const existing = await prisma.categoriaProducto.findFirst({
    where: { id, empresa_id: empresaId },
  });
  if (!existing) {
    throw new ApiError(404, 'Categoria not found');
  }

  const updated = await prisma.categoriaProducto.update({
    where: { id },
    data: {
      ...parsed.data,
    },
  });

  res.json({ item: updated });
}

export async function deleteCategoriaProducto(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const existing = await prisma.categoriaProducto.findFirst({
    where: { id, empresa_id: empresaId },
  });
  if (!existing) {
    throw new ApiError(404, 'Categoria not found');
  }

  const productsCount = await prisma.producto.count({
    where: { empresa_id: empresaId, categoria_id: id, is_active: true },
  });
  if (productsCount > 0) {
    throw new ApiError(400, 'Categoria has active productos; deactivate them first');
  }

  await prisma.categoriaProducto.update({
    where: { id },
    data: { is_active: false },
  });

  res.status(204).send();
}

export async function listProductos(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const includeInactive = parseBooleanQuery(req.query.include_inactive);

  const productType = parseProductType(req.query.product_type);

  const q = typeof req.query.q === 'string' ? req.query.q.trim() : undefined;
  const categoriaId =
    typeof req.query.category_id === 'string' ? req.query.category_id.trim() : undefined;

  const minPrice = parseNumberQuery(req.query.min_price);
  const maxPrice = parseNumberQuery(req.query.max_price);
  const order = parseOrderQuery(req.query.order);

  const limitRaw = parseIntQuery(req.query.limit);
  const pageRaw = parseIntQuery(req.query.page);
  const limit = Math.min(Math.max(limitRaw ?? 0, 0), 200);
  const page = Math.max(pageRaw ?? 0, 0);

  const usePaging = limit > 0;
  const take = usePaging ? limit : undefined;
  const skip = usePaging ? Math.max((page <= 1 ? 0 : (page - 1) * limit), 0) : undefined;

  const orderBy = (() => {
    switch (order) {
      case 'recent':
        return [{ created_at: 'desc' as const }, { id: 'desc' as const }];
      case 'price_asc':
        return [{ precio_venta: 'asc' as const }, { created_at: 'desc' as const }, { id: 'desc' as const }];
      case 'price_desc':
        return [{ precio_venta: 'desc' as const }, { created_at: 'desc' as const }, { id: 'desc' as const }];
      case 'most_used':
      default:
        return [{ search_count: 'desc' as const }, { created_at: 'desc' as const }, { id: 'desc' as const }];
    }
  })();

  const items = await prisma.producto.findMany({
    where: {
      empresa_id: empresaId,
      ...(includeInactive ? {} : { is_active: true }),
      ...(productType ? { product_type: productType } : {}),
      ...(categoriaId ? { categoria_id: categoriaId } : {}),
      ...((minPrice !== undefined || maxPrice !== undefined)
        ? {
            precio_venta: {
              ...(minPrice !== undefined ? { gte: minPrice } : {}),
              ...(maxPrice !== undefined ? { lte: maxPrice } : {}),
            },
          }
        : {}),
      ...(q
        ? {
            nombre: {
              contains: q,
              mode: 'insensitive',
            },
          }
        : {}),
    },
    orderBy,
    ...(skip !== undefined ? { skip } : {}),
    ...(take !== undefined ? { take } : {}),
    include: {
      categoria: true,
      _count: { select: { items_as_parent: true } },
    },
  });

  const shaped = items.map((p) => {
    const computedTotalCost = p.product_type === 'simple' ? p.precio_compra : p.total_cost;
    const computedTotalPrice = p.product_type === 'simple' ? p.precio_venta : p.total_price;

    // Keep response backward-friendly while exposing new fields.
    return {
      ...p,
      total_cost: Number(p.total_cost) === 0 ? computedTotalCost : p.total_cost,
      total_price: Number(p.total_price) === 0 ? computedTotalPrice : p.total_price,
      items_count: p._count?.items_as_parent ?? 0,
      _count: undefined,
    };
  });

  res.json({ items: shaped });
}

export async function createProducto(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const parsed = createProductoSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid producto payload', parsed.error.flatten());
  }

  await assertCategoriaActiva(empresaId, parsed.data.categoria_id);

  const stockQty = Math.max(0, Math.trunc((parsed.data as any).stock_qty ?? 0));
  const minPurchaseQty = Math.max(1, Math.trunc((parsed.data as any).min_purchase_qty ?? 1));
  const lowStockThreshold = Math.max(0, Math.trunc((parsed.data as any).low_stock_threshold ?? 5));
  const supplierId = (parsed.data as any).supplier_id ?? null;
  const brand = (parsed.data as any).brand ?? null;

  if (parsed.data.product_type === 'simple') {
    const totalCost = parsed.data.precio_compra;
    const totalPrice = parsed.data.precio_venta;

    const item = await prisma.producto.create({
      data: {
        empresa_id: empresaId,
        nombre: parsed.data.nombre,
        precio_compra: totalCost,
        precio_venta: totalPrice,
        product_type: 'simple',
        total_cost: totalCost,
        total_price: totalPrice,
        imagen_url: parsed.data.imagen_url,
        categoria_id: parsed.data.categoria_id,
        is_active: parsed.data.is_active ?? true,

        // Stock settings
        stock_qty: stockQty,
        min_stock: lowStockThreshold,
        min_purchase_qty: minPurchaseQty,
        supplier_id: supplierId,
        brand,
      },
      include: { categoria: true },
    });

    res.status(201).json({ item });
    return;
  }

  // Servicio/paquete
  const itemsInput = parsed.data.items;
  const uniqueChildIds = new Set(itemsInput.map((i) => i.child_producto_id));
  if (uniqueChildIds.size !== itemsInput.length) {
    throw new ApiError(400, 'Duplicate child_producto_id in items');
  }

  const childIds = [...uniqueChildIds];
  const children = await prisma.producto.findMany({
    where: {
      empresa_id: empresaId,
      id: { in: childIds },
      is_active: true,
      product_type: 'simple',
    },
    select: { id: true },
  });
  if (children.length !== childIds.length) {
    throw new ApiError(400, 'All items must reference active simple productos in this empresa');
  }

  const { totalCost, totalPrice } = calculateTotals(itemsInput);

  const created = await prisma.$transaction(async (tx) => {
    const producto = await tx.producto.create({
      data: {
        empresa_id: empresaId,
        nombre: parsed.data.nombre,
        // Keep legacy fields consistent
        precio_compra: totalCost,
        precio_venta: totalPrice,
        product_type: 'servicio',
        total_cost: totalCost,
        total_price: totalPrice,
        imagen_url: parsed.data.imagen_url,
        categoria_id: parsed.data.categoria_id,
        is_active: parsed.data.is_active ?? true,

        // Stock settings (services usually non-stocked, but keep fields consistent)
        stock_qty: 0,
        min_stock: lowStockThreshold,
        min_purchase_qty: minPurchaseQty,
        supplier_id: supplierId,
        brand,
      },
      include: { categoria: true },
    });

    await tx.productoItem.createMany({
      data: itemsInput.map((i) => ({
        parent_producto_id: producto.id,
        child_producto_id: i.child_producto_id,
        cantidad: i.cantidad,
        costo_unitario: i.costo_unitario,
        precio_unitario: i.precio_unitario,
      })),
    });

    return producto;
  });

  res.status(201).json({ item: created });
}

export async function getProducto(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const item = await prisma.producto.findFirst({
    where: { id, empresa_id: empresaId },
    include: { categoria: true },
  });

  if (!item) {
    throw new ApiError(404, 'Producto not found');
  }

  if (item.product_type !== 'servicio') {
    const shaped = {
      ...item,
      total_cost: Number(item.total_cost) === 0 ? item.precio_compra : item.total_cost,
      total_price: Number(item.total_price) === 0 ? item.precio_venta : item.total_price,
    };
    res.json({ item: shaped });
    return;
  }

  const items = await prisma.productoItem.findMany({
    where: { parent_producto_id: id },
    include: {
      child_producto: { select: { id: true, nombre: true } },
    },
    orderBy: { created_at: 'asc' },
  });

  const shapedItems = items.map((it) => {
    const cantidad = Number(it.cantidad);
    const costoUnitario = Number(it.costo_unitario);
    const precioUnitario = Number(it.precio_unitario);

    return {
      id: it.id,
      child_producto_id: it.child_producto_id,
      child_nombre: it.child_producto.nombre,
      cantidad,
      costo_unitario: costoUnitario,
      precio_unitario: precioUnitario,
      subtotal_costo: cantidad * costoUnitario,
      subtotal_precio: cantidad * precioUnitario,
    };
  });

  const shaped = {
    ...item,
    items: shapedItems,
  };

  res.json({ item: shaped });
}

export async function updateProducto(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const parsed = updateProductoSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid producto payload', parsed.error.flatten());
  }

  const existing = await prisma.producto.findFirst({
    where: { id, empresa_id: empresaId },
  });
  if (!existing) {
    throw new ApiError(404, 'Producto not found');
  }

  if (parsed.data.categoria_id) {
    await assertCategoriaActiva(empresaId, parsed.data.categoria_id);
  }

  const finalType: 'simple' | 'servicio' = (parsed.data.product_type as any) ?? (existing as any).product_type;

  // If items were provided, we treat this update as service items replacement.
  const itemsInput = parsed.data.items;

  const updated = await prisma.$transaction(async (tx) => {
    if (finalType === 'simple') {
      if (itemsInput && itemsInput.length > 0) {
        throw new ApiError(400, 'items are only allowed for servicios');
      }

      // If switching from servicio -> simple, require explicit prices.
      const switchingToSimple = (existing as any).product_type === 'servicio' && parsed.data.product_type === 'simple';
      if (switchingToSimple && (parsed.data.precio_compra === undefined || parsed.data.precio_venta === undefined)) {
        throw new ApiError(400, 'precio_compra and precio_venta are required when switching servicio -> simple');
      }

      // Remove any leftover composition items.
      await tx.productoItem.deleteMany({ where: { parent_producto_id: id } });

      const precioCompra = parsed.data.precio_compra ?? Number((existing as any).precio_compra);
      const precioVenta = parsed.data.precio_venta ?? Number((existing as any).precio_venta);

      const stockQty =
        (parsed.data as any).stock_qty !== undefined
          ? Math.max(0, Math.trunc((parsed.data as any).stock_qty))
          : undefined;
      const minPurchaseQty =
        (parsed.data as any).min_purchase_qty !== undefined
          ? Math.max(1, Math.trunc((parsed.data as any).min_purchase_qty))
          : undefined;
      const lowStockThreshold =
        (parsed.data as any).low_stock_threshold !== undefined
          ? Math.max(0, Math.trunc((parsed.data as any).low_stock_threshold))
          : undefined;

      const producto = await tx.producto.update({
        where: { id },
        data: {
          ...(parsed.data.nombre !== undefined ? { nombre: parsed.data.nombre } : {}),
          ...(parsed.data.imagen_url !== undefined ? { imagen_url: parsed.data.imagen_url } : {}),
          ...(parsed.data.categoria_id !== undefined ? { categoria_id: parsed.data.categoria_id } : {}),
          ...(parsed.data.is_active !== undefined ? { is_active: parsed.data.is_active } : {}),
          product_type: 'simple',
          precio_compra: precioCompra,
          precio_venta: precioVenta,
          total_cost: precioCompra,
          total_price: precioVenta,

          ...(stockQty !== undefined ? { stock_qty: stockQty } : {}),
          ...(minPurchaseQty !== undefined ? { min_purchase_qty: minPurchaseQty } : {}),
          ...(lowStockThreshold !== undefined ? { min_stock: lowStockThreshold } : {}),
          ...((parsed.data as any).supplier_id !== undefined ? { supplier_id: (parsed.data as any).supplier_id } : {}),
          ...((parsed.data as any).brand !== undefined ? { brand: (parsed.data as any).brand } : {}),
        },
        include: { categoria: true },
      });

      return producto;
    }

    // servicio
    if (parsed.data.product_type === 'servicio' && (!itemsInput || itemsInput.length === 0)) {
      throw new ApiError(400, 'items are required for servicios');
    }

    if (itemsInput) {
      const uniqueChildIds = new Set(itemsInput.map((i) => i.child_producto_id));
      if (uniqueChildIds.size !== itemsInput.length) {
        throw new ApiError(400, 'Duplicate child_producto_id in items');
      }

      const childIds = [...uniqueChildIds];
      const children = await tx.producto.findMany({
        where: {
          empresa_id: empresaId,
          id: { in: childIds },
          is_active: true,
          product_type: 'simple',
        },
        select: { id: true },
      });
      if (children.length !== childIds.length) {
        throw new ApiError(400, 'All items must reference active simple productos in this empresa');
      }

      await tx.productoItem.deleteMany({ where: { parent_producto_id: id } });
      await tx.productoItem.createMany({
        data: itemsInput.map((i) => ({
          parent_producto_id: id,
          child_producto_id: i.child_producto_id,
          cantidad: i.cantidad,
          costo_unitario: i.costo_unitario,
          precio_unitario: i.precio_unitario,
        })),
      });

      const { totalCost, totalPrice } = calculateTotals(itemsInput);

      const stockQty =
        (parsed.data as any).stock_qty !== undefined
          ? Math.max(0, Math.trunc((parsed.data as any).stock_qty))
          : undefined;
      const minPurchaseQty =
        (parsed.data as any).min_purchase_qty !== undefined
          ? Math.max(1, Math.trunc((parsed.data as any).min_purchase_qty))
          : undefined;
      const lowStockThreshold =
        (parsed.data as any).low_stock_threshold !== undefined
          ? Math.max(0, Math.trunc((parsed.data as any).low_stock_threshold))
          : undefined;

      const producto = await tx.producto.update({
        where: { id },
        data: {
          ...(parsed.data.nombre !== undefined ? { nombre: parsed.data.nombre } : {}),
          ...(parsed.data.imagen_url !== undefined ? { imagen_url: parsed.data.imagen_url } : {}),
          ...(parsed.data.categoria_id !== undefined ? { categoria_id: parsed.data.categoria_id } : {}),
          ...(parsed.data.is_active !== undefined ? { is_active: parsed.data.is_active } : {}),
          product_type: 'servicio',
          precio_compra: totalCost,
          precio_venta: totalPrice,
          total_cost: totalCost,
          total_price: totalPrice,

          ...(stockQty !== undefined ? { stock_qty: stockQty } : {}),
          ...(minPurchaseQty !== undefined ? { min_purchase_qty: minPurchaseQty } : {}),
          ...(lowStockThreshold !== undefined ? { min_stock: lowStockThreshold } : {}),
          ...((parsed.data as any).supplier_id !== undefined ? { supplier_id: (parsed.data as any).supplier_id } : {}),
          ...((parsed.data as any).brand !== undefined ? { brand: (parsed.data as any).brand } : {}),
        },
        include: { categoria: true },
      });

      return producto;
    }

    // No items update, just base fields.
    const producto = await tx.producto.update({
      where: { id },
      data: {
        ...(parsed.data.nombre !== undefined ? { nombre: parsed.data.nombre } : {}),
        ...(parsed.data.imagen_url !== undefined ? { imagen_url: parsed.data.imagen_url } : {}),
        ...(parsed.data.categoria_id !== undefined ? { categoria_id: parsed.data.categoria_id } : {}),
        ...(parsed.data.is_active !== undefined ? { is_active: parsed.data.is_active } : {}),
        product_type: 'servicio',
      },
      include: { categoria: true },
    });

    return producto;
  });

  res.json({ item: updated });
}

export async function deleteProducto(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const existing = await prisma.producto.findFirst({
    where: { id, empresa_id: empresaId },
  });
  if (!existing) {
    throw new ApiError(404, 'Producto not found');
  }

  await prisma.producto.update({
    where: { id },
    data: { is_active: false },
  });

  res.status(204).send();
}

export async function incrementProductoSearch(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const existing = await prisma.producto.findFirst({
    where: { id, empresa_id: empresaId },
  });
  if (!existing) {
    throw new ApiError(404, 'Producto not found');
  }

  const updated = await prisma.producto.update({
    where: { id },
    data: { search_count: { increment: 1 } },
    include: { categoria: true },
  });

  res.json({ item: updated });
}

// --- Producto items (CRUD for servicios) ---

export async function listProductoItems(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  await assertServicioParent(empresaId, id);

  const items = await prisma.productoItem.findMany({
    where: { parent_producto_id: id },
    include: { child_producto: { select: { id: true, nombre: true } } },
    orderBy: { created_at: 'asc' },
  });

  const shaped = items.map((it) => {
    const cantidad = Number(it.cantidad);
    const costoUnitario = Number(it.costo_unitario);
    const precioUnitario = Number(it.precio_unitario);

    return {
      id: it.id,
      child_producto_id: it.child_producto_id,
      child_nombre: it.child_producto.nombre,
      cantidad,
      costo_unitario: costoUnitario,
      precio_unitario: precioUnitario,
      subtotal_costo: cantidad * costoUnitario,
      subtotal_precio: cantidad * precioUnitario,
    };
  });

  res.json({ items: shaped });
}

export async function addProductoItem(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  await assertServicioParent(empresaId, id);

  const parsed = productoItemInputSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid producto item payload', parsed.error.flatten());
  }

  const child = await prisma.producto.findFirst({
    where: {
      id: parsed.data.child_producto_id,
      empresa_id: empresaId,
      is_active: true,
      product_type: 'simple',
    },
    select: { id: true },
  });
  if (!child) {
    throw new ApiError(400, 'child_producto_id must reference an active simple producto');
  }

  const result = await prisma.$transaction(async (tx) => {
    const created = await tx.productoItem.create({
      data: {
        parent_producto_id: id,
        child_producto_id: parsed.data.child_producto_id,
        cantidad: parsed.data.cantidad,
        costo_unitario: parsed.data.costo_unitario,
        precio_unitario: parsed.data.precio_unitario,
      },
    });

    const items = await tx.productoItem.findMany({
      where: { parent_producto_id: id },
      select: { cantidad: true, costo_unitario: true, precio_unitario: true },
    });

    const totals = calculateTotals(
      items.map((it) => ({
        cantidad: Number(it.cantidad),
        costo_unitario: Number(it.costo_unitario),
        precio_unitario: Number(it.precio_unitario),
      })),
    );

    await tx.producto.update({
      where: { id },
      data: {
        total_cost: totals.totalCost,
        total_price: totals.totalPrice,
        precio_compra: totals.totalCost,
        precio_venta: totals.totalPrice,
      },
    });

    return created;
  });

  res.status(201).json({ item: result });
}

export async function updateProductoItem(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id, itemId } = req.params;

  await assertServicioParent(empresaId, id);

  const parsed = productoItemInputSchema.partial().safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid producto item payload', parsed.error.flatten());
  }

  const existing = await prisma.productoItem.findFirst({
    where: { id: itemId, parent_producto_id: id },
  });
  if (!existing) throw new ApiError(404, 'Producto item not found');

  if (parsed.data.child_producto_id) {
    const child = await prisma.producto.findFirst({
      where: {
        id: parsed.data.child_producto_id,
        empresa_id: empresaId,
        is_active: true,
        product_type: 'simple',
      },
      select: { id: true },
    });
    if (!child) throw new ApiError(400, 'child_producto_id must reference an active simple producto');
  }

  const updated = await prisma.$transaction(async (tx) => {
    const item = await tx.productoItem.update({
      where: { id: itemId },
      data: {
        ...(parsed.data.child_producto_id !== undefined
          ? { child_producto_id: parsed.data.child_producto_id }
          : {}),
        ...(parsed.data.cantidad !== undefined ? { cantidad: parsed.data.cantidad } : {}),
        ...(parsed.data.costo_unitario !== undefined ? { costo_unitario: parsed.data.costo_unitario } : {}),
        ...(parsed.data.precio_unitario !== undefined ? { precio_unitario: parsed.data.precio_unitario } : {}),
      },
    });

    const items = await tx.productoItem.findMany({
      where: { parent_producto_id: id },
      select: { cantidad: true, costo_unitario: true, precio_unitario: true },
    });
    const totals = calculateTotals(
      items.map((it) => ({
        cantidad: Number(it.cantidad),
        costo_unitario: Number(it.costo_unitario),
        precio_unitario: Number(it.precio_unitario),
      })),
    );

    await tx.producto.update({
      where: { id },
      data: {
        total_cost: totals.totalCost,
        total_price: totals.totalPrice,
        precio_compra: totals.totalCost,
        precio_venta: totals.totalPrice,
      },
    });

    return item;
  });

  res.json({ item: updated });
}

export async function deleteProductoItem(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id, itemId } = req.params;

  await assertServicioParent(empresaId, id);

  const existing = await prisma.productoItem.findFirst({
    where: { id: itemId, parent_producto_id: id },
  });
  if (!existing) throw new ApiError(404, 'Producto item not found');

  await prisma.$transaction(async (tx) => {
    await tx.productoItem.delete({ where: { id: itemId } });

    const items = await tx.productoItem.findMany({
      where: { parent_producto_id: id },
      select: { cantidad: true, costo_unitario: true, precio_unitario: true },
    });
    const totals = calculateTotals(
      items.map((it) => ({
        cantidad: Number(it.cantidad),
        costo_unitario: Number(it.costo_unitario),
        precio_unitario: Number(it.precio_unitario),
      })),
    );

    await tx.producto.update({
      where: { id },
      data: {
        total_cost: totals.totalCost,
        total_price: totals.totalPrice,
        precio_compra: totals.totalCost,
        precio_venta: totals.totalPrice,
      },
    });
  });

  res.status(204).send();
}
