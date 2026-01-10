-- Simplify WhatsApp CRM: inbound media as placeholders, no stored media metadata
-- - Drop media_* columns from crm_messages
-- - Drop lat/lng from crm_chats (keep location_text as plain address)
-- NOTE: Do not modify already-applied migrations. This file is additive.

BEGIN;

-- 1) Messages: remove media storage columns
DO $$
BEGIN
  IF to_regclass('crm_messages') IS NOT NULL THEN
    ALTER TABLE crm_messages
      DROP COLUMN IF EXISTS media_url,
      DROP COLUMN IF EXISTS media_mime,
      DROP COLUMN IF EXISTS media_size,
      DROP COLUMN IF EXISTS media_name;
  END IF;
END $$;

-- 2) Chats: remove coordinates (address remains as text)
DO $$
BEGIN
  IF to_regclass('crm_chats') IS NOT NULL THEN
    ALTER TABLE crm_chats
      DROP COLUMN IF EXISTS lat,
      DROP COLUMN IF EXISTS lng;
  END IF;
END $$;

COMMIT;
