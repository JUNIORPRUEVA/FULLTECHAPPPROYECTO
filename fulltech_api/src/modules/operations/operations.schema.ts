import { z } from 'zod';

export const operationsJobStatusEnum = z.enum([
  // Canonical CRM-driven statuses
  'POR_LEVANTAMIENTO',
  'SERVICIO_RESERVADO',
  'SOLUCION_GARANTIA',
  'INSTALACION_PENDIENTE',
  'INSTALACION_FINALIZADA',
  'RESERVA',
  'EN_GARANTIA',

  // Legacy statuses (backward compatible)
  'pending_survey',
  'survey_in_progress',
  'survey_completed',
  'pending_scheduling',
  'scheduled',
  'installation_in_progress',
  'completed',
  'warranty_pending',
  'warranty_in_progress',
  'closed',
  'cancelled',
]);

export const operationsJobPriorityEnum = z.enum(['low', 'normal', 'high']);

export const createJobSchema = z.object({
  id: z.string().uuid().optional(),
  crm_customer_id: z.string().uuid(),
  service_type: z.string().min(1),
  priority: operationsJobPriorityEnum.optional(),
  notes: z.string().optional(),
  initial_status: operationsJobStatusEnum,
  assigned_tech_id: z.string().uuid().optional().nullable(),
  assigned_team_ids: z.array(z.string()).optional(),
});

export const listJobsQuerySchema = z.object({
  // Support both `q` (legacy) and `search` (spec)
  q: z.string().optional(),
  search: z.string().optional(),
  status: operationsJobStatusEnum.optional(),
  assigned_tech_id: z.string().uuid().optional(),
  from: z.string().optional(),
  to: z.string().optional(),

  // Support both offset pagination (legacy) and page/limit (spec)
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(200).default(50),
  offset: z.coerce.number().int().min(0).optional(),
});

export const completeJobSchema = z.object({
  completed_at: z.string().optional(),
});

export const patchJobSchema = z.object({
  status: operationsJobStatusEnum.optional(),
  priority: operationsJobPriorityEnum.optional(),
  assigned_tech_id: z.string().uuid().optional().nullable(),
  assigned_team_ids: z.array(z.string()).optional(),
  notes: z.string().optional(),
});

export const surveyModeEnum = z.enum(['physical', 'virtual']);
export const surveyComplexityEnum = z.enum(['basic', 'intermediate', 'complex']);

export const submitSurveySchema = z.object({
  id: z.string().uuid().optional(),
  job_id: z.string().uuid(),
  mode: surveyModeEnum,
  gps_lat: z.number().optional().nullable(),
  gps_lng: z.number().optional().nullable(),
  address_confirmed: z.string().optional().nullable(),
  complexity: surveyComplexityEnum.optional(),
  site_notes: z.string().optional().nullable(),
  tools_needed: z.any().optional().nullable(),
  materials_needed: z.any().optional().nullable(),
  products_to_use: z.any().optional().nullable(),
  future_opportunities: z.string().optional().nullable(),
  media: z
    .array(
      z.object({
        id: z.string().uuid().optional(),
        type: z.enum(['image', 'video']),
        url_or_path: z.string().min(1),
        caption: z.string().optional().nullable(),
      }),
    )
    .optional(),
});

export const scheduleJobSchema = z.object({
  id: z.string().uuid().optional(),
  job_id: z.string().uuid(),
  scheduled_date: z.string().min(1), // ISO date (YYYY-MM-DD)
  preferred_time: z.string().optional().nullable(),
  assigned_tech_id: z.string().uuid(),
  additional_tech_ids: z.array(z.string().uuid()).optional(),
  customer_availability_notes: z.string().optional().nullable(),
});

export const startInstallationSchema = z.object({
  job_id: z.string().uuid(),
  started_at: z.string().optional(),
});

export const completeInstallationSchema = z.object({
  id: z.string().uuid().optional(),
  job_id: z.string().uuid(),
  finished_at: z.string().optional(),
  tech_notes: z.string().optional().nullable(),
  work_done_summary: z.string().optional().nullable(),
  installed_products: z.any().optional().nullable(),
  media_urls: z.array(z.string()).optional(),
  signature_name: z.string().optional().nullable(),
});

export const warrantyStatusEnum = z.enum(['pending', 'in_progress', 'resolved']);

export const createWarrantyTicketSchema = z.object({
  id: z.string().uuid().optional(),
  job_id: z.string().uuid(),
  reason: z.string().min(1),
  assigned_tech_id: z.string().uuid().optional().nullable(),
});

export const patchWarrantyTicketSchema = z.object({
  status: warrantyStatusEnum.optional(),
  assigned_tech_id: z.string().uuid().optional().nullable(),
  resolution_notes: z.string().optional().nullable(),
  resolved_at: z.string().optional().nullable(),
});

export type CreateJobDto = z.infer<typeof createJobSchema>;
export type ListJobsQuery = z.infer<typeof listJobsQuerySchema>;
export type PatchJobDto = z.infer<typeof patchJobSchema>;
export type SubmitSurveyDto = z.infer<typeof submitSurveySchema>;
export type ScheduleJobDto = z.infer<typeof scheduleJobSchema>;
export type StartInstallationDto = z.infer<typeof startInstallationSchema>;
export type CompleteInstallationDto = z.infer<typeof completeInstallationSchema>;
export type CreateWarrantyTicketDto = z.infer<typeof createWarrantyTicketSchema>;
export type PatchWarrantyTicketDto = z.infer<typeof patchWarrantyTicketSchema>;
export type CompleteJobDto = z.infer<typeof completeJobSchema>;
