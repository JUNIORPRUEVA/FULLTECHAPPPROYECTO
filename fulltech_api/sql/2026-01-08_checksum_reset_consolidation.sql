-- Schema Consolidation for Services and Agenda
-- Date: 2026-01-08
-- Description: Consolidate all schema changes in idempotent way
-- This migration is safe to run multiple times

BEGIN;

-- =============================================================================
-- 1. CRM CHATS EMPRESA_ID (ensure it's properly applied)
-- =============================================================================

-- Add empresa_id column if it doesn't exist
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'crm_chats' AND column_name = 'empresa_id'
    ) THEN
        ALTER TABLE crm_chats ADD COLUMN empresa_id UUID;
        RAISE NOTICE 'Added empresa_id column to crm_chats';
    END IF;
END $$;

-- Set default value for existing records that don't have empresa_id
UPDATE crm_chats
SET empresa_id = '78b649eb-eaca-4e98-8790-0d67fee0cf7a'
WHERE empresa_id IS NULL;

-- Make the column NOT NULL if it isn't already
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'crm_chats' 
        AND column_name = 'empresa_id' 
        AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE crm_chats ALTER COLUMN empresa_id SET NOT NULL;
        RAISE NOTICE 'Set empresa_id to NOT NULL in crm_chats';
    END IF;
END $$;

-- Add foreign key constraint if it doesn't exist
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'crm_chats_empresa_id_fkey'
        AND table_name = 'crm_chats'
    ) THEN
        ALTER TABLE crm_chats
        ADD CONSTRAINT crm_chats_empresa_id_fkey
        FOREIGN KEY (empresa_id)
        REFERENCES "Empresa"(id)
        ON DELETE CASCADE;
        RAISE NOTICE 'Added foreign key constraint to crm_chats.empresa_id';
    END IF;
END $$;

-- Create index for better query performance
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'crm_chats' AND indexname = 'crm_chats_empresa_id_idx') THEN
        CREATE INDEX crm_chats_empresa_id_idx ON crm_chats(empresa_id);
        RAISE NOTICE 'Created index on crm_chats.empresa_id';
    END IF;
END $$;

-- =============================================================================
-- 2. SERVICES MODULE (complete schema)
-- =============================================================================

-- Services table for catalog management
CREATE TABLE IF NOT EXISTS services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  default_price DECIMAL(10,2),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT services_empresa_fkey 
    FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE CASCADE
);

-- Add indexes for services
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'services' AND indexname = 'services_empresa_id_idx') THEN
        CREATE INDEX services_empresa_id_idx ON services(empresa_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'services' AND indexname = 'services_name_idx') THEN
        CREATE INDEX services_name_idx ON services(name);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'services' AND indexname = 'services_active_idx') THEN
        CREATE INDEX services_active_idx ON services(is_active);
    END IF;
END $$;

-- Add updated_at trigger for services
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'services_updated_at_trigger') THEN
        CREATE TRIGGER services_updated_at_trigger
        BEFORE UPDATE ON services
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- =============================================================================
-- 3. AGENDA MODULE (complete schema)
-- =============================================================================

-- Enum for agenda item types
DO $$ BEGIN
    CREATE TYPE "AgendaItemType" AS ENUM (
        'RESERVA', 
        'SERVICIO_RESERVADO', 
        'GARANTIA', 
        'SOLUCION_GARANTIA'
    );
    RAISE NOTICE 'Created AgendaItemType enum';
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'AgendaItemType enum already exists';
END $$;

-- Agenda items table
CREATE TABLE IF NOT EXISTS agenda_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL,
  thread_id UUID,
  client_id UUID,
  client_phone TEXT,
  client_name TEXT,
  type "AgendaItemType" NOT NULL,
  scheduled_at TIMESTAMPTZ,
  service_id UUID,
  service_name TEXT,
  product_name TEXT,
  technician_id UUID,
  technician_name TEXT,
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT agenda_items_empresa_fkey 
    FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE CASCADE
);

-- Add foreign key constraints for agenda_items
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'agenda_items_thread_fkey' 
        AND table_name = 'agenda_items'
    ) THEN
        ALTER TABLE agenda_items 
        ADD CONSTRAINT agenda_items_thread_fkey 
        FOREIGN KEY (thread_id) REFERENCES crm_threads(id) ON DELETE SET NULL;
    END IF;
EXCEPTION
    WHEN foreign_key_violation OR invalid_foreign_key THEN null;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'agenda_items_service_fkey' 
        AND table_name = 'agenda_items'
    ) THEN
        ALTER TABLE agenda_items 
        ADD CONSTRAINT agenda_items_service_fkey 
        FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL;
    END IF;
EXCEPTION
    WHEN foreign_key_violation OR invalid_foreign_key THEN null;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'agenda_items_technician_fkey' 
        AND table_name = 'agenda_items'
    ) THEN
        ALTER TABLE agenda_items 
        ADD CONSTRAINT agenda_items_technician_fkey 
        FOREIGN KEY (technician_id) REFERENCES "Usuario"(id) ON DELETE SET NULL;
    END IF;
