import type { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { createVentaSchema, updateVentaSchema } from './ventas.schema';

export async function listVentas(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const items = await prisma.venta.findMany({
    where: { empresa_id: empresaId },
    orderBy: { updated_at: 'desc' },
    include: { cliente: true },
  });

  res.json({ items });
}

export async function createVenta(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const parsed = createVentaSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid venta payload', parsed.error.flatten());
  }

  const cliente = await prisma.cliente.findFirst({
    where: { id: parsed.data.cliente_id, empresa_id: empresaId },
  });
  if (!cliente) {
    throw new ApiError(400, 'cliente_id not found for this empresa');
  }

  const venta = await prisma.venta.create({
    data: {
      empresa_id: empresaId,
      cliente_id: parsed.data.cliente_id,
      numero: parsed.data.numero,
      monto: parsed.data.monto,
      estado: parsed.data.estado ?? 'pendiente',
    },
  });

  res.status(201).json({ item: venta });
}

export async function getVenta(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const venta = await prisma.venta.findFirst({
    where: { id, empresa_id: empresaId },
    include: { cliente: true },
  });
  if (!venta) {
    throw new ApiError(404, 'Venta not found');
  }

  res.json({ item: venta });
}

export async function updateVenta(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const parsed = updateVentaSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid venta payload', parsed.error.flatten());
  }

  const existing = await prisma.venta.findFirst({
    where: { id, empresa_id: empresaId },
  });
  if (!existing) {
    throw new ApiError(404, 'Venta not found');
  }

  if (parsed.data.cliente_id) {
    const cliente = await prisma.cliente.findFirst({
      where: { id: parsed.data.cliente_id, empresa_id: empresaId },
    });
    if (!cliente) {
      throw new ApiError(400, 'cliente_id not found for this empresa');
    }
  }

  const updated = await prisma.venta.update({
    where: { id },
    data: {
      ...parsed.data,
    },
  });

  res.json({ item: updated });
}

export async function deleteVenta(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const existing = await prisma.venta.findFirst({
    where: { id, empresa_id: empresaId },
  });
  if (!existing) {
    throw new ApiError(404, 'Venta not found');
  }

  await prisma.venta.delete({ where: { id } });
  res.status(204).send();
}
