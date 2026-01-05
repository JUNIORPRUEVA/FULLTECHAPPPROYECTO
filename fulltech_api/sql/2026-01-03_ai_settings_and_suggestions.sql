-- AI Settings + Suggestions + Audits

-- Settings (single row id=1)
CREATE TABLE IF NOT EXISTS ai_settings (
  id INT PRIMARY KEY,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  quick_replies_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  system_prompt TEXT,
  tone TEXT,
  rules TEXT,
  business_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  prompt_version INT NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO ai_settings (id)
VALUES (1)
ON CONFLICT (id) DO NOTHING;

-- Suggestions (one row per suggestion id)
CREATE TABLE IF NOT EXISTS ai_suggestions (
  id UUID PRIMARY KEY,
  chat_id UUID NULL,
  last_customer_message_id UUID NULL,
  customer_text TEXT NOT NULL,
  suggestion_text TEXT NOT NULL,
  used_knowledge JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Audit: what got sent (after edit) and which suggestion was used
CREATE TABLE IF NOT EXISTS ai_message_audits (
  id UUID PRIMARY KEY,
  chat_id UUID NOT NULL,
  message_id UUID NOT NULL,
  suggestion_id UUID NULL,
  suggested_text TEXT NULL,
  final_text TEXT NOT NULL,
  used_knowledge JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_suggestions_chat_id ON ai_suggestions(chat_id);
CREATE INDEX IF NOT EXISTS idx_ai_message_audits_chat_id ON ai_message_audits(chat_id);

-- Extend existing quick replies with keywords for intent matching
ALTER TABLE quick_replies
  ADD COLUMN IF NOT EXISTS keywords TEXT;

ALTER TABLE quick_replies
  ADD COLUMN IF NOT EXISTS allow_comment BOOLEAN NOT NULL DEFAULT TRUE;
