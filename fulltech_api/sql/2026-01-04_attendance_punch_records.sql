-- Attendance / Ponchado (punch_records)
-- Fecha: 2026-01-04
-- Objetivo: crear en la nube las tablas/tipos necesarios para el módulo de Ponchado.
-- DB: PostgreSQL

BEGIN;

-- UUID generator (used across the project)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Enums (idempotent)
DO $$ BEGIN
  CREATE TYPE "PunchType" AS ENUM ('IN', 'LUNCH_START', 'LUNCH_END', 'OUT');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "SyncStatus" AS ENUM ('PENDING', 'SYNCED', 'FAILED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- updated_at helper (shared)
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Table
CREATE TABLE IF NOT EXISTS punch_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES "Empresa"(id),
  user_id UUID NOT NULL REFERENCES "Usuario"(id),
  type "PunchType" NOT NULL,
  datetime_utc TIMESTAMPTZ NOT NULL,
  datetime_local TEXT NULL,
  timezone TEXT NULL,

  -- Location data
  location_lat DECIMAL(10, 8) NULL,
  location_lng DECIMAL(11, 8) NULL,
  location_accuracy DOUBLE PRECISION NULL,
  location_provider TEXT NULL,
  address_text TEXT NULL,
  location_missing BOOLEAN NOT NULL DEFAULT FALSE,

  -- Device info
  device_id TEXT NULL,
  device_name TEXT NULL,
  platform TEXT NULL,

  -- Metadata
  note TEXT NULL,
  is_manual_edit BOOLEAN NOT NULL DEFAULT FALSE,
  sync_status "SyncStatus" NOT NULL DEFAULT 'SYNCED',

  -- Audit
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ NULL
);

-- Keep updated_at fresh
DROP TRIGGER IF EXISTS trg_punch_records_updated_at ON punch_records;
CREATE TRIGGER trg_punch_records_updated_at
BEFORE UPDATE ON punch_records
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Indexes (matching prisma/schema.prisma)
CREATE INDEX IF NOT EXISTS punch_records_empresa_idx ON punch_records(empresa_id);
CREATE INDEX IF NOT EXISTS punch_records_user_idx ON punch_records(user_id);
CREATE INDEX IF NOT EXISTS punch_records_datetime_utc_idx ON punch_records(datetime_utc DESC);
CREATE INDEX IF NOT EXISTS punch_records_type_idx ON punch_records(type);
CREATE INDEX IF NOT EXISTS punch_records_sync_status_idx ON punch_records(sync_status);
CREATE INDEX IF NOT EXISTS punch_records_deleted_at_idx ON punch_records(deleted_at);

COMMIT;
