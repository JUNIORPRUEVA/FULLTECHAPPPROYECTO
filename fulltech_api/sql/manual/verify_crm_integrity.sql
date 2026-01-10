-- CRM Integrity Verification Queries
-- All of these should return 0 rows in a healthy database.

-- 1) Duplicate chats per empresa + wa_id
SELECT empresa_id, wa_id, COUNT(*) AS cnt
FROM crm_chats
GROUP BY empresa_id, wa_id
HAVING COUNT(*) > 1;

-- 2) Duplicate remote_message_id per empresa (ignore NULLs)
SELECT empresa_id, remote_message_id, COUNT(*) AS cnt
FROM crm_messages
WHERE remote_message_id IS NOT NULL
GROUP BY empresa_id, remote_message_id
HAVING COUNT(*) > 1;

-- 3) Messages referencing missing chats
SELECT m.id, m.chat_id
FROM crm_messages m
LEFT JOIN crm_chats c ON c.id = m.chat_id
WHERE c.id IS NULL;

-- 4) Messages whose empresa_id doesn't match the chat's empresa_id
SELECT m.id, m.chat_id, m.empresa_id AS msg_empresa_id, c.empresa_id AS chat_empresa_id
FROM crm_messages m
JOIN crm_chats c ON c.id = m.chat_id
WHERE m.empresa_id <> c.empresa_id;

-- 5) Chats with phone that doesn't match wa_id digits
SELECT id, empresa_id, wa_id, phone
FROM crm_chats
WHERE phone IS NOT NULL
  AND regexp_replace(wa_id, '\\D', '', 'g') <> regexp_replace(phone, '\\D', '', 'g');
