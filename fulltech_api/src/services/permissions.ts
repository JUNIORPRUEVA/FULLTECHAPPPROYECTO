import { prisma } from '../config/prisma';

export type PermissionCode = string;

// Legacy role fallbacks (backwards compatibility)
const ROLE_DEFAULTS: Record<string, PermissionCode[]> = {
  admin: ['*'],
  administrador: ['*'],
  vendedor: ['pos.sell', 'pos.reports.view', 'printing.use'],
  tecnico: ['inventory.view'],
  tecnico_fijo: ['inventory.view'],
  contratista: ['inventory.view'],
  asistente_administrativo: ['users.view', 'reports.view'],
};

function setHasStar(set: Set<string>): boolean {
  return set.has('*');
}

export async function getPermissionCatalog(): Promise<
  Array<{ code: string; description: string }>
> {
  const rows = await prisma.$queryRaw<Array<{ code: string; description: string }>>`
    SELECT code, description
    FROM rbac_permissions
    ORDER BY code ASC;
  `;
  return rows;
}

export async function getUserEffectivePermissions(params: {
  empresaId: string;
  userId: string;
  legacyRole?: string | null;
}): Promise<Set<string>> {
  const { empresaId, userId, legacyRole } = params;

  const permSet = new Set<string>();

  // Legacy role mapping (fast path)
  if (legacyRole) {
    const defaults = ROLE_DEFAULTS[legacyRole] ?? [];
    for (const code of defaults) {
      permSet.add(code);
    }
  }

  // If admin-like by legacy role -> grant all
  if (setHasStar(permSet)) return permSet;

  // RBAC roles -> permissions
  const rolePerms = await prisma.$queryRaw<Array<{ permission_code: string }>>`
    SELECT rp.permission_code
    FROM rbac_user_roles ur
    JOIN rbac_roles r ON r.id = ur.role_id
    JOIN rbac_role_permissions rp ON rp.role_id = r.id
    WHERE ur.user_id = ${userId}::uuid
      AND r.empresa_id = ${empresaId}::uuid;
  `;
  for (const row of rolePerms) permSet.add(row.permission_code);

  // User overrides (deny wins over allow)
  const overrides = await prisma.$queryRaw<
    Array<{ permission_code: string; effect: 'allow' | 'deny' }>
  >`
    SELECT permission_code, effect
    FROM rbac_user_permission_overrides
    WHERE user_id = ${userId}::uuid;
  `;

  for (const o of overrides) {
    if (o.effect === 'deny') permSet.delete(o.permission_code);
  }
  for (const o of overrides) {
    if (o.effect === 'allow') permSet.add(o.permission_code);
  }

  return permSet;
}

export function hasPermission(
  permissions: Set<string> | undefined,
  code: string,
): boolean {
  if (!permissions) return false;
  if (permissions.has('*')) return true;
  return permissions.has(code);
}
