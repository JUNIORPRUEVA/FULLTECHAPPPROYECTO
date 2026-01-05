import { z } from 'zod';

export const crmQuickRepliesListQuerySchema = z.object({
  search: z.string().optional(),
  category: z.string().optional(),
  isActive: z
    .union([z.literal('true'), z.literal('false')])
    .optional()
    .transform((v) => (v === undefined ? undefined : v === 'true')),
});

export const crmQuickReplyUpsertSchema = z.object({
  title: z.string().min(1).max(200),
  category: z.string().min(1).max(100),
  content: z.string().min(1).max(5000),
  keywords: z.string().max(2000).optional().nullable(),
  allowComment: z.boolean().optional().default(true),
  isActive: z.boolean().optional().default(true),
});
