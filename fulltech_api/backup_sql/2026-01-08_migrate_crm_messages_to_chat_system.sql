-- Update crm_messages table to use chat_id instead of thread_id
-- Date: 2026-01-08
-- Purpose: Align crm_messages table with new CRM chat system

BEGIN;

-- Step 1: Check if we need to migrate from thread_id to chat_id
DO $$ 
BEGIN
  -- If thread_id column exists but chat_id doesn't, we need to rename
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'thread_id'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'chat_id'
  ) THEN
    -- Rename thread_id to chat_id
    ALTER TABLE crm_messages RENAME COLUMN thread_id TO chat_id;
    RAISE NOTICE 'Renamed thread_id to chat_id in crm_messages';
    
    -- Update foreign key constraint
    ALTER TABLE crm_messages DROP CONSTRAINT IF EXISTS crm_messages_thread_id_fkey;
    ALTER TABLE crm_messages 
      ADD CONSTRAINT crm_messages_chat_id_fkey 
      FOREIGN KEY (chat_id) 
      REFERENCES crm_chats(id) 
      ON DELETE CASCADE;
    RAISE NOTICE 'Updated foreign key constraint to use chat_id';
  ELSE
    RAISE NOTICE 'Column chat_id already exists or thread_id does not exist';
  END IF;
END $$;

-- Step 2: Rename other columns to match new schema
DO $$
BEGIN
  -- Rename message_id to remote_message_id if needed
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'message_id'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'remote_message_id'
  ) THEN
    ALTER TABLE crm_messages RENAME COLUMN message_id TO remote_message_id;
    RAISE NOTICE 'Renamed message_id to remote_message_id';
  END IF;

  -- Rename from_me to direction if needed
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'from_me'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'direction'
  ) THEN
    -- Add direction column
    ALTER TABLE crm_messages ADD COLUMN direction TEXT;
    
    -- Migrate data: from_me=true -> 'out', from_me=false -> 'in'
    UPDATE crm_messages SET direction = CASE WHEN from_me THEN 'out' ELSE 'in' END;
    
    -- Make it NOT NULL
    ALTER TABLE crm_messages ALTER COLUMN direction SET NOT NULL;
    
    -- Drop old column
    ALTER TABLE crm_messages DROP COLUMN from_me;
    
    RAISE NOTICE 'Migrated from_me to direction';
  END IF;

  -- Rename type to message_type if needed
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'type'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'message_type'
  ) THEN
    ALTER TABLE crm_messages RENAME COLUMN type TO message_type;
    RAISE NOTICE 'Renamed type to message_type';
  END IF;

  -- Rename body to text if needed
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'body'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'text'
  ) THEN
    ALTER TABLE crm_messages RENAME COLUMN body TO text;
    RAISE NOTICE 'Renamed body to text';
  END IF;
END $$;

-- Step 3: Add new columns if they don't exist
ALTER TABLE crm_messages ADD COLUMN IF NOT EXISTS media_mime TEXT;
ALTER TABLE crm_messages ADD COLUMN IF NOT EXISTS media_size INTEGER;
ALTER TABLE crm_messages ADD COLUMN IF NOT EXISTS media_name TEXT;
ALTER TABLE crm_messages ADD COLUMN IF NOT EXISTS quoted_message_id TEXT;
ALTER TABLE crm_messages ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'received';
ALTER TABLE crm_messages ADD COLUMN IF NOT EXISTS error TEXT;
ALTER TABLE crm_messages ADD COLUMN IF NOT EXISTS timestamp TIMESTAMPTZ;

-- Step 4: Migrate timestamp if needed
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'created_at'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' AND column_name = 'timestamp'
  ) THEN
    -- Copy created_at to timestamp where timestamp is null
    UPDATE crm_messages SET timestamp = created_at WHERE timestamp IS NULL;
    RAISE NOTICE 'Migrated created_at to timestamp';
  END IF;
END $$;

-- Step 5: Make timestamp NOT NULL if it has data
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'crm_messages' 
      AND column_name = 'timestamp'
      AND is_nullable = 'YES'
  ) THEN
    -- Set default for NULL values
    UPDATE crm_messages SET timestamp = created_at WHERE timestamp IS NULL;
    
    -- Make it NOT NULL
    ALTER TABLE crm_messages ALTER COLUMN timestamp SET NOT NULL;
    RAISE NOTICE 'Made timestamp NOT NULL';
  END IF;
END $$;

-- Step 6: Update unique constraint on remote_message_id
DROP INDEX IF EXISTS crm_messages_message_id_uniq;
CREATE UNIQUE INDEX IF NOT EXISTS crm_messages_remote_message_id_key 
  ON crm_messages(remote_message_id) 
  WHERE remote_message_id IS NOT NULL;

-- Step 7: Update indexes
DROP INDEX IF EXISTS crm_messages_thread_created_idx;
CREATE INDEX IF NOT EXISTS crm_messages_chat_id_timestamp_idx 
  ON crm_messages(chat_id, timestamp DESC);

CREATE INDEX IF NOT EXISTS crm_messages_empresa_id_idx 
  ON crm_messages(empresa_id);

-- Verification
SELECT 
  COUNT(*) as total_messages,
  COUNT(empresa_id) as with_empresa_id,
  COUNT(chat_id) as with_chat_id,
  COUNT(direction) as with_direction,
  COUNT(message_type) as with_message_type,
  COUNT(timestamp) as with_timestamp
FROM crm_messages;

COMMIT;
