-- Verify CRM schema is correct
-- Date: 2026-01-07
-- Purpose: Check that all CRM tables have the correct structure

-- Check crm_chats table structure
SELECT 
  'crm_chats' as table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'crm_chats'
ORDER BY ordinal_position;

-- Check crm_messages table structure
SELECT 
  'crm_messages' as table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'crm_messages'
ORDER BY ordinal_position;

-- Check for empresa_id in both tables
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name IN ('crm_chats', 'crm_messages')
  AND column_name = 'empresa_id';

-- Check foreign key constraints
SELECT
  tc.table_name, 
  kcu.column_name, 
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN ('crm_chats', 'crm_messages')
ORDER BY tc.table_name;
