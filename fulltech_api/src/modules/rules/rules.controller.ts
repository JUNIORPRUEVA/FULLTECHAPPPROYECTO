import type { Request, Response } from 'express';

import { z } from 'zod';

import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';

import {
  listRulesQuerySchema,
  patchRulesContentSchema,
  rulesIdParamsSchema,
  rulesCategorySchema,
  upsertRulesContentSchema,
  userRoleSchema,
} from './rules.schema';

function isAdminRole(role: string | undefined): boolean {
  return role === 'admin' || role === 'administrador';
}

function normalizeRole(role: string | undefined): z.infer<typeof userRoleSchema> | null {
  const parsed = userRoleSchema.safeParse(role);
  return parsed.success ? parsed.data : null;
}

function normalizeCategory(category: unknown) {
  const parsed = rulesCategorySchema.safeParse(category);
  return parsed.success ? parsed.data : null;
}

function pickSort(sort: 'order' | 'updatedAt_desc') {
  if (sort === 'updatedAt_desc') {
    return [{ updated_at: 'desc' as const }];
  }
  return [
    { category: 'asc' as const },
    { order_index: 'asc' as const },
    { updated_at: 'desc' as const },
  ];
}

export async function listRules(req: Request, res: Response) {
  const actor = req.user;
  if (!actor?.empresaId) throw new ApiError(401, 'Unauthorized');

  const parsed = listRulesQuerySchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const isAdmin = isAdminRole(actor.role);
  const q = parsed.data.q?.trim();

  const category = normalizeCategory(parsed.data.category);
  const roleFilterRaw = parsed.data.role?.trim();
  const roleFilter = roleFilterRaw ? normalizeRole(roleFilterRaw) : null;
  const roleFilterIsAll = roleFilterRaw?.toUpperCase?.() === 'ALL';

  const fromDate = parsed.data.fromDate ? new Date(parsed.data.fromDate) : null;
  const toDate = parsed.data.toDate ? new Date(parsed.data.toDate) : null;

  const limit = parsed.data.limit;
  const page = parsed.data.page;
  const skip = (page - 1) * limit;

  const where: any = {
    empresa_id: actor.empresaId,
  };

  if (category) where.category = category;

  if (q && q.length > 0) {
    where.OR = [
      { title: { contains: q, mode: 'insensitive' } },
      { content: { contains: q, mode: 'insensitive' } },
    ];
  }

  if (fromDate || toDate) {
    where.updated_at = {
      ...(fromDate ? { gte: fromDate } : {}),
      ...(toDate ? { lte: toDate } : {}),
    };
  }

  if (!isAdmin) {
    const actorRole = normalizeRole(actor.role);
    if (!actorRole) throw new ApiError(403, 'Forbidden');

    where.is_active = true;
    where.OR = [
      ...(where.OR ?? []),
      { visible_to_all: true },
      { role_visibility: { has: actorRole } },
    ];

    // For non-admin, ignore active/role filters (server-enforced visibility)
  } else {
    if (parsed.data.active !== undefined) where.is_active = parsed.data.active;

    if (roleFilterIsAll) {
      where.visible_to_all = true;
    } else if (roleFilter) {
      where.OR = [
        { visible_to_all: true },
        { role_visibility: { has: roleFilter } },
      ];
    }
  }

  const [total, items] = await Promise.all([
    prisma.rulesContent.count({ where }),
    prisma.rulesContent.findMany({
      where,
      orderBy: pickSort(parsed.data.sort),
      skip,
      take: limit,
    }),
  ]);

  res.json({
    page,
    page_size: limit,
    total,
    items: items.map((i) => ({
      id: i.id,
      title: i.title,
      category: i.category,
      content: i.content,
      visibleToAll: i.visible_to_all,
      roleVisibility: i.role_visibility,
      isActive: i.is_active,
      orderIndex: i.order_index,
      createdBy: i.created_by_user_id,
      createdAt: i.created_at,
      updatedAt: i.updated_at,
    })),
  });
}

export async function getRule(req: Request, res: Response) {
  const actor = req.user;
  if (!actor?.empresaId) throw new ApiError(401, 'Unauthorized');

  const parsedParams = rulesIdParamsSchema.safeParse(req.params);
  if (!parsedParams.success) throw new ApiError(400, 'Invalid id', parsedParams.error.flatten());

  const isAdmin = isAdminRole(actor.role);

  const item = await prisma.rulesContent.findFirst({
    where: { id: parsedParams.data.id, empresa_id: actor.empresaId },
  });

  if (!item) throw new ApiError(404, 'Rule not found');

  if (!isAdmin) {
    const actorRole = normalizeRole(actor.role);
    if (!actorRole) throw new ApiError(403, 'Forbidden');

    const visible = item.visible_to_all || item.role_visibility.includes(actorRole);
    if (!item.is_active || !visible) throw new ApiError(404, 'Rule not found');
  }

  res.json({
    item: {
      id: item.id,
      title: item.title,
      category: item.category,
      content: item.content,
      visibleToAll: item.visible_to_all,
      roleVisibility: item.role_visibility,
      isActive: item.is_active,
      orderIndex: item.order_index,
      createdBy: item.created_by_user_id,
      createdAt: item.created_at,
      updatedAt: item.updated_at,
    },
  });
}

