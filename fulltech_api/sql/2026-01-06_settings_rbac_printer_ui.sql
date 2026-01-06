-- RBAC + Settings (Printer/UI) tables
--
-- Goals:
-- - Multi-tenant enforced via empresa_id.
-- - Safe to run repeatedly on existing databases.
-- - Backwards-compatible with legacy Usuario.rol (role enum).
--
-- Tables:
-- - rbac_roles: roles per empresa
-- - rbac_permissions: permission catalog
-- - rbac_role_permissions: many-to-many
-- - rbac_user_roles: many-to-many
-- - rbac_user_permission_overrides: allow/deny per user
-- - printer_settings: per-user printer settings
-- - ui_settings: per-user UI settings

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------
-- RBAC: roles & permissions
-- -----------------------------

CREATE TABLE IF NOT EXISTS rbac_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  name text NOT NULL,
  is_system boolean NOT NULL DEFAULT false,
  created_at timestamp(3) NOT NULL DEFAULT now(),
  updated_at timestamp(3) NOT NULL DEFAULT now(),
  UNIQUE (empresa_id, name)
);

CREATE TABLE IF NOT EXISTS rbac_permissions (
  code text PRIMARY KEY,
  description text NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS rbac_role_permissions (
  role_id uuid NOT NULL,
  permission_code text NOT NULL,
  created_at timestamp(3) NOT NULL DEFAULT now(),
  PRIMARY KEY (role_id, permission_code)
);

CREATE TABLE IF NOT EXISTS rbac_user_roles (
  user_id uuid NOT NULL,
  role_id uuid NOT NULL,
  created_at timestamp(3) NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS rbac_user_permission_overrides (
  user_id uuid NOT NULL,
  permission_code text NOT NULL,
  effect text NOT NULL CHECK (effect IN ('allow', 'deny')),
  created_at timestamp(3) NOT NULL DEFAULT now(),
  updated_at timestamp(3) NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, permission_code)
);

-- Foreign keys (guarded to avoid failures in fresh/partial environments)
DO $$
BEGIN
  IF to_regclass('rbac_roles') IS NOT NULL AND to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_rbac_roles_empresa') THEN
      ALTER TABLE rbac_roles
        ADD CONSTRAINT fk_rbac_roles_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('rbac_role_permissions') IS NOT NULL AND to_regclass('rbac_roles') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_rbac_role_permissions_role') THEN
      ALTER TABLE rbac_role_permissions
        ADD CONSTRAINT fk_rbac_role_permissions_role
        FOREIGN KEY (role_id) REFERENCES rbac_roles(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('rbac_role_permissions') IS NOT NULL AND to_regclass('rbac_permissions') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_rbac_role_permissions_perm') THEN
      ALTER TABLE rbac_role_permissions
        ADD CONSTRAINT fk_rbac_role_permissions_perm
        FOREIGN KEY (permission_code) REFERENCES rbac_permissions(code) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('rbac_user_roles') IS NOT NULL AND to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_rbac_user_roles_user') THEN
      ALTER TABLE rbac_user_roles
        ADD CONSTRAINT fk_rbac_user_roles_user
        FOREIGN KEY (user_id) REFERENCES "Usuario"(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('rbac_user_roles') IS NOT NULL AND to_regclass('rbac_roles') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_rbac_user_roles_role') THEN
      ALTER TABLE rbac_user_roles
        ADD CONSTRAINT fk_rbac_user_roles_role
        FOREIGN KEY (role_id) REFERENCES rbac_roles(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('rbac_user_permission_overrides') IS NOT NULL AND to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_rbac_user_perm_overrides_user') THEN
      ALTER TABLE rbac_user_permission_overrides
        ADD CONSTRAINT fk_rbac_user_perm_overrides_user
        FOREIGN KEY (user_id) REFERENCES "Usuario"(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('rbac_user_permission_overrides') IS NOT NULL AND to_regclass('rbac_permissions') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_rbac_user_perm_overrides_perm') THEN
      ALTER TABLE rbac_user_permission_overrides
        ADD CONSTRAINT fk_rbac_user_perm_overrides_perm
        FOREIGN KEY (permission_code) REFERENCES rbac_permissions(code) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_rbac_roles_empresa ON rbac_roles(empresa_id);
CREATE INDEX IF NOT EXISTS idx_rbac_user_roles_user ON rbac_user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_rbac_role_permissions_role ON rbac_role_permissions(role_id);

-- -----------------------------
-- Settings: printer + UI
-- -----------------------------

CREATE TABLE IF NOT EXISTS printer_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  user_id uuid NOT NULL,
  strategy text NOT NULL DEFAULT 'PDF_FALLBACK',
  printer_name text NULL,
  paper_width_mm integer NOT NULL DEFAULT 80,
  copies integer NOT NULL DEFAULT 1,
  created_at timestamp(3) NOT NULL DEFAULT now(),
  updated_at timestamp(3) NOT NULL DEFAULT now(),
  UNIQUE (empresa_id, user_id)
);

CREATE TABLE IF NOT EXISTS ui_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  user_id uuid NOT NULL,
  large_screen_mode boolean NOT NULL DEFAULT false,
  hide_sidebar boolean NOT NULL DEFAULT false,
  scale numeric(6,3) NOT NULL DEFAULT 1.0,
  created_at timestamp(3) NOT NULL DEFAULT now(),
  updated_at timestamp(3) NOT NULL DEFAULT now(),
  UNIQUE (empresa_id, user_id)
);

DO $$
BEGIN
  IF to_regclass('printer_settings') IS NOT NULL AND to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_printer_settings_empresa') THEN
      ALTER TABLE printer_settings
        ADD CONSTRAINT fk_printer_settings_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('printer_settings') IS NOT NULL AND to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_printer_settings_user') THEN
      ALTER TABLE printer_settings
        ADD CONSTRAINT fk_printer_settings_user
        FOREIGN KEY (user_id) REFERENCES "Usuario"(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('ui_settings') IS NOT NULL AND to_regclass('"Empresa"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_ui_settings_empresa') THEN
      ALTER TABLE ui_settings
        ADD CONSTRAINT fk_ui_settings_empresa
        FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id) ON DELETE CASCADE;
    END IF;
  END IF;

  IF to_regclass('ui_settings') IS NOT NULL AND to_regclass('"Usuario"') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_ui_settings_user') THEN
      ALTER TABLE ui_settings
        ADD CONSTRAINT fk_ui_settings_user
        FOREIGN KEY (user_id) REFERENCES "Usuario"(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_printer_settings_empresa_user ON printer_settings(empresa_id, user_id);
CREATE INDEX IF NOT EXISTS idx_ui_settings_empresa_user ON ui_settings(empresa_id, user_id);

-- -----------------------------
-- Seed permission catalog (idempotent)
-- -----------------------------

INSERT INTO rbac_permissions(code, description) VALUES
  ('settings.manage', 'Administrar configuración y permisos'),
  ('users.view', 'Ver usuarios'),
  ('users.manage', 'Crear/editar/bloquear usuarios'),
  ('pos.sell', 'Crear ventas en POS'),
  ('pos.purchases.manage', 'Gestionar compras en POS'),
  ('pos.inventory.adjust', 'Ajustar inventario (POS)'),
  ('pos.reports.view', 'Ver reportes POS'),
  ('inventory.view', 'Ver inventario'),
  ('inventory.manage', 'Gestionar inventario'),
  ('reports.view', 'Ver reportes'),
  ('printing.use', 'Usar impresión')
ON CONFLICT (code) DO UPDATE SET description = EXCLUDED.description;

-- Seed system roles per company (idempotent)
-- Uses legacy role names so mapping is straightforward.
DO $$
DECLARE
  emp RECORD;
BEGIN
  IF to_regclass('"Empresa"') IS NULL THEN
    RETURN;
  END IF;

  FOR emp IN SELECT id FROM "Empresa" LOOP
    INSERT INTO rbac_roles(empresa_id, name, is_system)
      VALUES (emp.id, 'admin', true)
      ON CONFLICT (empresa_id, name) DO NOTHING;

    INSERT INTO rbac_roles(empresa_id, name, is_system)
      VALUES (emp.id, 'administrador', true)
      ON CONFLICT (empresa_id, name) DO NOTHING;

    INSERT INTO rbac_roles(empresa_id, name, is_system)
      VALUES (emp.id, 'vendedor', true)
      ON CONFLICT (empresa_id, name) DO NOTHING;

    INSERT INTO rbac_roles(empresa_id, name, is_system)
      VALUES (emp.id, 'tecnico', true)
      ON CONFLICT (empresa_id, name) DO NOTHING;

    INSERT INTO rbac_roles(empresa_id, name, is_system)
      VALUES (emp.id, 'tecnico_fijo', true)
      ON CONFLICT (empresa_id, name) DO NOTHING;

    INSERT INTO rbac_roles(empresa_id, name, is_system)
      VALUES (emp.id, 'contratista', true)
      ON CONFLICT (empresa_id, name) DO NOTHING;

    INSERT INTO rbac_roles(empresa_id, name, is_system)
      VALUES (emp.id, 'asistente_administrativo', true)
      ON CONFLICT (empresa_id, name) DO NOTHING;
  END LOOP;
END $$;
