-- Adds VALUES to the RulesCategory enum (PostgreSQL)
-- Safe to run multiple times.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'RulesCategory'
      AND e.enumlabel = 'VALUES'
  ) THEN
    ALTER TYPE "RulesCategory" ADD VALUE 'VALUES';
  END IF;
END
$$;
