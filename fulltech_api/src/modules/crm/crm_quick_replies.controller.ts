import type { Request, Response } from 'express';

import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import {
  crmQuickRepliesListQuerySchema,
  crmQuickReplyUpsertSchema,
} from './crm_quick_replies.schema';

function toQuickReplyItem(row: any) {
  return {
    id: row.id,
    title: row.title,
    category: row.category,
    content: row.content,
    keywords: row.keywords ?? null,
    allowComment: typeof row.allow_comment === 'boolean' ? row.allow_comment : true,
    isActive: Boolean(row.is_active ?? row.isActive ?? true),
    createdAt: row.created_at ?? null,
    updatedAt: row.updated_at ?? null,

    // snake_case compat
    is_active: Boolean(row.is_active ?? row.isActive ?? true),
    allow_comment: typeof row.allow_comment === 'boolean' ? row.allow_comment : true,
    created_at: row.created_at ?? null,
    updated_at: row.updated_at ?? null,
  };
}

export async function listQuickReplies(req: Request, res: Response) {
  const parsed = crmQuickRepliesListQuerySchema.safeParse(req.query);
  if (!parsed.success) throw new ApiError(400, 'Invalid query', parsed.error.flatten());

  const { search, category, isActive } = parsed.data;

  const where: string[] = [];
  const params: any[] = [];
  let idx = 1;

  if (typeof isActive === 'boolean') {
    where.push(`is_active = $${idx}::boolean`);
    params.push(isActive);
    idx++;
  }

  if (category && category.trim().length > 0) {
    where.push(`category = $${idx}::text`);
    params.push(category.trim());
    idx++;
  }

  if (search && search.trim().length > 0) {
    where.push(`(title ILIKE $${idx} OR content ILIKE $${idx} OR keywords ILIKE $${idx})`);
    params.push(`%${search.trim()}%`);
    idx++;
  }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';

  const rows = await prisma.$queryRawUnsafe<any[]>(
    `
      SELECT id, title, category, content, keywords, allow_comment, is_active, created_at, updated_at
      FROM quick_replies
      ${whereSql}
      ORDER BY updated_at DESC, created_at DESC
    `,
    ...params,
  );

  res.json({ items: rows.map(toQuickReplyItem) });
}

export async function createQuickReply(req: Request, res: Response) {
  const parsed = crmQuickReplyUpsertSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const { title, category, content, isActive, keywords, allowComment } = parsed.data;

  const rows = await prisma.$queryRawUnsafe<any[]>(
    `
      INSERT INTO quick_replies (title, category, content, keywords, allow_comment, is_active)
      VALUES ($1::text, $2::text, $3::text, $4::text, $5::boolean, $6::boolean)
      RETURNING id, title, category, content, keywords, allow_comment, is_active, created_at, updated_at
    `,
    title,
    category,
    content,
    keywords ?? null,
    allowComment,
    isActive,
  );

  res.status(201).json({ item: toQuickReplyItem(rows[0]) });
}

export async function updateQuickReply(req: Request, res: Response) {
  const id = req.params.id;

  const parsed = crmQuickReplyUpsertSchema.safeParse(req.body);
  if (!parsed.success) throw new ApiError(400, 'Invalid payload', parsed.error.flatten());

  const { title, category, content, isActive, keywords, allowComment } = parsed.data;

  const rows = await prisma.$queryRawUnsafe<any[]>(
    `
      UPDATE quick_replies
      SET title = $2::text,
          category = $3::text,
          content = $4::text,
          keywords = $5::text,
          allow_comment = $6::boolean,
          is_active = $7::boolean,
          updated_at = now()
      WHERE id = $1::uuid
      RETURNING id, title, category, content, keywords, allow_comment, is_active, created_at, updated_at
    `,
    id,
    title,
    category,
    content,
    keywords ?? null,
    allowComment,
    isActive,
  );

  if (!rows.length) throw new ApiError(404, 'Quick reply not found');
  res.json({ item: toQuickReplyItem(rows[0]) });
}

export async function deleteQuickReply(req: Request, res: Response) {
  const id = req.params.id;

  const deleted = await prisma.$executeRawUnsafe(
    `DELETE FROM quick_replies WHERE id = $1::uuid`,
    id,
  );

  if (!deleted) throw new ApiError(404, 'Quick reply not found');
  res.json({ ok: true });
}
