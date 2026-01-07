-- Sales placeholder table for CRM lead->customer conversion (DEPRECATED)
--
-- This migration originally created a table named `sales`, which now conflicts with
-- the real Sales module introduced in `2026-01-04_create_sales_module_tables.sql`.
--
-- Keep this file as a no-op for backward compatibility, so automated runners
-- can safely apply the entire `sql/` folder in order.

DO $$
BEGIN
  RAISE NOTICE 'Skipping deprecated migration: 2026-01-02_sales_placeholder.sql';
END $$;
