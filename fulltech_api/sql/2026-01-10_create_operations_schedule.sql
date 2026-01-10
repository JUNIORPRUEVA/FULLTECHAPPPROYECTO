-- Create operations_schedule table (required by CRM -> Operations sync).
-- This prevents 500 errors when CRM status changes try to upsert schedule data.

CREATE TABLE IF NOT EXISTS operations_schedule (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid UNIQUE NOT NULL,
  scheduled_date date NOT NULL,
  preferred_time text,
  assigned_tech_id uuid NULL,
  additional_tech_ids text[] NOT NULL DEFAULT '{}'::text[],
  customer_availability_notes text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_name = 'operations_schedule_job_id_fkey'
  ) THEN
    ALTER TABLE operations_schedule
      ADD CONSTRAINT operations_schedule_job_id_fkey
      FOREIGN KEY (job_id) REFERENCES operations_jobs(id)
      ON DELETE CASCADE;
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_name = 'operations_schedule_assigned_tech_id_fkey'
  ) THEN
    ALTER TABLE operations_schedule
      ADD CONSTRAINT operations_schedule_assigned_tech_id_fkey
      FOREIGN KEY (assigned_tech_id) REFERENCES "Usuario"(id)
      ON DELETE SET NULL;
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_operations_schedule_job_id
  ON operations_schedule(job_id);
CREATE INDEX IF NOT EXISTS idx_operations_schedule_scheduled_date
  ON operations_schedule(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_operations_schedule_assigned_tech_id
  ON operations_schedule(assigned_tech_id);

CREATE OR REPLACE FUNCTION update_operations_schedule_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'operations_schedule_updated_at_trigger'
  ) THEN
    CREATE TRIGGER operations_schedule_updated_at_trigger
    BEFORE UPDATE ON operations_schedule
    FOR EACH ROW
    EXECUTE FUNCTION update_operations_schedule_updated_at();
  END IF;
END$$;

