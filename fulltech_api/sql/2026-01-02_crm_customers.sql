-- FULLTECH CRM & Operaciones
-- Base CRM (threads/messages/tasks) + Customers
-- Fecha: 2026-01-02
-- DB: fulltechapp_sistem

BEGIN;

-- UUID generator (Prisma typically uses gen_random_uuid)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================
-- 1) customers
-- =====================
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES "Empresa"(id),
  nombre TEXT NOT NULL,
  telefono TEXT NOT NULL,
  email TEXT NULL,
  direccion TEXT NULL,
  ubicacion_mapa TEXT NULL,
  tags TEXT[] NOT NULL DEFAULT '{}',
  notas TEXT NULL,
  origen TEXT NOT NULL DEFAULT 'whatsapp',
  sync_version INT NOT NULL DEFAULT 1,
  deleted_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS customers_empresa_telefono_uniq
  ON customers(empresa_id, telefono)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS customers_empresa_idx ON customers(empresa_id);
CREATE INDEX IF NOT EXISTS customers_telefono_idx ON customers(telefono);

-- Keep updated_at fresh
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_customers_updated_at ON customers;
CREATE TRIGGER trg_customers_updated_at
BEFORE UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================
-- 2) crm_threads
-- =====================
CREATE TABLE IF NOT EXISTS crm_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES "Empresa"(id),
  phone_number TEXT NOT NULL,
  display_name TEXT NULL,
  canal TEXT NOT NULL DEFAULT 'whatsapp',
  customer_id UUID NULL REFERENCES customers(id),
  estado_crm TEXT NOT NULL DEFAULT 'pendiente',
  assigned_user_id UUID NULL REFERENCES "Usuario"(id),
  last_message_preview TEXT NULL,
  last_message_at TIMESTAMPTZ NULL,
  pinned BOOLEAN NOT NULL DEFAULT FALSE,
  primary_interest TEXT NULL,
  sync_version INT NOT NULL DEFAULT 1,
  deleted_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS crm_threads_empresa_phone_uniq
  ON crm_threads(empresa_id, phone_number)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS crm_threads_phone_idx ON crm_threads(phone_number);
CREATE INDEX IF NOT EXISTS crm_threads_estado_idx ON crm_threads(estado_crm);
CREATE INDEX IF NOT EXISTS crm_threads_assigned_idx ON crm_threads(assigned_user_id);
CREATE INDEX IF NOT EXISTS crm_threads_last_message_at_idx ON crm_threads(last_message_at);

DROP TRIGGER IF EXISTS trg_crm_threads_updated_at ON crm_threads;
CREATE TRIGGER trg_crm_threads_updated_at
BEFORE UPDATE ON crm_threads
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================
-- 3) crm_messages
-- =====================
CREATE TABLE IF NOT EXISTS crm_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES "Empresa"(id),
  thread_id UUID NOT NULL REFERENCES crm_threads(id) ON DELETE CASCADE,
  message_id TEXT NULL,
  from_me BOOLEAN NOT NULL,
  type TEXT NOT NULL DEFAULT 'text',
  body TEXT NULL,
  media_url TEXT NULL,
  sync_version INT NOT NULL DEFAULT 1,
  deleted_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS crm_messages_message_id_uniq
  ON crm_messages(message_id)
  WHERE message_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS crm_messages_thread_created_idx
  ON crm_messages(thread_id, created_at);

DROP TRIGGER IF EXISTS trg_crm_messages_updated_at ON crm_messages;
CREATE TRIGGER trg_crm_messages_updated_at
BEFORE UPDATE ON crm_messages
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================
-- 4) crm_tasks
-- =====================
CREATE TABLE IF NOT EXISTS crm_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES "Empresa"(id),
  thread_id UUID NOT NULL REFERENCES crm_threads(id) ON DELETE CASCADE,
  assigned_user_id UUID NOT NULL REFERENCES "Usuario"(id),
  tipo TEXT NOT NULL,
  fecha_hora TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'pendiente',
  nota TEXT NULL,
  sync_version INT NOT NULL DEFAULT 1,
  deleted_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS crm_tasks_assigned_fecha_idx
  ON crm_tasks(assigned_user_id, fecha_hora);
CREATE INDEX IF NOT EXISTS crm_tasks_status_idx
  ON crm_tasks(status);

DROP TRIGGER IF EXISTS trg_crm_tasks_updated_at ON crm_tasks;
CREATE TRIGGER trg_crm_tasks_updated_at
BEFORE UPDATE ON crm_tasks
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMIT;
