-- Adds follow-up flag for WhatsApp CRM chats

ALTER TABLE crm_chat_meta
  ADD COLUMN IF NOT EXISTS follow_up boolean NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS crm_chat_meta_follow_up_idx
  ON crm_chat_meta (follow_up);
