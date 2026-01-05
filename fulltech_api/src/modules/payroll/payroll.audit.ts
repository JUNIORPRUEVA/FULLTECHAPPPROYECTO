import { prisma } from '../../config/prisma';

export async function logAudit({
  empresaId,
  actorUserId,
  action,
  entity,
  entityId,
  meta,
}: {
  empresaId: string;
  actorUserId: string;
  action: string;
  entity: string;
  entityId: string;
  meta?: any;
}) {
  try {
    await prisma.auditLog.create({
      data: {
        empresa_id: empresaId,
        actor_user_id: actorUserId,
        action,
        entity,
        entity_id: entityId,
        meta: meta ?? undefined,
      },
    });
  } catch (e) {
    // audit should not break main flow
    console.warn('[AUDIT_LOG] failed:', e);
  }
}
