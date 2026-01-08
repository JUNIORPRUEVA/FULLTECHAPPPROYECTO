-- Add empresa_id column to crm_messages table
-- Date: 2026-01-07
-- Purpose: Associate messages with companies to support multi-tenant architecture

BEGIN;

-- Step 1: Add the column as nullable first (only if not exists)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'empresa_id'
  ) THEN
    ALTER TABLE crm_messages ADD COLUMN empresa_id UUID;
    RAISE NOTICE 'Column empresa_id added to crm_messages';
  ELSE
    RAISE NOTICE 'Column empresa_id already exists in crm_messages';
  END IF;
END $$;

-- Step 2: Set empresa_id from the related chat for existing messages
UPDATE crm_messages cm
SET empresa_id = cc.empresa_id
FROM crm_chats cc
WHERE cm.chat_id = cc.id
  AND cm.empresa_id IS NULL;

-- Step 3: Set default value for any remaining NULL records (using DEFAULT_EMPRESA_ID)
-- Replace with your actual DEFAULT_EMPRESA_ID: 78b649eb-eaca-4e98-8790-0d67fee0cf7a
UPDATE crm_messages 
SET empresa_id = '78b649eb-eaca-4e98-8790-0d67fee0cf7a'
WHERE empresa_id IS NULL;

-- Step 4: Make the column NOT NULL
DO $$
BEGIN
  ALTER TABLE crm_messages ALTER COLUMN empresa_id SET NOT NULL;
  RAISE NOTICE 'Column empresa_id set to NOT NULL';
EXCEPTION
  WHEN others THEN 
    RAISE NOTICE 'Column empresa_id already NOT NULL or error: %', SQLERRM;
END $$;

-- Step 5: Add foreign key constraint (only if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'crm_messages_empresa_id_fkey'
  ) THEN
    ALTER TABLE crm_messages 
    ADD CONSTRAINT crm_messages_empresa_id_fkey 
    FOREIGN KEY (empresa_id) 
    REFERENCES "Empresa"(id) 
    ON DELETE CASCADE;
    RAISE NOTICE 'Foreign key constraint crm_messages_empresa_id_fkey added';
  ELSE
    RAISE NOTICE 'Foreign key constraint crm_messages_empresa_id_fkey already exists';
  END IF;
END $$;

-- Step 6: Create index for better query performance
CREATE INDEX IF NOT EXISTS crm_messages_empresa_id_idx ON crm_messages(empresa_id);

-- Verification
SELECT 
  COUNT(*) as total_messages, 
  COUNT(empresa_id) as messages_with_empresa,
  COUNT(*) - COUNT(empresa_id) as messages_without_empresa
FROM crm_messages;

COMMIT;
