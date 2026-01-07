-- Add empresa_id column to crm_chats table
-- Date: 2026-01-07
-- Purpose: Associate chats with companies to support multi-tenant architecture

-- Step 1: Add the column as nullable first (only if not exists)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_chats' AND column_name = 'empresa_id'
  ) THEN
    ALTER TABLE crm_chats ADD COLUMN empresa_id UUID;
  END IF;
END $$;

-- Step 2: Set default value for existing records (using DEFAULT_EMPRESA_ID from env)
-- Replace with your actual DEFAULT_EMPRESA_ID: 78b649eb-eaca-4e98-8790-0d67fee0cf7a
UPDATE crm_chats 
SET empresa_id = '78b649eb-eaca-4e98-8790-0d67fee0cf7a'
WHERE empresa_id IS NULL;

-- Step 3: Make the column NOT NULL (only if not already)
DO $$
BEGIN
  ALTER TABLE crm_chats ALTER COLUMN empresa_id SET NOT NULL;
EXCEPTION
  WHEN others THEN NULL; -- Column may already be NOT NULL
END $$;

-- Step 4: Add foreign key constraint (only if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'crm_chats_empresa_id_fkey'
  ) THEN
    ALTER TABLE crm_chats 
    ADD CONSTRAINT crm_chats_empresa_id_fkey 
    FOREIGN KEY (empresa_id) 
    REFERENCES "Empresa"(id) 
    ON DELETE CASCADE;
  END IF;
END $$;

-- Step 5: Create index for better query performance
CREATE INDEX IF NOT EXISTS crm_chats_empresa_id_idx ON crm_chats(empresa_id);

-- Verification
SELECT COUNT(*) as total_chats, 
       COUNT(empresa_id) as chats_with_empresa 
FROM crm_chats;
