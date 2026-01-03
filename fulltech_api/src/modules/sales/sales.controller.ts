import type { Request, Response } from 'express';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { createSaleSchema } from './sales.schema';

function actorEmpresaId(req: Request): string {
  const actor = req.user;
  if (!actor?.empresaId) throw new ApiError(401, 'Unauthorized');
  return actor.empresaId;
}

export async function createSale(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const actor = req.user;

  const parsed = createSaleSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const { thread_id, customer_id, total, detalles } = parsed.data;

  const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    let customerId: string | null = customer_id ?? null;
    let threadId: string | null = thread_id ?? null;

    let thread: any = null;

    if (threadId) {
      thread = await tx.crmThread.findFirst({
        where: { id: threadId, empresa_id, deleted_at: null },
      });
      if (!thread) throw new ApiError(404, 'Thread not found');

      // If explicit customer is provided, validate it.
      if (customerId) {
        const cust = await tx.customer.findFirst({
          where: { id: customerId, empresa_id, deleted_at: null },
        });
        if (!cust) throw new ApiError(404, 'Customer not found');
      }

      // Auto-convert lead -> customer if needed.
      if (!customerId) {
        if (thread.customer_id) {
          customerId = thread.customer_id;
        } else {
          // Create or attach customer by phone.
          const phone = thread.phone_number;
          let cust = await tx.customer.findFirst({
            where: { empresa_id, telefono: phone, deleted_at: null },
          });

          if (!cust) {
            const name =
              thread.display_name && thread.display_name.trim().length > 0
                ? thread.display_name.trim()
                : `Cliente WhatsApp ${phone}`;

            cust = await tx.customer.create({
              data: {
                empresa_id,
                nombre: name,
                telefono: phone,
                origen: 'whatsapp',
              },
            });
          }

          customerId = cust.id;

          thread = await tx.crmThread.update({
            where: { id: threadId },
            data: {
              customer_id: cust.id,
              estado_crm: 'compro',
              sync_version: { increment: 1 },
            },
          });
        }
      } else {
        // If customerId is provided but thread is not linked yet, link it.
        if (!thread.customer_id) {
          thread = await tx.crmThread.update({
            where: { id: threadId },
            data: {
              customer_id: customerId,
              estado_crm: 'compro',
              sync_version: { increment: 1 },
            },
          });
        } else {
          // Always mark as compra when a sale is recorded from a thread.
          thread = await tx.crmThread.update({
            where: { id: threadId },
            data: {
              estado_crm: 'compro',
              sync_version: { increment: 1 },
            },
          });
        }
      }
    }

    if (customerId) {
      const cust = await tx.customer.findFirst({
        where: { id: customerId, empresa_id, deleted_at: null },
      });
      if (!cust) throw new ApiError(404, 'Customer not found');
    }

    const sale = await tx.sale.create({
      data: {
        empresa_id,
        thread_id: threadId,
        customer_id: customerId,
        total: total as any,
        detalles: detalles ?? null,
        created_by_user_id: actor?.userId ?? null,
      },
    });

    return { sale, thread };
  });

  res.status(201).json({ item: result.sale, thread: result.thread });
}

export async function listSales(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);

  const items = await prisma.sale.findMany({
    where: { empresa_id, deleted_at: null },
    orderBy: { created_at: 'desc' },
  });

  res.json({ items });
}
