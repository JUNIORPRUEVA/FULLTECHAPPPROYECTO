import type { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { createClienteSchema, updateClienteSchema } from './clientes.schema';

export async function listClientes(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const items = await prisma.cliente.findMany({
    where: { empresa_id: empresaId },
    orderBy: { updated_at: 'desc' },
  });

  res.json({ items });
}

export async function createCliente(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const parsed = createClienteSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid cliente payload', parsed.error.flatten());
  }

  const cliente = await prisma.cliente.create({
    data: {
      empresa_id: empresaId,
      ...parsed.data,
      // Normalizamos estados a strings para mantener compatibilidad futura.
      estado: parsed.data.estado ?? 'pendiente',
      ultima_interaccion: parsed.data.ultima_interaccion
        ? new Date(parsed.data.ultima_interaccion)
        : undefined,
    },
  });

  res.status(201).json({ item: cliente });
}

export async function getCliente(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const cliente = await prisma.cliente.findFirst({
    where: { id, empresa_id: empresaId },
  });

  if (!cliente) {
    throw new ApiError(404, 'Cliente not found');
  }

  res.json({ item: cliente });
}

export async function updateCliente(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const parsed = updateClienteSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid cliente payload', parsed.error.flatten());
  }

  const existing = await prisma.cliente.findFirst({
    where: { id, empresa_id: empresaId },
  });
  if (!existing) {
    throw new ApiError(404, 'Cliente not found');
  }

  const updated = await prisma.cliente.update({
    where: { id },
    data: {
      ...parsed.data,
      ultima_interaccion: parsed.data.ultima_interaccion
        ? new Date(parsed.data.ultima_interaccion)
        : undefined,
    },
  });

  res.json({ item: updated });
}

export async function deleteCliente(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;

  const existing = await prisma.cliente.findFirst({
    where: { id, empresa_id: empresaId },
  });
  if (!existing) {
    throw new ApiError(404, 'Cliente not found');
  }

  await prisma.cliente.delete({ where: { id } });
  res.status(204).send();
}
