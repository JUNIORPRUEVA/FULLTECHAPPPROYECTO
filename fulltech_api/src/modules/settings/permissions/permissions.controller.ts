import { Request, Response } from 'express';

import { prisma } from '../../../config/prisma';
import { getPermissionCatalog, getUserEffectivePermissions } from '../../../services/permissions';

export async function getPermissionsCatalog(req: Request, res: Response) {
  const items = await getPermissionCatalog();
  res.json({ items });
}

export async function getMyPermissions(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const userId = req.user!.userId;

  const u = await prisma.usuario.findUnique({
    where: { id: userId },
    select: { rol: true },
  });

  const perms = await getUserEffectivePermissions({
    empresaId,
    userId,
    legacyRole: u?.rol ?? req.user!.role,
  });

  res.json({ permissions: Array.from(perms).sort() });
}

export async function listUsersWithPermissions(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const users = await prisma.usuario.findMany({
    where: { empresa_id: empresaId },
    select: {
      id: true,
      nombre_completo: true,
      email: true,
      rol: true,
      estado: true,
    },
    orderBy: { created_at: 'asc' },
  });

  // Roles assigned via new RBAC tables
  const roleRows = await prisma.$queryRaw<
    Array<{ user_id: string; role_id: string; role_name: string }>
  >`
    SELECT ur.user_id::text as user_id,
           ur.role_id::text as role_id,
           r.name as role_name
    FROM rbac_user_roles ur
    JOIN rbac_roles r ON r.id = ur.role_id
    WHERE r.empresa_id = ${empresaId}::uuid;
  `;

  const rolesByUser = new Map<string, Array<{ id: string; name: string }>>();
  for (const r of roleRows) {
    const list = rolesByUser.get(r.user_id) ?? [];
    list.push({ id: r.role_id, name: r.role_name });
    rolesByUser.set(r.user_id, list);
  }

  const overrideRows = await prisma.$queryRaw<
    Array<{ user_id: string; permission_code: string; effect: 'allow' | 'deny' }>
  >`
    SELECT user_id::text as user_id, permission_code, effect
    FROM rbac_user_permission_overrides
    WHERE user_id IN (
      SELECT id FROM "Usuario" WHERE empresa_id = ${empresaId}::uuid
    );
  `;

  const overridesByUser = new Map<
    string,
    Array<{ code: string; effect: 'allow' | 'deny' }>
  >();
  for (const o of overrideRows) {
    const list = overridesByUser.get(o.user_id) ?? [];
    list.push({ code: o.permission_code, effect: o.effect });
    overridesByUser.set(o.user_id, list);
  }

  const shaped = await Promise.all(
    users.map(async (u) => {
      const perms = await getUserEffectivePermissions({
        empresaId,
        userId: u.id,
        legacyRole: u.rol,
      });

      return {
        id: u.id,
        name: u.nombre_completo,
        email: u.email,
        legacyRole: u.rol,
        estado: u.estado,
        roles: rolesByUser.get(u.id) ?? [],
        overrides: overridesByUser.get(u.id) ?? [],
        effectivePermissions: Array.from(perms).sort(),
      };
    }),
  );

  res.json({ items: shaped });
}

export async function listRoles(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;

  const roles = await prisma.$queryRaw<
    Array<{ id: string; name: string; is_system: boolean }>
  >`
    SELECT id::text as id, name, is_system
    FROM rbac_roles
    WHERE empresa_id = ${empresaId}::uuid
    ORDER BY is_system DESC, name ASC;
  `;

  res.json({ items: roles });
}

export async function updateUserPermissions(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const { id } = req.params;
  const body = req.body as {
    roleIds?: string[];
    overrides?: Array<{ code: string; effect: 'allow' | 'deny' }>;
  };

  const roleIds = Array.isArray(body.roleIds) ? body.roleIds : [];
  const overrides = Array.isArray(body.overrides) ? body.overrides : [];

  // Validate user belongs to empresa
  const user = await prisma.usuario.findFirst({
    where: { id, empresa_id: empresaId },
    select: { id: true },
  });
  if (!user) return res.status(404).json({ error: 'not_found' });

  // Validate roleIds belong to empresa
  if (roleIds.length > 0) {
    const roles = await prisma.$queryRaw<Array<{ id: string }>>`
      SELECT id::text as id
      FROM rbac_roles
      WHERE empresa_id = ${empresaId}::uuid
        AND id = ANY(${roleIds}::uuid[]);
    `;
    if (roles.length !== roleIds.length) {
      return res.status(400).json({ error: 'invalid_role_ids' });
    }
  }

  // Validate override codes exist in catalog
  if (overrides.length > 0) {
    const codes = overrides.map((o) => o.code);
    const existing = await prisma.$queryRaw<Array<{ code: string }>>`
      SELECT code
      FROM rbac_permissions
      WHERE code = ANY(${codes}::text[]);
    `;
    if (existing.length !== codes.length) {
      return res.status(400).json({ error: 'invalid_permission_code' });
    }
  }

  await prisma.$transaction(async (tx) => {
    // Replace roles
    await tx.$executeRaw`
      DELETE FROM rbac_user_roles
      WHERE user_id = ${id}::uuid;
    `;

    if (roleIds.length > 0) {
      await tx.$executeRaw`
        INSERT INTO rbac_user_roles(user_id, role_id)
        SELECT ${id}::uuid, unnest(${roleIds}::uuid[]);
      `;
    }

    // Replace overrides (upsert)
    await tx.$executeRaw`
      DELETE FROM rbac_user_permission_overrides
      WHERE user_id = ${id}::uuid;
    `;

    for (const o of overrides) {
      await tx.$executeRaw`
        INSERT INTO rbac_user_permission_overrides(user_id, permission_code, effect)
        VALUES (${id}::uuid, ${o.code}::text, ${o.effect}::text);
      `;
    }
  });

  res.json({ ok: true });
}
