-- Migration: Add Multi-Instance Support to CRM
-- Date: 2026-01-10
-- Description: Enables per-user Evolution API instances with complete data isolation

/*
  DEPRECATED / DO NOT RUN
  ----------------------
  This file is a stale duplicate kept under sql/migrations/.
  The migration runner executes files in sql/ (non-recursive).
  Use: sql/2026-01-10_add_crm_multi_instance.sql
*/

/*

BEGIN;

-- =====================================================
-- 1) CREATE crm_instancias TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS crm_instancias (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  nombre_instancia TEXT NOT NULL,
  evolution_base_url TEXT NOT NULL,
  evolution_api_key TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP(3) NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP(3) NOT NULL DEFAULT NOW()
);

-- Unique constraint: one active instance per user
CREATE UNIQUE INDEX crm_instancias_user_active_idx 
  ON crm_instancias(user_id, is_active) 
  WHERE is_active = TRUE;

-- Index for lookups by instance name
CREATE INDEX crm_instancias_nombre_idx ON crm_instancias(nombre_instancia);

-- Index for empresa queries
CREATE INDEX crm_instancias_empresa_idx ON crm_instancias(empresa_id);

COMMENT ON COLUMN crm_instancias.nombre_instancia IS 'Evolution instance name (e.g., "junior01")';
COMMENT ON COLUMN crm_instancias.is_active IS 'Only one active instance per user allowed';

-- =====================================================
-- =====================================================

ALTER TABLE crm_chats 
  ADD COLUMN IF NOT EXISTS instancia_id UUID REFERENCES crm_instancias(id) ON DELETE SET NULL;

-- Add owner_user_id for quick filtering
ALTER TABLE crm_chats 
  ADD COLUMN IF NOT EXISTS owner_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
  ADD COLUMN IF NOT EXISTS asignado_a_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
-- Create indexes
CREATE INDEX IF NOT EXISTS crm_chats_instancia_idx ON crm_chats(instancia_id);
CREATE INDEX IF NOT EXISTS crm_chats_owner_user_idx ON crm_chats(owner_user_id);

-- Update unique constraint to include instancia_id
-- Drop old unique constraint and create new one
CREATE UNIQUE INDEX IF NOT EXISTS crm_chats_instancia_wa_id_unique 
  ON crm_chats(instancia_id, wa_id) 
  WHERE instancia_id IS NOT NULL;
COMMENT ON COLUMN crm_chats.instancia_id IS 'Instance that owns/manages this chat';
COMMENT ON COLUMN crm_chats.owner_user_id IS 'Original owner of the chat (for filtering)';
COMMENT ON COLUMN crm_chats.asignado_a_user_id IS 'Current user assigned to handle this chat';

-- =====================================================

-- Add instancia_id for fast queries and auditing
ALTER TABLE crm_messages 
  ADD COLUMN IF NOT EXISTS instancia_id UUID REFERENCES crm_instancias(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS crm_messages_instancia_idx ON crm_messages(instancia_id);

COMMENT ON COLUMN crm_messages.instancia_id IS 'Instance that handled this message (for audit/queries)';
-- =====================================================

CREATE TABLE IF NOT EXISTS crm_chat_transfer_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID REFERENCES "Usuario"(id) ON DELETE SET NULL,
  to_user_id UUID NOT NULL REFERENCES "Usuario"(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  from_instancia_id UUID REFERENCES crm_instancias(id) ON DELETE SET NULL,
  to_instancia_id UUID NOT NULL REFERENCES crm_instancias(id) ON DELETE CASCADE,
  notes TEXT,
  created_at TIMESTAMP(3) NOT NULL DEFAULT NOW()
);
CREATE INDEX crm_chat_transfer_events_created_at_idx ON crm_chat_transfer_events(created_at DESC);

-- =====================================================
-- 5) MIGRATE EXISTING DATA
-- =====================================================

-- Create a default instance for existing data (if needed)
-- This will be assigned to admin or first user
DO $$
DECLARE
  default_empresa_id UUID;
  default_user_id UUID;
  default_instance_id UUID;
  default_instance_name TEXT;
  default_base_url TEXT;
  default_api_key TEXT;
BEGIN
  -- Get default values from env or first available
  SELECT id INTO default_empresa_id FROM empresas ORDER BY created_at LIMIT 1;
  SELECT id INTO default_user_id FROM users WHERE role IN ('admin', 'administrador') ORDER BY created_at LIMIT 1;
  
  -- Use env values if available, otherwise placeholder
  default_instance_name := COALESCE(current_setting('app.evolution_instance_name', TRUE), 'default');
  default_base_url := COALESCE(current_setting('app.evolution_base_url', TRUE), 'https://your-evolution-api.com');
  default_api_key := COALESCE(current_setting('app.evolution_api_key', TRUE), 'PLACEHOLDER_KEY');

  -- Only create default instance if there are existing chats and no instances
  IF EXISTS (SELECT 1 FROM crm_chats LIMIT 1) AND NOT EXISTS (SELECT 1 FROM crm_instancias LIMIT 1) THEN
    INSERT INTO crm_instancias (
      empresa_id,
      user_id,
      nombre_instancia,
      evolution_base_url,
      evolution_api_key,
      is_active
    ) VALUES (
      default_empresa_id,
      default_user_id,
      default_instance_name,
      default_base_url,
      default_api_key,
      TRUE
    )
    RETURNING id INTO default_instance_id;

    -- Assign all existing chats to this default instance
    UPDATE crm_chats 
    SET 
      instancia_id = default_instance_id,
      owner_user_id = default_user_id,
      asignado_a_user_id = COALESCE(assigned_user_id, default_user_id)
    WHERE instancia_id IS NULL;

    -- Assign all existing messages to this default instance
    UPDATE crm_messages 
    RAISE NOTICE 'Created default instance % and migrated existing data', default_instance_id;
  END IF;
END $$;

-- =====================================================
-- 6) ADD UPDATED_AT TRIGGER FOR crm_instancias
-- =====================================================

CREATE OR REPLACE FUNCTION update_crm_instancias_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

  EXECUTE FUNCTION update_crm_instancias_updated_at();
COMMIT;

-- VERIFICATION QUERIES
-- =====================================================
  u.name as owner,
-- Check instance count
SELECT COUNT(*) as total_instances FROM crm_instancias;

-- Check instance distribution
SELECT 
  i.nombre_instancia,
  u.username as owner,
  i.is_active,
FROM crm_instancias i
LEFT JOIN users u ON u.id = i.user_id
LEFT JOIN crm_chats c ON c.instancia_id = i.id
GROUP BY i.id, u.username
ORDER BY i.created_at;

-- Check chats without instance (should be 0 if migration worked)
SELECT COUNT(*) as chats_without_instance 
FROM crm_chats 
WHERE instancia_id IS NULL;

*/

SELECT 1;
