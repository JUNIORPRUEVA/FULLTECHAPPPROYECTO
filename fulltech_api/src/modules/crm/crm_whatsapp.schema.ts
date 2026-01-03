import { z } from 'zod';

export const crmChatsListQuerySchema = z.object({
  search: z.string().optional(),
  status: z.string().optional(),
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(30),
});

export const crmChatMessagesListQuerySchema = z.object({
  before: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(200).optional().default(50),
});

export const crmSendTextSchema = z.object({
  text: z.string().min(1).max(4000),
});

export const crmSendMediaFieldsSchema = z.object({
  caption: z.string().max(4000).optional(),
  type: z
    .enum(['image', 'video', 'audio', 'document'])
    .optional(),
});

export const crmMarkReadSchema = z.object({});
