-- HOTFIX: Ensure CRM <-> Operations sync columns/tables exist
-- NOTE: This is additive and idempotent (safe to run multiple times).
-- Do NOT modify already-applied migrations.

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

-- 3) Ensure crm_chats has scheduling + bought-client fields (required by CRM dialogs)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'CrmPostSaleState') THEN
    CREATE TYPE "CrmPostSaleState" AS ENUM (
      'NORMAL',
      'GARANTIA',
      'SOLUCION_GARANTIA',
      'CLIENTE_MOLESTO',
      'VIP'
    );
  END IF;

  IF to_regclass('crm_chats') IS NOT NULL THEN
    ALTER TABLE crm_chats
      ADD COLUMN IF NOT EXISTS scheduled_at timestamptz NULL,
      ADD COLUMN IF NOT EXISTS location_text text NULL,
      ADD COLUMN IF NOT EXISTS lat double precision NULL,
      ADD COLUMN IF NOT EXISTS lng double precision NULL,
      ADD COLUMN IF NOT EXISTS assigned_tech_id uuid NULL,
      ADD COLUMN IF NOT EXISTS service_id uuid NULL,
      ADD COLUMN IF NOT EXISTS purchased_at timestamptz NULL,
      ADD COLUMN IF NOT EXISTS active_client_message_pending boolean NOT NULL DEFAULT false,
      ADD COLUMN IF NOT EXISTS post_sale_state "CrmPostSaleState" NOT NULL DEFAULT 'NORMAL';
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_crm_chats_status ON crm_chats(status);
CREATE INDEX IF NOT EXISTS idx_crm_chats_scheduled_at ON crm_chats(scheduled_at DESC);
CREATE INDEX IF NOT EXISTS idx_crm_chats_assigned_tech_id ON crm_chats(assigned_tech_id);
CREATE INDEX IF NOT EXISTS idx_crm_chats_service_id ON crm_chats(service_id);
CREATE INDEX IF NOT EXISTS idx_crm_chats_active_client_message_pending ON crm_chats(active_client_message_pending);

-- 4) Ensure operations_jobs has CRM linkage + operational metadata
DO $$
BEGIN
  IF to_regclass('operations_jobs') IS NOT NULL THEN
    ALTER TABLE operations_jobs
      ADD COLUMN IF NOT EXISTS crm_chat_id uuid NULL,
      ADD COLUMN IF NOT EXISTS crm_task_type "OperationsCrmTaskType" NULL,
      ADD COLUMN IF NOT EXISTS product_id uuid NULL,
      ADD COLUMN IF NOT EXISTS service_id uuid NULL,
      ADD COLUMN IF NOT EXISTS scheduled_at timestamptz NULL,
      ADD COLUMN IF NOT EXISTS location_text text NULL,
      ADD COLUMN IF NOT EXISTS lat double precision NULL,
      ADD COLUMN IF NOT EXISTS lng double precision NULL,
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

CREATE INDEX IF NOT EXISTS idx_operations_jobs_crm_chat_id ON operations_jobs(crm_chat_id);
CREATE INDEX IF NOT EXISTS idx_operations_jobs_crm_task_type ON operations_jobs(crm_task_type);
CREATE INDEX IF NOT EXISTS idx_operations_jobs_product_id ON operations_jobs(product_id);
CREATE INDEX IF NOT EXISTS idx_operations_jobs_service_id ON operations_jobs(service_id);
CREATE INDEX IF NOT EXISTS idx_operations_jobs_scheduled_at ON operations_jobs(scheduled_at DESC);

-- 5) Ensure operations job history table exists
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

CREATE INDEX IF NOT EXISTS idx_operations_job_history_job_id ON operations_job_history(job_id);
CREATE INDEX IF NOT EXISTS idx_operations_job_history_created_at ON operations_job_history(created_at DESC);
