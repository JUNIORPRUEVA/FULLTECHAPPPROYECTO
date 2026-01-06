-- CRM WhatsApp: default status for new chats
-- الهدف: كل chat جديد يدخل "primer_contacto" تلقائياً

BEGIN;

-- 1) Ensure default value is primer_contacto
ALTER TABLE IF EXISTS crm_chats
  ALTER COLUMN status SET DEFAULT 'primer_contacto';

-- 2) Normalize existing rows that are NULL/empty (safe backfill)
UPDATE crm_chats
SET status = 'primer_contacto'
WHERE status IS NULL OR btrim(status) = '';

-- NOTE:
-- If you ALSO want to convert old "activo" chats into "primer_contacto",
-- uncomment the following block.
--
-- UPDATE crm_chats
-- SET status = 'primer_contacto'
-- WHERE status = 'activo';

COMMIT;
