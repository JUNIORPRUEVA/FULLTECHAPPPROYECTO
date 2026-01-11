-- Adds normalized columns for the simplified Operations flow.
-- Safe/idempotent migration.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'operations_jobs'
      AND column_name = 'tipo_trabajo'
  ) THEN
    ALTER TABLE public.operations_jobs
      ADD COLUMN tipo_trabajo TEXT NOT NULL DEFAULT 'INSTALACION';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'operations_jobs'
      AND column_name = 'estado'
  ) THEN
    ALTER TABLE public.operations_jobs
      ADD COLUMN estado TEXT NOT NULL DEFAULT 'PENDIENTE';
  END IF;
END $$;

-- Normalize existing data (best-effort).
UPDATE public.operations_jobs
SET tipo_trabajo = CASE
  WHEN tipo_trabajo IS NOT NULL AND btrim(tipo_trabajo) <> '' THEN tipo_trabajo
  WHEN crm_task_type = 'LEVANTAMIENTO' THEN 'LEVANTAMIENTO'
  WHEN crm_task_type = 'GARANTIA' THEN 'GARANTIA'
  WHEN crm_task_type = 'INSTALACION' THEN 'INSTALACION'
  WHEN crm_task_type = 'SERVICIO_RESERVADO' THEN
    CASE
      WHEN lower(coalesce(service_type, '')) LIKE '%manten%' THEN 'MANTENIMIENTO'
      ELSE 'INSTALACION'
    END
  WHEN lower(coalesce(service_type, '')) LIKE '%manten%' THEN 'MANTENIMIENTO'
  ELSE 'INSTALACION'
END
WHERE tipo_trabajo IS NULL OR btrim(tipo_trabajo) = '';

UPDATE public.operations_jobs
SET estado = CASE
  WHEN estado IS NOT NULL AND btrim(estado) <> '' THEN estado
  WHEN status IN ('pending_survey','survey_in_progress','survey_completed','pending_scheduling','warranty_pending') THEN 'PENDIENTE'
  WHEN status IN ('scheduled') THEN 'PROGRAMADO'
  WHEN status IN ('installation_in_progress','warranty_in_progress') THEN 'EN_EJECUCION'
  WHEN status IN ('completed') THEN 'FINALIZADO'
  WHEN status IN ('closed') THEN 'CERRADO'
  WHEN status IN ('cancelled') THEN 'CANCELADO'
  ELSE 'PENDIENTE'
END
WHERE estado IS NULL OR btrim(estado) = '';

-- Add basic CHECK constraints (only if not already present).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'operations_jobs_tipo_trabajo_check'
  ) THEN
    ALTER TABLE public.operations_jobs
      ADD CONSTRAINT operations_jobs_tipo_trabajo_check
      CHECK (tipo_trabajo IN ('INSTALACION','MANTENIMIENTO','LEVANTAMIENTO','GARANTIA'));
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'operations_jobs_estado_check'
  ) THEN
    ALTER TABLE public.operations_jobs
      ADD CONSTRAINT operations_jobs_estado_check
      CHECK (estado IN ('PENDIENTE','PROGRAMADO','EN_EJECUCION','FINALIZADO','CERRADO','CANCELADO'));
  END IF;
END $$;
