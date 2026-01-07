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
  // If true, backend will only record the message and will not call Evolution.
  // Requires remoteMessageId so status webhooks can match.
  skipEvolution: z.boolean().optional(),
  remoteMessageId: z.string().max(200).optional().nullable(),
  aiSuggestionId: z.string().uuid().optional().nullable(),
  aiSuggestedText: z.string().max(8000).optional().nullable(),
  aiUsedKnowledge: z.array(z.string()).max(50).optional().nullable(),
});

export const crmOutboundSendTextSchema = crmSendTextSchema.extend({
  // A normal WhatsApp phone number (any format, backend will normalize).
  phone: z.string().min(6).max(40),
  // Optional CRM status; defaults to "primer_contacto" when creating a new chat.
  status: z.string().max(50).optional(),
  // Optional label for the chat.
  displayName: z.string().max(200).optional(),
});

export const crmSendMediaFieldsSchema = z.object({
  caption: z.string().max(4000).optional(),
  type: z
    .enum(['image', 'video', 'audio', 'document'])
    .optional(),
});

export const crmRecordMediaSchema = z.object({
  mediaUrl: z.string().min(1).max(4000),
  mimeType: z.string().max(200).optional().nullable(),
  size: z.coerce.number().int().min(0).optional().nullable(),
  fileName: z.string().max(500).optional().nullable(),
  caption: z.string().max(4000).optional().nullable(),
  type: z.enum(['image', 'video', 'audio', 'document']).optional(),

  // If true, backend will only record and will not call Evolution.
  // Requires remoteMessageId so status webhooks can match.
  skipEvolution: z.boolean().optional(),
  remoteMessageId: z.string().max(200).optional().nullable(),
});

export const crmEditChatMessageSchema = z.object({
  text: z.string().min(1).max(4000),
});

export const crmDeleteChatMessageSchema = z.object({
  // Reserved for future options (forEveryone, etc).
});

export const crmMarkReadSchema = z.object({});

export const crmChatPatchSchema = z.object({
  status: z.string().max(50).optional(),
  important: z.boolean().optional(),
  follow_up: z.boolean().optional(),
  product_id: z.string().max(200).optional().nullable(),
  internal_note: z.string().max(5000).optional().nullable(),
  assigned_user_id: z.string().uuid().optional().nullable(),

  // Requested camelCase API fields (preferred)
  isImportant: z.boolean().optional(),
  followUp: z.boolean().optional(),
  productId: z.string().max(200).optional().nullable(),
  note: z.string().max(5000).optional().nullable(),
  assignedToUserId: z.string().uuid().optional().nullable(),
});
