-- Manual reset for WhatsApp CRM tables (messages/chats/webhook events)
-- Run with psql, NOT through the app migration runner.
-- Example:
--   psql "$DATABASE_URL" -f fulltech_api/sql/manual/reset_crm_whatsapp.sql

BEGIN;

-- Delete in dependency order.
TRUNCATE TABLE
  crm_messages,
  crm_chat_meta,
  crm_chats,
  crm_webhook_events
RESTART IDENTITY;

COMMIT;
