-- 2026-01-09
-- Operations jobs: CRM-driven workflow fields + canonical statuses
-- NOTE: additive migration; keeps legacy operations fields.

BEGIN;

-- 1) Extend enum with canonical values (safe if already added)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'OperationsJobStatus') THEN
    BEGIN
      ALTER TYPE "OperationsJobStatus" ADD VALUE IF NOT EXISTS 'POR_LEVANTAMIENTO';
      ALTER TYPE "OperationsJobStatus" ADD VALUE IF NOT EXISTS 'SERVICIO_RESERVADO';
      ALTER TYPE "OperationsJobStatus" ADD VALUE IF NOT EXISTS 'SOLUCION_GARANTIA';
      ALTER TYPE "OperationsJobStatus" ADD VALUE IF NOT EXISTS 'INSTALACION_PENDIENTE';
      ALTER TYPE "OperationsJobStatus" ADD VALUE IF NOT EXISTS 'INSTALACION_FINALIZADA';
      ALTER TYPE "OperationsJobStatus" ADD VALUE IF NOT EXISTS 'RESERVA';
      ALTER TYPE "OperationsJobStatus" ADD VALUE IF NOT EXISTS 'EN_GARANTIA';
    EXCEPTION WHEN duplicate_object THEN
      -- ignore
    END;
  END IF;
END $$;

-- 2) Add new columns (all nullable / additive)
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "chat_id" uuid;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "address_text" text;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "gps_lat" double precision;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "gps_lng" double precision;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "product_id" uuid;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "service_id" uuid;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "vendedor_user_id" uuid;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "technician_user_id" uuid;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "scheduled_at" timestamp with time zone;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "reservation_at" timestamp with time zone;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "warranty_start_date" date;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "warranty_end_date" date;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "warranty_months" integer;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "product_serial" text;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "issue_details" text;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "resolution_due_at" timestamp with time zone;
ALTER TABLE "operations_jobs" ADD COLUMN IF NOT EXISTS "completed_at" timestamp with time zone;

-- 3) Unique single-source-of-truth per chat (allows multiple NULLs)
CREATE UNIQUE INDEX IF NOT EXISTS "operations_jobs_chat_id_unique"
  ON "operations_jobs" ("chat_id")
  WHERE "chat_id" IS NOT NULL;

-- 4) Indexes for operations listing
CREATE INDEX IF NOT EXISTS "operations_jobs_empresa_status_idx" ON "operations_jobs" ("empresa_id", "status");
CREATE INDEX IF NOT EXISTS "operations_jobs_chat_id_idx" ON "operations_jobs" ("chat_id");
CREATE INDEX IF NOT EXISTS "operations_jobs_scheduled_at_idx" ON "operations_jobs" ("scheduled_at");
CREATE INDEX IF NOT EXISTS "operations_jobs_reservation_at_idx" ON "operations_jobs" ("reservation_at");
CREATE INDEX IF NOT EXISTS "operations_jobs_resolution_due_at_idx" ON "operations_jobs" ("resolution_due_at");

-- 5) FK to crm_chats (guarded)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'operations_jobs_chat_id_fkey'
  ) THEN
    ALTER TABLE "operations_jobs"
      ADD CONSTRAINT "operations_jobs_chat_id_fkey"
      FOREIGN KEY ("chat_id") REFERENCES "crm_chats"("id") ON DELETE SET NULL;
  END IF;
END $$;

COMMIT;
