-- Operations jobs: CRM-driven workflow fields + canonical statuses
-- Date: 2026-01-09
-- This migration is idempotent and safe to run multiple times.

BEGIN;

-- 1) Extend enum with canonical values (safe if already added)
DO $$
DECLARE
  enum_name text;
  val text;
  vals text[] := ARRAY[
    'POR_LEVANTAMIENTO',
    'SERVICIO_RESERVADO',
    'SOLUCION_GARANTIA',
    'INSTALACION_PENDIENTE',
    'INSTALACION_FINALIZADA',
    'RESERVA',
    'EN_GARANTIA'
  ];
BEGIN
  -- The enum might exist as quoted or unquoted; check both.
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'OperationsJobStatus') THEN
    enum_name := '"OperationsJobStatus"';
  ELSIF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'operationsjobstatus') THEN
    enum_name := 'operationsjobstatus';
  ELSE
    enum_name := NULL;
  END IF;

  IF enum_name IS NOT NULL THEN
    FOREACH val IN ARRAY vals LOOP
      IF NOT EXISTS (
        SELECT 1
        FROM pg_enum e
        JOIN pg_type t ON t.oid = e.enumtypid
        WHERE (t.typname = 'OperationsJobStatus' OR t.typname = 'operationsjobstatus')
          AND e.enumlabel = val
      ) THEN
        EXECUTE 'ALTER TYPE ' || enum_name || ' ADD VALUE ' || quote_literal(val);
      END IF;
    END LOOP;
  END IF;
END $$;

-- 2) Add new columns + indexes + FK only if operations_jobs exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'operations_jobs'
  ) THEN
    -- Add new columns (nullable / additive)
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS chat_id uuid';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS address_text text';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS gps_lat double precision';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS gps_lng double precision';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS product_id uuid';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS service_id uuid';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS vendedor_user_id uuid';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS technician_user_id uuid';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS scheduled_at timestamptz';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS reservation_at timestamptz';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS warranty_start_date date';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS warranty_end_date date';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS warranty_months integer';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS product_serial text';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS issue_details text';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS resolution_due_at timestamptz';
    EXECUTE 'ALTER TABLE operations_jobs ADD COLUMN IF NOT EXISTS completed_at timestamptz';

    -- Unique single-source-of-truth per chat (allows multiple NULLs)
    EXECUTE 'CREATE UNIQUE INDEX IF NOT EXISTS operations_jobs_chat_id_unique ON operations_jobs (chat_id) WHERE chat_id IS NOT NULL';

    -- Indexes for operations listing
    EXECUTE 'CREATE INDEX IF NOT EXISTS operations_jobs_empresa_status_idx ON operations_jobs (empresa_id, status)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS operations_jobs_chat_id_idx ON operations_jobs (chat_id)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS operations_jobs_scheduled_at_idx ON operations_jobs (scheduled_at)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS operations_jobs_reservation_at_idx ON operations_jobs (reservation_at)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS operations_jobs_resolution_due_at_idx ON operations_jobs (resolution_due_at)';

    -- FK to crm_chats (guarded)
    IF EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = 'crm_chats'
    ) THEN
      IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'operations_jobs_chat_id_fkey'
      ) THEN
        BEGIN
          EXECUTE 'ALTER TABLE operations_jobs ADD CONSTRAINT operations_jobs_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES crm_chats(id) ON DELETE SET NULL';
        EXCEPTION WHEN others THEN
          -- Ignore if constraint can't be created due to legacy schema differences
          NULL;
        END;
      END IF;
    END IF;
  ELSE
    RAISE NOTICE 'operations_jobs table not found; skipping operations CRM workflow migration.';
  END IF;
END $$;

COMMIT;
