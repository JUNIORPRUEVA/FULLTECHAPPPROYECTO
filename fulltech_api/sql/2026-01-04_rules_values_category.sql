-- Adds VALUES to the RulesCategory enum (PostgreSQL)
-- Safe to run multiple times.
DO $$
BEGIN
  -- If the enum does not exist (common in DBs bootstrapped via raw SQL), create it.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t WHERE t.typname = 'RulesCategory'
  ) THEN
    CREATE TYPE "RulesCategory" AS ENUM (
      'VISION',
      'MISSION',
      'VALUES',
      'POLICY',
      'ROLE_RESPONSIBILITIES',
      'PROCEDURE',
      'GENERAL'
    );
  END IF;

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