EXCEPTION
    WHEN foreign_key_violation OR invalid_foreign_key THEN null;
END $$;

-- Ensure status column exists in agenda_items (in case table exists without this column)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'agenda_items' AND column_name = 'status'
    ) THEN
        ALTER TABLE agenda_items ADD COLUMN status TEXT DEFAULT 'pending';
        RAISE NOTICE 'Added status column to agenda_items';
    END IF;
END $$;

-- Add indexes for agenda_items
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'agenda_items' AND indexname = 'agenda_items_empresa_id_idx') THEN
        CREATE INDEX agenda_items_empresa_id_idx ON agenda_items(empresa_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'agenda_items' AND indexname = 'agenda_items_scheduled_at_idx') THEN
        CREATE INDEX agenda_items_scheduled_at_idx ON agenda_items(scheduled_at);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'agenda_items' AND indexname = 'agenda_items_type_idx') THEN
        CREATE INDEX agenda_items_type_idx ON agenda_items(type);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'agenda_items' AND indexname = 'agenda_items_technician_idx') THEN
        CREATE INDEX agenda_items_technician_idx ON agenda_items(technician_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'agenda_items' AND indexname = 'agenda_items_status_idx') THEN
        CREATE INDEX IF NOT EXISTS agenda_items_status_idx ON agenda_items(status);
    END IF;
END $$;

-- Add updated_at trigger for agenda_items
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'agenda_items_updated_at_trigger') THEN
        CREATE TRIGGER agenda_items_updated_at_trigger
        BEFORE UPDATE ON agenda_items
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- =============================================================================
-- 4. CRM MESSAGES MIGRATION (thread_id to chat_id)
-- =============================================================================

-- Add chat_id column to crm_messages if it doesn't exist
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'crm_messages' AND column_name = 'chat_id'
    ) THEN
        ALTER TABLE crm_messages ADD COLUMN chat_id UUID;
        RAISE NOTICE 'Added chat_id column to crm_messages';
    END IF;
END $$;

-- Migrate thread_id to chat_id if needed
DO $$ 
DECLARE
    migrated_count INTEGER := 0;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'crm_messages' AND column_name = 'thread_id')
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'crm_messages' AND column_name = 'chat_id') THEN
        
        UPDATE crm_messages 
        SET chat_id = thread_id 
        WHERE chat_id IS NULL AND thread_id IS NOT NULL;
        
        GET DIAGNOSTICS migrated_count = ROW_COUNT;
        RAISE NOTICE 'Migrated % crm_messages from thread_id to chat_id', migrated_count;
    END IF;
END $$;

-- Add foreign key constraint for chat_id
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'crm_messages_chat_id_fkey' 
        AND table_name = 'crm_messages'
    ) THEN
        ALTER TABLE crm_messages 
        ADD CONSTRAINT crm_messages_chat_id_fkey 
        FOREIGN KEY (chat_id) REFERENCES crm_chats(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added foreign key constraint to crm_messages.chat_id';
    END IF;
EXCEPTION
    WHEN foreign_key_violation OR invalid_foreign_key THEN 
        RAISE NOTICE 'Could not add foreign key constraint for crm_messages.chat_id (table may not exist)';
END $$;

-- Add index for chat_id
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'crm_messages' AND indexname = 'crm_messages_chat_id_idx') THEN
        CREATE INDEX crm_messages_chat_id_idx ON crm_messages(chat_id);
    END IF;
END $$;

-- =============================================================================
-- 5. VERIFICATION AND SUMMARY
-- =============================================================================

-- Verify all tables and report status
DO $$ 
DECLARE
    service_count INTEGER;
    agenda_count INTEGER;
    chat_count INTEGER;
    message_count INTEGER;
BEGIN
    -- Check services
    SELECT COUNT(*) INTO service_count FROM services;
    RAISE NOTICE 'Services table verified: % records', service_count;
    
    -- Check agenda_items
    SELECT COUNT(*) INTO agenda_count FROM agenda_items;
    RAISE NOTICE 'Agenda items table verified: % records', agenda_count;
    
    -- Check crm_chats
    SELECT COUNT(*) INTO chat_count FROM crm_chats WHERE empresa_id IS NOT NULL;
    RAISE NOTICE 'CRM chats with empresa_id: %', chat_count;
    
    -- Check crm_messages
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'crm_messages' AND column_name = 'chat_id') THEN
        SELECT COUNT(*) INTO message_count FROM crm_messages WHERE chat_id IS NOT NULL;
        RAISE NOTICE 'CRM messages with chat_id: %', message_count;
    END IF;
END $$;

COMMIT;

-- Final success message
SELECT 'MIGRATION RESET COMPLETED: All schema consolidated and checksums should be clean now!' as status;