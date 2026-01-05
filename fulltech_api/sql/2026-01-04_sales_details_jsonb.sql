-- Add JSONB details column to new sales module for multi-line items
-- Table: sales (mapped from Prisma model SalesRecord)

ALTER TABLE sales
  ADD COLUMN IF NOT EXISTS details jsonb;
