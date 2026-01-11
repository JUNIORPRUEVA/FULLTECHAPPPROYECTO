-- Carta feature (Presupuesto) - storage + AI structured content + PDF persistence
-- Date: 2026-01-11

BEGIN;

-- 1) Extend company_settings with social links for PDF footer
ALTER TABLE company_settings
  ADD COLUMN IF NOT EXISTS instagram_url text,
  ADD COLUMN IF NOT EXISTS facebook_url text;

-- 2) Extend LetterType enum with new required values
DO $$
BEGIN
  -- Some deployments store letters.letter_type as TEXT (no enum type exists).
  -- Only attempt to alter the enum if it exists.
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'LetterType') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_enum e
      JOIN pg_type t ON t.oid = e.enumtypid
      WHERE t.typname = 'LetterType' AND e.enumlabel = 'COTIZACION_FORMAL'
    ) THEN
      ALTER TYPE "LetterType" ADD VALUE 'COTIZACION_FORMAL';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM pg_enum e
      JOIN pg_type t ON t.oid = e.enumtypid
      WHERE t.typname = 'LetterType' AND e.enumlabel = 'DISCULPA_INCIDENCIA'
    ) THEN
      ALTER TYPE "LetterType" ADD VALUE 'DISCULPA_INCIDENCIA';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM pg_enum e
      JOIN pg_type t ON t.oid = e.enumtypid
      WHERE t.typname = 'LetterType' AND e.enumlabel = 'CONFIRMACION_SERVICIO'
    ) THEN
      ALTER TYPE "LetterType" ADD VALUE 'CONFIRMACION_SERVICIO';
    END IF;
  END IF;
END $$;

-- 3) Extend letters table to behave as "cartas" linked to a Presupuesto
ALTER TABLE IF EXISTS letters
  ADD COLUMN IF NOT EXISTS presupuesto_id uuid,
  ADD COLUMN IF NOT EXISTS cliente_id uuid,
  ADD COLUMN IF NOT EXISTS user_instructions text,
  ADD COLUMN IF NOT EXISTS ai_content_json jsonb,
  ADD COLUMN IF NOT EXISTS pdf_path text;

DO $$
BEGIN
  IF to_regclass('letters') IS NOT NULL THEN
    CREATE INDEX IF NOT EXISTS letters_company_presupuesto_idx ON letters(company_id, presupuesto_id);
    CREATE INDEX IF NOT EXISTS letters_company_cliente_idx ON letters(company_id, cliente_id);
  END IF;
END $$;

COMMIT;
