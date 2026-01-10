-- CRM bought-clients flow + scheduling fields for Operations sync
-- NOTE: Do not modify already-applied migrations. This file is additive.

-- 1) Post-sale state enum for purchased chats
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
END$$;

-- 2) Extend crm_chats with scheduling + bought-client inbox/state fields
DO $$
BEGIN
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

-- 3) Extend operations_jobs to store scheduling/location fields directly
DO $$
BEGIN
  IF to_regclass('operations_jobs') IS NOT NULL THEN
    ALTER TABLE operations_jobs
      ADD COLUMN IF NOT EXISTS scheduled_at timestamptz NULL,
      ADD COLUMN IF NOT EXISTS location_text text NULL,
      ADD COLUMN IF NOT EXISTS lat double precision NULL,
      ADD COLUMN IF NOT EXISTS lng double precision NULL;
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_operations_jobs_scheduled_at ON operations_jobs(scheduled_at DESC);
