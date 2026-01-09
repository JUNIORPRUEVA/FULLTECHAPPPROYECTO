-- CRM (crm_chats) ↔ Operations (operations_jobs) sync support

-- 1) Nullable assigned tech for schedules (seller can reserve without assigning immediately)
DO $$
BEGIN
  IF to_regclass('operations_schedule') IS NOT NULL THEN
    ALTER TABLE operations_schedule
      ALTER COLUMN assigned_tech_id DROP NOT NULL;
  END IF;
END$$;

-- 2) Task type enum for CRM-originated operations jobs
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'OperationsCrmTaskType') THEN
    CREATE TYPE "OperationsCrmTaskType" AS ENUM (
      'LEVANTAMIENTO',
      'SERVICIO_RESERVADO',
      'GARANTIA',
      'INSTALACION'
    );
  END IF;
END$$;

-- 3) Extend operations_jobs to link back to crm_chats and store operational metadata
DO $$
BEGIN
  IF to_regclass('operations_jobs') IS NOT NULL THEN
    ALTER TABLE operations_jobs
      ADD COLUMN IF NOT EXISTS crm_chat_id uuid NULL,
      ADD COLUMN IF NOT EXISTS crm_task_type "OperationsCrmTaskType" NULL,
      ADD COLUMN IF NOT EXISTS product_id uuid NULL,
      ADD COLUMN IF NOT EXISTS service_id uuid NULL,
      ADD COLUMN IF NOT EXISTS technician_notes text NULL,
      ADD COLUMN IF NOT EXISTS cancel_reason text NULL,
      ADD COLUMN IF NOT EXISTS last_update_by_user_id uuid NULL;
  END IF;
END$$;

DO $$
BEGIN
  IF to_regclass('operations_jobs') IS NOT NULL AND to_regclass('crm_chats') IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_name = 'operations_jobs_crm_chat_id_fkey'
  ) THEN
    ALTER TABLE operations_jobs
      ADD CONSTRAINT operations_jobs_crm_chat_id_fkey
      FOREIGN KEY (crm_chat_id) REFERENCES crm_chats(id)
      ON DELETE SET NULL;
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_operations_jobs_crm_chat_id
  ON operations_jobs(crm_chat_id);
CREATE INDEX IF NOT EXISTS idx_operations_jobs_crm_task_type
  ON operations_jobs(crm_task_type);
CREATE INDEX IF NOT EXISTS idx_operations_jobs_product_id
  ON operations_jobs(product_id);
CREATE INDEX IF NOT EXISTS idx_operations_jobs_service_id
  ON operations_jobs(service_id);

-- 4) Operations job history / audit trail
CREATE TABLE IF NOT EXISTS operations_job_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL,
  action_type text NOT NULL,
  old_status text,
  new_status text,
  note text,
  created_by_user_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF to_regclass('operations_jobs') IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_name = 'operations_job_history_job_id_fkey'
  ) THEN
    ALTER TABLE operations_job_history
      ADD CONSTRAINT operations_job_history_job_id_fkey
      FOREIGN KEY (job_id) REFERENCES operations_jobs(id)
      ON DELETE CASCADE;
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_operations_job_history_job_id
  ON operations_job_history(job_id);
CREATE INDEX IF NOT EXISTS idx_operations_job_history_created_at
  ON operations_job_history(created_at DESC);

-- 5) Permission catalog entries (if RBAC module exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rbac_permissions') THEN
    INSERT INTO rbac_permissions (code, description)
    VALUES
      ('operations.view', 'Ver módulo de Operaciones'),
      ('operations.update_status', 'Actualizar estatus operativo'),
      ('operations.assign_technician', 'Asignar técnico en Operaciones'),
      ('operations.view_history', 'Ver historial de tareas operativas')
    ON CONFLICT (code) DO NOTHING;
  END IF;
END$$;
