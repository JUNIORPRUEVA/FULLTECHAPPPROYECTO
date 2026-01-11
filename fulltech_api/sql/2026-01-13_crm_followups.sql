-- CRM follow-ups: scheduled messages per chat (text or image).
-- Adds media_url support to crm_messages and creates crm_followup_tasks table.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Re-add media_url to WhatsApp CRM messages for rich media rendering in Flutter.
ALTER TABLE crm_messages
  ADD COLUMN IF NOT EXISTS media_url TEXT;

CREATE INDEX IF NOT EXISTS crm_messages_media_url_idx ON crm_messages(media_url);

-- Scheduled follow-up tasks (per chat).
CREATE TABLE IF NOT EXISTS crm_followup_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES "Empresa"(id) ON DELETE CASCADE,
  chat_id UUID NOT NULL REFERENCES crm_chats(id) ON DELETE CASCADE,
  instancia_id UUID REFERENCES crm_instancias(id) ON DELETE SET NULL,

  run_at timestamptz NOT NULL,
  payload jsonb NOT NULL,
  constraints jsonb NULL,

  created_by_user_id UUID REFERENCES "Usuario"(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),

  processing_at timestamptz NULL,
  processing_by TEXT NULL,

  attempts INT NOT NULL DEFAULT 0,
  last_error TEXT NULL,

  sent_at timestamptz NULL,
  skipped_at timestamptz NULL,
  skip_reason TEXT NULL
);

CREATE INDEX IF NOT EXISTS crm_followup_tasks_empresa_idx ON crm_followup_tasks(empresa_id);
CREATE INDEX IF NOT EXISTS crm_followup_tasks_chat_idx ON crm_followup_tasks(chat_id);
CREATE INDEX IF NOT EXISTS crm_followup_tasks_run_at_idx ON crm_followup_tasks(run_at);
CREATE INDEX IF NOT EXISTS crm_followup_tasks_sent_at_idx ON crm_followup_tasks(sent_at);
CREATE INDEX IF NOT EXISTS crm_followup_tasks_skipped_at_idx ON crm_followup_tasks(skipped_at);
CREATE INDEX IF NOT EXISTS crm_followup_tasks_processing_at_idx ON crm_followup_tasks(processing_at);

COMMIT;

