import { z } from 'zod';

export const rulesCategorySchema = z.enum([
  'VISION',
  'MISSION',
  'VALUES',
  'POLICY',
  'ROLE_RESPONSIBILITIES',
  'PROCEDURE',
  'GENERAL',
]);

export const userRoleSchema = z.enum([
  'admin',
  'administrador',
  'vendedor',
  'tecnico',
  'tecnico_fijo',
  'contratista',
  'asistente_administrativo',
]);

export const rulesIdParamsSchema = z.object({
  id: z.string().uuid(),
});

export const listRulesQuerySchema = z.object({
  q: z.string().max(200).optional(),
  category: rulesCategorySchema.optional(),

  // Filter by role visibility. Special value: ALL
  role: z.string().max(60).optional(),

  active: z.coerce.boolean().optional(),
  fromDate: z.string().datetime().optional(),
  toDate: z.string().datetime().optional(),

  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(200).default(50),

  // Supported: order (default), updatedAt_desc
  sort: z.enum(['order', 'updatedAt_desc']).optional().default('order'),
});

const roleVisibilityListSchema = z.array(userRoleSchema).max(50);

const upsertRulesContentBaseSchema = z.object({
  title: z.string().min(1).max(200),
  category: rulesCategorySchema,
  content: z.string().min(1).max(40000),

  visibleToAll: z.coerce.boolean().default(true),
  roleVisibility: roleVisibilityListSchema.optional().default([]),

  isActive: z.coerce.boolean().optional().default(true),
  orderIndex: z.coerce.number().int().min(0).max(100000).optional().default(0),
});

export const upsertRulesContentSchema = upsertRulesContentBaseSchema.superRefine(
  (v: z.infer<typeof upsertRulesContentBaseSchema>, ctx: z.RefinementCtx) => {
    if (!v.visibleToAll && (!v.roleVisibility || v.roleVisibility.length === 0)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['roleVisibility'],
        message: 'roleVisibility is required when visibleToAll=false',
      });
    }
  },
);

export const patchRulesContentSchema = upsertRulesContentBaseSchema
  .partial()
  .superRefine((v: Partial<z.infer<typeof upsertRulesContentBaseSchema>>, ctx: z.RefinementCtx) => {
    if (v.visibleToAll === false && (v.roleVisibility?.length ?? 0) === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['roleVisibility'],
        message: 'roleVisibility is required when visibleToAll=false',
      });
    }
  });
