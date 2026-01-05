import { z } from 'zod';

export const payrollHalfSchema = z.enum(['FIRST', 'SECOND']);
export const payrollRunStatusSchema = z.enum(['DRAFT', 'REVIEW', 'APPROVED', 'PAID', 'CLOSED']);
export const payrollMovementTypeSchema = z.enum(['EARNING', 'DEDUCTION']);
export const payrollMovementSourceSchema = z.enum([
  'MANUAL',
  'SALES_COMMISSION',
  'ADVANCE',
  'LOAN',
  'ADJUSTMENT',
  'OTHER',
]);
export const payrollMovementStatusSchema = z.enum(['PENDING', 'APPLIED', 'VOIDED']);

export const ensureCurrentPeriodsSchema = z.object({
  year: z.number().int().min(2000).max(2100).optional(),
  month: z.number().int().min(1).max(12).optional(),
});

export const createPayrollRunSchema = z
  .object({
    periodId: z.string().uuid().optional(),
    year: z.number().int().min(2000).max(2100).optional(),
    month: z.number().int().min(1).max(12).optional(),
    half: payrollHalfSchema.optional(),
    notes: z.string().max(2000).optional(),
  })
  .refine((v) => !!v.periodId || (!!v.year && !!v.month && !!v.half), {
    message: 'Debe enviar periodId o year/month/half',
  });

export const listPayrollRunsQuerySchema = z.object({
  year: z.coerce.number().int().min(2000).max(2100).optional(),
  month: z.coerce.number().int().min(1).max(12).optional(),
  half: payrollHalfSchema.optional(),
  status: payrollRunStatusSchema.optional(),
});

export const createPayrollMovementSchema = z.object({
  employee_user_id: z.string().uuid(),
  movement_type: payrollMovementTypeSchema,
  source: payrollMovementSourceSchema,
  concept_code: z.string().min(1).max(64),
  concept_name: z.string().min(1).max(200),
  amount: z.number().positive(),
  effective_date: z.string().min(8).max(32), // YYYY-MM-DD preferred
  note: z.string().max(2000).optional(),
});

export const listPayrollMovementsQuerySchema = z.object({
  employeeId: z.string().uuid().optional(),
  status: payrollMovementStatusSchema.optional(),
  from: z.string().min(8).max(32).optional(),
  to: z.string().min(8).max(32).optional(),
});

export const updatePayrollMovementSchema = z.object({
  movement_type: payrollMovementTypeSchema.optional(),
  source: payrollMovementSourceSchema.optional(),
  concept_code: z.string().min(1).max(64).optional(),
  concept_name: z.string().min(1).max(200).optional(),
  amount: z.number().positive().optional(),
  effective_date: z.string().min(8).max(32).optional(),
  note: z.string().max(2000).nullable().optional(),
});

export type PayrollHalf = z.infer<typeof payrollHalfSchema>;
