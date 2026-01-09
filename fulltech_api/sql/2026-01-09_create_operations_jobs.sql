-- Create operations_jobs base table (if missing)
-- Date: 2026-01-09
-- Safe/idempotent: creates enums, table, and indexes if not present.

BEGIN;

-- UUID helpers (safe if already installed)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enums
DO $$
BEGIN
  CREATE TYPE "OperationsJobPriority" AS ENUM ('low','normal','high');
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE "OperationsJobStatus" AS ENUM (
    'POR_LEVANTAMIENTO',
    'SERVICIO_RESERVADO',
    'SOLUCION_GARANTIA',
    'INSTALACION_PENDIENTE',
    'INSTALACION_FINALIZADA',
    'RESERVA',
    'EN_GARANTIA',
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
    'cancelled'
  );
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

-- Base table (includes CRM workflow fields)
CREATE TABLE IF NOT EXISTS operations_jobs (
  id uuid PRIMARY KEY DEFAULT COALESCE(gen_random_uuid(), uuid_generate_v4()),
  empresa_id uuid NOT NULL,
  created_by_user_id uuid NOT NULL,
  assigned_tech_id uuid,
  assigned_team_ids text[] NOT NULL DEFAULT '{}',

  chat_id uuid,

  customer_name text NOT NULL,
  customer_phone text NOT NULL,
  customer_address text,
  address_text text,
  gps_lat double precision,
  gps_lng double precision,

  crm_customer_id uuid NOT NULL,
  service_type text NOT NULL,

  product_id uuid,
  service_id uuid,
  vendedor_user_id uuid,
  technician_user_id uuid,

  scheduled_at timestamptz,
  reservation_at timestamptz,

  warranty_start_date date,
  warranty_end_date date,
  warranty_months integer,
  product_serial text,
  issue_details text,

  resolution_due_at timestamptz,
  completed_at timestamptz,

  priority "OperationsJobPriority" NOT NULL DEFAULT 'normal',
  status "OperationsJobStatus" NOT NULL DEFAULT 'pending_survey',
  notes text,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Unique single-source-of-truth per chat (allows multiple NULLs)
CREATE UNIQUE INDEX IF NOT EXISTS operations_jobs_chat_id_unique
  ON operations_jobs (chat_id)
  WHERE chat_id IS NOT NULL;

-- Indexes
CREATE INDEX IF NOT EXISTS operations_jobs_empresa_id_idx ON operations_jobs (empresa_id);
CREATE INDEX IF NOT EXISTS operations_jobs_empresa_status_idx ON operations_jobs (empresa_id, status);
CREATE INDEX IF NOT EXISTS operations_jobs_crm_customer_id_idx ON operations_jobs (crm_customer_id);
CREATE INDEX IF NOT EXISTS operations_jobs_chat_id_idx ON operations_jobs (chat_id);
CREATE INDEX IF NOT EXISTS operations_jobs_scheduled_at_idx ON operations_jobs (scheduled_at);
CREATE INDEX IF NOT EXISTS operations_jobs_reservation_at_idx ON operations_jobs (reservation_at);
CREATE INDEX IF NOT EXISTS operations_jobs_resolution_due_at_idx ON operations_jobs (resolution_due_at);
CREATE INDEX IF NOT EXISTS operations_jobs_status_idx ON operations_jobs (status);
CREATE INDEX IF NOT EXISTS operations_jobs_priority_idx ON operations_jobs (priority);
CREATE INDEX IF NOT EXISTS operations_jobs_assigned_tech_id_idx ON operations_jobs (assigned_tech_id);
CREATE INDEX IF NOT EXISTS operations_jobs_created_at_desc_idx ON operations_jobs (created_at DESC);
CREATE INDEX IF NOT EXISTS operations_jobs_deleted_at_idx ON operations_jobs (deleted_at);

-- FK constraints (guarded; won't fail if referenced tables differ)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='crm_chats') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'operations_jobs_chat_id_fkey') THEN
      BEGIN
        ALTER TABLE operations_jobs
          ADD CONSTRAINT operations_jobs_chat_id_fkey
          FOREIGN KEY (chat_id) REFERENCES crm_chats(id) ON DELETE SET NULL;
      EXCEPTION WHEN others THEN
        NULL;
      END;
    END IF;
  END IF;
END $$;

COMMIT;
