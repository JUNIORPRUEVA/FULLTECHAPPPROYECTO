-- Services and Agenda Module
-- Date: 2026-01-08
-- Description: Create agenda items table for scheduling

BEGIN;

-- Enum for agenda item types
DO $$ BEGIN
  CREATE TYPE "AgendaItemType" AS ENUM ('RESERVA', 'SERVICIO_RESERVADO', 'GARANTIA', 'SOLUCION_GARANTIA');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Agenda items table
CREATE TABLE IF NOT EXISTS agenda_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES "Empresa"(id) ON DELETE CASCADE,
  thread_id UUID REFERENCES crm_threads(id) ON DELETE SET NULL,
  client_id UUID,
  client_phone TEXT,
  client_name TEXT,
  type "AgendaItemType" NOT NULL,
  scheduled_at TIMESTAMPTZ,
  service_id UUID REFERENCES services(id) ON DELETE SET NULL,
  service_name TEXT,
  product_name TEXT,
  technician_id UUID REFERENCES "Usuario"(id) ON DELETE SET NULL,
  technician_name TEXT,
  note TEXT,
  details TEXT,
  serial_number TEXT,
  warranty_months INTEGER,
  warranty_time TEXT,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_agenda_items_empresa_id ON agenda_items(empresa_id);
CREATE INDEX IF NOT EXISTS idx_agenda_items_empresa_type ON agenda_items(empresa_id, type);
CREATE INDEX IF NOT EXISTS idx_agenda_items_empresa_scheduled ON agenda_items(empresa_id, scheduled_at);
CREATE INDEX IF NOT EXISTS idx_agenda_items_technician ON agenda_items(technician_id);
CREATE INDEX IF NOT EXISTS idx_agenda_items_thread ON agenda_items(thread_id);
CREATE INDEX IF NOT EXISTS idx_agenda_items_completed ON agenda_items(is_completed);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_agenda_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_agenda_items_updated_at ON agenda_items;
CREATE TRIGGER trigger_agenda_items_updated_at
  BEFORE UPDATE ON agenda_items
  FOR EACH ROW
  EXECUTE FUNCTION update_agenda_items_updated_at();

COMMIT;
