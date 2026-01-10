-- CRM integrity hardening: make WA identity and remote message ids unique per empresa.
-- This avoids cross-tenant mixing and matches API expectations.

-- =====================
-- 0) DATA CLEANUP (idempotent-ish)
-- =====================

-- Merge duplicate chats (empresa_id, wa_id) by keeping the most recently updated chat.
WITH ranked AS (
  SELECT
    id,
    empresa_id,
    wa_id,
    FIRST_VALUE(id) OVER (
      PARTITION BY empresa_id, wa_id
      ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST, id DESC
    ) AS keep_id,
    ROW_NUMBER() OVER (
      PARTITION BY empresa_id, wa_id
      ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST, id DESC
    ) AS rn
  FROM crm_chats
),
to_merge AS (
  SELECT id AS drop_id, keep_id
  FROM ranked
  WHERE rn > 1
)
UPDATE crm_messages m
SET chat_id = tm.keep_id
FROM to_merge tm
WHERE m.chat_id = tm.drop_id;

-- Optional table: crm_chat_meta
DO $$
BEGIN
  EXECUTE '
    WITH ranked AS (
      SELECT
        id,
        empresa_id,
        wa_id,
        FIRST_VALUE(id) OVER (
          PARTITION BY empresa_id, wa_id
          ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST, id DESC
        ) AS keep_id,
        ROW_NUMBER() OVER (
          PARTITION BY empresa_id, wa_id
          ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST, id DESC
        ) AS rn
      FROM crm_chats
    ),
    to_merge AS (
      SELECT id AS drop_id, keep_id
      FROM ranked
      WHERE rn > 1
    )
    UPDATE crm_chat_meta m
    SET chat_id = tm.keep_id
    FROM to_merge tm
    WHERE m.chat_id = tm.drop_id
  ';
EXCEPTION WHEN undefined_table THEN
  -- ignore
END $$;

-- Delete the duplicate chat rows after reassignment.
WITH ranked AS (
  SELECT
    id,
    empresa_id,
    wa_id,
    ROW_NUMBER() OVER (
      PARTITION BY empresa_id, wa_id
      ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST, id DESC
    ) AS rn
  FROM crm_chats
)
DELETE FROM crm_chats c
USING ranked r
WHERE c.id = r.id AND r.rn > 1;

-- Drop duplicate remote_message_id rows (empresa_id, remote_message_id) keeping the earliest created.
WITH ranked AS (
  SELECT
    id,
    empresa_id,
    remote_message_id,
    ROW_NUMBER() OVER (
      PARTITION BY empresa_id, remote_message_id
      ORDER BY created_at ASC NULLS LAST, id ASC
    ) AS rn
  FROM crm_messages
  WHERE remote_message_id IS NOT NULL
)
DELETE FROM crm_messages m
USING ranked r
WHERE m.id = r.id AND r.rn > 1;

-- Chats: replace UNIQUE(wa_id) with UNIQUE(empresa_id, wa_id)
ALTER TABLE crm_chats
  DROP CONSTRAINT IF EXISTS crm_chats_wa_id_key;

DROP INDEX IF EXISTS crm_chats_wa_id_key;

ALTER TABLE crm_chats
  ADD CONSTRAINT crm_chats_empresa_id_wa_id_key UNIQUE (empresa_id, wa_id);

-- Messages: replace UNIQUE(remote_message_id) with UNIQUE(empresa_id, remote_message_id)
ALTER TABLE crm_messages
  DROP CONSTRAINT IF EXISTS crm_messages_remote_message_id_key;

DROP INDEX IF EXISTS crm_messages_remote_message_id_key;

ALTER TABLE crm_messages
  ADD CONSTRAINT crm_messages_empresa_id_remote_message_id_key UNIQUE (empresa_id, remote_message_id);
