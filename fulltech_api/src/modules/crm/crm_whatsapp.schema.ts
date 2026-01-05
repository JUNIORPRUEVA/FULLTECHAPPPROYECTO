import { z } from 'zod';

export const crmChatsListQuerySchema = z.object({
  search: z.string().optional(),
  status: z.string().optional(),
  productId: z.string().optional(),
  product_id: z.string().optional(),
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(30),
});

export const crmChatMessagesListQuerySchema = z.object({
  before: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(200).optional().default(50),
});

export const crmSendTextSchema = z.object({
  text: z.string().min(1).max(4000),
  aiSuggestionId: z.string().uuid().optional().nullable(),
  aiSuggestedText: z.string().max(8000).optional().nullable(),
  aiUsedKnowledge: z.array(z.string()).max(50).optional().nullable(),
});

export const crmSendMediaFieldsSchema = z.object({
  caption: z.string().max(4000).optional(),
  type: z
    .enum(['image', 'video', 'audio', 'document'])
    .optional(),
});

export const crmMarkReadSchema = z.object({});

export const crmChatPatchSchema = z.object({
  status: z.string().max(50).optional(),
  important: z.boolean().optional(),
  product_id: z.string().max(200).optional().nullable(),
  internal_note: z.string().max(5000).optional().nullable(),
  assigned_user_id: z.string().uuid().optional().nullable(),

  // Requested camelCase API fields (preferred)
  isImportant: z.boolean().optional(),
  productId: z.string().max(200).optional().nullable(),
  note: z.string().max(5000).optional().nullable(),
  assignedToUserId: z.string().uuid().optional().nullable(),
});
