import { z } from 'zod';

export const aiSuggestSchema = z.object({
  chatId: z.string().uuid().optional().nullable(),
  lastCustomerMessageId: z.string().uuid().optional().nullable(),
  customerMessageText: z.string().min(1).max(8000),
  customerPhone: z.string().optional().nullable(),
  customerName: z.string().optional().nullable(),
  currentChatState: z.string().optional().nullable(),
  assignedProductId: z.string().optional().nullable(),
  quickRepliesEnabled: z.boolean().optional().default(true),
});

export const aiSettingsUpsertSchema = z.object({
  enabled: z.boolean().optional(),
  quickRepliesEnabled: z.boolean().optional(),
  systemPrompt: z.string().max(20000).optional().nullable(),
  tone: z.enum(['Ejecutivo', 'Cercano', 'Formal']).optional().nullable(),
  rules: z.string().max(20000).optional().nullable(),
  businessData: z.record(z.any()).optional().nullable(),
});

export const aiGenerateLetterSchema = z.object({
  companyProfile: z.record(z.any()),
  letterType: z.string().min(1).max(80),
  quotation: z.record(z.any()).optional().nullable(),
  manualCustomer: z
    .object({
      name: z.string().min(1).max(200),
      phone: z.string().max(60).optional().nullable(),
      email: z.string().email().max(180).optional().nullable(),
    })
    .optional()
    .nullable(),
  manualContext: z.string().max(5000).optional().nullable(),
  action: z.enum(['generate', 'improve', 'more_formal', 'shorter']).optional().default('generate'),
  subject: z.string().max(400).optional().nullable(),
  body: z.string().max(20000).optional().nullable(),
  tone: z.enum(['Ejecutivo', 'Cercano', 'Formal']).optional().nullable(),
});