export async function createRule(req: Request, res: Response) {
  const actor = req.user;
  if (!actor?.empresaId || !actor?.userId) throw new ApiError(401, 'Unauthorized');

  if (!isAdminRole(actor.role)) {
    throw new ApiError(403, 'Forbidden');
  }

  const parsed = upsertRulesContentSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const created = await prisma.rulesContent.create({
    data: {
      empresa_id: actor.empresaId,
      title: parsed.data.title,
      category: parsed.data.category as any,
      content: parsed.data.content,
      visible_to_all: parsed.data.visibleToAll,
      role_visibility: parsed.data.visibleToAll ? [] : (parsed.data.roleVisibility as any),
      is_active: parsed.data.isActive,
      order_index: parsed.data.orderIndex,
      created_by_user_id: actor.userId,
    },
  });

  res.status(201).json({
    item: {
      id: created.id,
      title: created.title,
      category: created.category,
      content: created.content,
      visibleToAll: created.visible_to_all,
      roleVisibility: created.role_visibility,
      isActive: created.is_active,
      orderIndex: created.order_index,
      createdBy: created.created_by_user_id,
      createdAt: created.created_at,
      updatedAt: created.updated_at,
    },
  });
}

export async function updateRule(req: Request, res: Response) {
  const actor = req.user;
  if (!actor?.empresaId) throw new ApiError(401, 'Unauthorized');

  if (!isAdminRole(actor.role)) {
    throw new ApiError(403, 'Forbidden');
  }

  const parsedParams = rulesIdParamsSchema.safeParse(req.params);
  if (!parsedParams.success) throw new ApiError(400, 'Invalid id', parsedParams.error.flatten());

  const parsed = patchRulesContentSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const existing = await prisma.rulesContent.findFirst({
    where: { id: parsedParams.data.id, empresa_id: actor.empresaId },
  });
  if (!existing) throw new ApiError(404, 'Rule not found');

  const visibleToAll = parsed.data.visibleToAll ?? existing.visible_to_all;
  const roleVisibility =
    parsed.data.roleVisibility ?? (existing.role_visibility as unknown as string[]);

  if (visibleToAll === false && roleVisibility.length === 0) {
    throw new ApiError(400, 'roleVisibility is required when visibleToAll=false');
  }

  const updated = await prisma.rulesContent.update({
    where: { id: existing.id },
    data: {
      ...(parsed.data.title !== undefined ? { title: parsed.data.title } : {}),
      ...(parsed.data.category !== undefined ? { category: parsed.data.category as any } : {}),
      ...(parsed.data.content !== undefined ? { content: parsed.data.content } : {}),
      ...(parsed.data.isActive !== undefined ? { is_active: parsed.data.isActive } : {}),
      ...(parsed.data.orderIndex !== undefined ? { order_index: parsed.data.orderIndex } : {}),
      ...(parsed.data.visibleToAll !== undefined ? { visible_to_all: parsed.data.visibleToAll } : {}),
      ...(parsed.data.roleVisibility !== undefined
        ? { role_visibility: visibleToAll ? [] : (parsed.data.roleVisibility as any) }
        : {}),
    },
  });

  res.json({
    item: {
      id: updated.id,
      title: updated.title,
      category: updated.category,
      content: updated.content,
      visibleToAll: updated.visible_to_all,
      roleVisibility: updated.role_visibility,
      isActive: updated.is_active,
      orderIndex: updated.order_index,
      createdBy: updated.created_by_user_id,
      createdAt: updated.created_at,
      updatedAt: updated.updated_at,
    },
  });
}

export async function deleteRule(req: Request, res: Response) {
  const actor = req.user;
  if (!actor?.empresaId) throw new ApiError(401, 'Unauthorized');

  if (!isAdminRole(actor.role)) {
    throw new ApiError(403, 'Forbidden');
  }

  const parsedParams = rulesIdParamsSchema.safeParse(req.params);
  if (!parsedParams.success) throw new ApiError(400, 'Invalid id', parsedParams.error.flatten());

  const existing = await prisma.rulesContent.findFirst({
    where: { id: parsedParams.data.id, empresa_id: actor.empresaId },
  });
  if (!existing) throw new ApiError(404, 'Rule not found');

  await prisma.rulesContent.delete({ where: { id: existing.id } });
  res.json({ ok: true });
}

export async function toggleRuleActive(req: Request, res: Response) {
  const actor = req.user;
  if (!actor?.empresaId) throw new ApiError(401, 'Unauthorized');

  if (!isAdminRole(actor.role)) {
    throw new ApiError(403, 'Forbidden');
  }

  const parsedParams = rulesIdParamsSchema.safeParse(req.params);
  if (!parsedParams.success) throw new ApiError(400, 'Invalid id', parsedParams.error.flatten());

  const existing = await prisma.rulesContent.findFirst({
    where: { id: parsedParams.data.id, empresa_id: actor.empresaId },
  });
  if (!existing) throw new ApiError(404, 'Rule not found');

  const updated = await prisma.rulesContent.update({
    where: { id: existing.id },
    data: { is_active: !existing.is_active },
  });

  res.json({
    item: {
      id: updated.id,
      isActive: updated.is_active,
      updatedAt: updated.updated_at,
    },
  });
}
