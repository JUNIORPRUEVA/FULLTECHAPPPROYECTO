import type { Request, Response } from 'express';

import { prisma } from '../../config/prisma';
import { actorEmpresaId, actorUserId } from './crm_whatsapp.controller';

function toWireType(crmTaskType: string | null): 'AGENDA' | 'LEVANTAMIENTO' {
  if (String(crmTaskType ?? '').toUpperCase() === 'LEVANTAMIENTO') {
    return 'LEVANTAMIENTO';
  }
  return 'AGENDA';
}

export async function listCrmOperationsItems(req: Request, res: Response) {
  const empresa_id = actorEmpresaId(req);
  const user_id = actorUserId(req);

  const jobs = await prisma.operationsJob.findMany({
    where: {
      empresa_id,
      deleted_at: null,
      crm_chat_id: { not: null },
      OR: [
        { created_by_user_id: user_id },
        { last_update_by_user_id: user_id },
      ],
      crm_task_type: { in: ['LEVANTAMIENTO', 'SERVICIO_RESERVADO', 'INSTALACION', 'GARANTIA'] as any },
    },
    select: {
      id: true,
      crm_chat_id: true,
      crm_task_type: true,
      scheduled_at: true,
      notes: true,
      created_at: true,
      updated_at: true,
    },
    orderBy: { updated_at: 'desc' },
    take: 200,
  });

  const agenda: any[] = [];
  const levantamientos: any[] = [];

  for (const j of jobs as any[]) {
    const item = {
      id: String(j.id),
      chat_id: String(j.crm_chat_id),
      type: toWireType(j.crm_task_type ?? null),
      scheduled_at: j.scheduled_at ? new Date(j.scheduled_at).toISOString() : null,
      nota: j.notes ?? null,
      created_at: new Date(j.created_at).toISOString(),
      updated_at: new Date(j.updated_at).toISOString(),
    };

    if (item.type === 'LEVANTAMIENTO') {
      levantamientos.push(item);
    } else {
      agenda.push(item);
    }
  }

  res.json({ agenda, levantamientos });
}
