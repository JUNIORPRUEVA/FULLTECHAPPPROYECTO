-- Payroll Quincenal (biweekly) module
-- Safe/Idempotent-ish SQL: uses DO blocks for enums/constraints and IF NOT EXISTS for tables/indexes.

-- Enums
DO $$ BEGIN
  CREATE TYPE "PayrollPeriodHalf" AS ENUM ('FIRST', 'SECOND');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "PayrollPeriodStatus" AS ENUM ('OPEN', 'LOCKED', 'CLOSED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "PayrollRunStatus" AS ENUM ('DRAFT', 'REVIEW', 'APPROVED', 'PAID', 'CLOSED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "PayrollEmployeeStatus" AS ENUM ('READY', 'NEEDS_REVIEW', 'LOCKED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "PayrollLineItemType" AS ENUM ('EARNING', 'DEDUCTION');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "PayrollMovementType" AS ENUM ('EARNING', 'DEDUCTION');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "PayrollMovementSource" AS ENUM ('MANUAL', 'SALES_COMMISSION', 'ADVANCE', 'LOAN', 'ADJUSTMENT', 'OTHER');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "PayrollMovementStatus" AS ENUM ('PENDING', 'APPLIED', 'VOIDED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Tables
CREATE TABLE IF NOT EXISTS "payroll_periods" (
  "id" UUID NOT NULL,
  "company_id" UUID NOT NULL,
  "year" INTEGER NOT NULL,
  "month" INTEGER NOT NULL,
  "half" "PayrollPeriodHalf" NOT NULL,
  "date_from" DATE NOT NULL,
  "date_to" DATE NOT NULL,
  "status" "PayrollPeriodStatus" NOT NULL DEFAULT 'OPEN',
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "payroll_periods_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "payroll_runs" (
  "id" UUID NOT NULL,
  "company_id" UUID NOT NULL,
  "period_id" UUID NOT NULL,
  "created_by_user_id" UUID NOT NULL,
  "status" "PayrollRunStatus" NOT NULL DEFAULT 'DRAFT',
  "approved_by_user_id" UUID,
  "paid_by_user_id" UUID,
  "paid_at" TIMESTAMP(3),
  "notes" TEXT,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "payroll_runs_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "payroll_employee_summaries" (
  "id" UUID NOT NULL,
  "run_id" UUID NOT NULL,
  "employee_user_id" UUID NOT NULL,
  "base_salary_amount" DECIMAL(12,2) NOT NULL,
  "commissions_amount" DECIMAL(12,2) NOT NULL,
  "other_earnings_amount" DECIMAL(12,2) NOT NULL,
  "gross_amount" DECIMAL(12,2) NOT NULL,
  "statutory_deductions_amount" DECIMAL(12,2) NOT NULL,
  "other_deductions_amount" DECIMAL(12,2) NOT NULL,
  "net_amount" DECIMAL(12,2) NOT NULL,
  "currency" TEXT NOT NULL DEFAULT 'DOP',
  "status" "PayrollEmployeeStatus" NOT NULL DEFAULT 'READY',
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "payroll_employee_summaries_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "payroll_line_items" (
  "id" UUID NOT NULL,
  "employee_summary_id" UUID NOT NULL,
  "type" "PayrollLineItemType" NOT NULL,
  "concept_code" TEXT NOT NULL,
  "concept_name" TEXT NOT NULL,
  "amount" DECIMAL(12,2) NOT NULL,
  "meta" JSONB,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "payroll_line_items_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "payroll_movements" (
  "id" UUID NOT NULL,
  "company_id" UUID NOT NULL,
  "employee_user_id" UUID NOT NULL,
  "movement_type" "PayrollMovementType" NOT NULL,
  "source" "PayrollMovementSource" NOT NULL,
  "concept_code" TEXT NOT NULL,
  "concept_name" TEXT NOT NULL,
  "amount" DECIMAL(12,2) NOT NULL,
  "effective_date" DATE NOT NULL,
  "period_id" UUID,
  "status" "PayrollMovementStatus" NOT NULL DEFAULT 'PENDING',
  "created_by_user_id" UUID NOT NULL,
  "approved_by_user_id" UUID,
  "note" TEXT,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "payroll_movements_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "statutory_config" (
  "id" UUID NOT NULL,
  "company_id" UUID NOT NULL,
  "year" INTEGER NOT NULL,
  "config" JSONB NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "statutory_config_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "payroll_payslips" (
  "id" UUID NOT NULL,
  "run_id" UUID NOT NULL,
  "employee_user_id" UUID NOT NULL,
  "pdf_url" TEXT,
  "snapshot" JSONB NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "payroll_payslips_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "audit_log" (
  "id" UUID NOT NULL,
  "company_id" UUID NOT NULL,
  "actor_user_id" UUID NOT NULL,
  "action" TEXT NOT NULL,
  "entity" TEXT NOT NULL,
  "entity_id" TEXT NOT NULL,
  "meta" JSONB,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id")
);

-- Indexes
CREATE INDEX IF NOT EXISTS "payroll_periods_company_id_idx" ON "payroll_periods"("company_id");
CREATE INDEX IF NOT EXISTS "payroll_periods_year_month_idx" ON "payroll_periods"("year", "month");
DO $$ BEGIN
  CREATE UNIQUE INDEX "payroll_periods_company_id_year_month_half_key" ON "payroll_periods"("company_id", "year", "month", "half");
EXCEPTION WHEN duplicate_table OR duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "payroll_runs_company_id_idx" ON "payroll_runs"("company_id");
CREATE INDEX IF NOT EXISTS "payroll_runs_period_id_idx" ON "payroll_runs"("period_id");
CREATE INDEX IF NOT EXISTS "payroll_runs_status_idx" ON "payroll_runs"("status");

CREATE INDEX IF NOT EXISTS "payroll_employee_summaries_run_id_idx" ON "payroll_employee_summaries"("run_id");
CREATE INDEX IF NOT EXISTS "payroll_employee_summaries_employee_user_id_idx" ON "payroll_employee_summaries"("employee_user_id");
DO $$ BEGIN
  CREATE UNIQUE INDEX "payroll_employee_summaries_run_id_employee_user_id_key" ON "payroll_employee_summaries"("run_id", "employee_user_id");
EXCEPTION WHEN duplicate_table OR duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "payroll_line_items_employee_summary_id_idx" ON "payroll_line_items"("employee_summary_id");
CREATE INDEX IF NOT EXISTS "payroll_line_items_concept_code_idx" ON "payroll_line_items"("concept_code");

CREATE INDEX IF NOT EXISTS "payroll_movements_company_id_idx" ON "payroll_movements"("company_id");
CREATE INDEX IF NOT EXISTS "payroll_movements_employee_user_id_idx" ON "payroll_movements"("employee_user_id");
CREATE INDEX IF NOT EXISTS "payroll_movements_period_id_idx" ON "payroll_movements"("period_id");
CREATE INDEX IF NOT EXISTS "payroll_movements_status_idx" ON "payroll_movements"("status");
CREATE INDEX IF NOT EXISTS "payroll_movements_effective_date_idx" ON "payroll_movements"("effective_date");

CREATE INDEX IF NOT EXISTS "statutory_config_company_id_idx" ON "statutory_config"("company_id");
CREATE INDEX IF NOT EXISTS "statutory_config_year_idx" ON "statutory_config"("year");
CREATE INDEX IF NOT EXISTS "statutory_config_active_idx" ON "statutory_config"("active");

CREATE INDEX IF NOT EXISTS "payroll_payslips_run_id_idx" ON "payroll_payslips"("run_id");
CREATE INDEX IF NOT EXISTS "payroll_payslips_employee_user_id_idx" ON "payroll_payslips"("employee_user_id");
DO $$ BEGIN
  CREATE UNIQUE INDEX "payroll_payslips_run_id_employee_user_id_key" ON "payroll_payslips"("run_id", "employee_user_id");
EXCEPTION WHEN duplicate_table OR duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS "audit_log_company_id_idx" ON "audit_log"("company_id");
CREATE INDEX IF NOT EXISTS "audit_log_actor_user_id_idx" ON "audit_log"("actor_user_id");
CREATE INDEX IF NOT EXISTS "audit_log_entity_idx" ON "audit_log"("entity");
CREATE INDEX IF NOT EXISTS "audit_log_entity_id_idx" ON "audit_log"("entity_id");
CREATE INDEX IF NOT EXISTS "audit_log_created_at_idx" ON "audit_log"("created_at");

-- Foreign keys (wrapped to avoid duplicate constraint errors)
DO $$ BEGIN
  ALTER TABLE "payroll_periods" ADD CONSTRAINT "payroll_periods_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "Empresa"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_runs" ADD CONSTRAINT "payroll_runs_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "Empresa"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_runs" ADD CONSTRAINT "payroll_runs_period_id_fkey" FOREIGN KEY ("period_id") REFERENCES "payroll_periods"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_runs" ADD CONSTRAINT "payroll_runs_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "Usuario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_runs" ADD CONSTRAINT "payroll_runs_approved_by_user_id_fkey" FOREIGN KEY ("approved_by_user_id") REFERENCES "Usuario"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_runs" ADD CONSTRAINT "payroll_runs_paid_by_user_id_fkey" FOREIGN KEY ("paid_by_user_id") REFERENCES "Usuario"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_employee_summaries" ADD CONSTRAINT "payroll_employee_summaries_run_id_fkey" FOREIGN KEY ("run_id") REFERENCES "payroll_runs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_employee_summaries" ADD CONSTRAINT "payroll_employee_summaries_employee_user_id_fkey" FOREIGN KEY ("employee_user_id") REFERENCES "Usuario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_line_items" ADD CONSTRAINT "payroll_line_items_employee_summary_id_fkey" FOREIGN KEY ("employee_summary_id") REFERENCES "payroll_employee_summaries"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_movements" ADD CONSTRAINT "payroll_movements_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "Empresa"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_movements" ADD CONSTRAINT "payroll_movements_employee_user_id_fkey" FOREIGN KEY ("employee_user_id") REFERENCES "Usuario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_movements" ADD CONSTRAINT "payroll_movements_period_id_fkey" FOREIGN KEY ("period_id") REFERENCES "payroll_periods"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_movements" ADD CONSTRAINT "payroll_movements_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "Usuario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_movements" ADD CONSTRAINT "payroll_movements_approved_by_user_id_fkey" FOREIGN KEY ("approved_by_user_id") REFERENCES "Usuario"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "statutory_config" ADD CONSTRAINT "statutory_config_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "Empresa"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_payslips" ADD CONSTRAINT "payroll_payslips_run_id_fkey" FOREIGN KEY ("run_id") REFERENCES "payroll_runs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "payroll_payslips" ADD CONSTRAINT "payroll_payslips_employee_user_id_fkey" FOREIGN KEY ("employee_user_id") REFERENCES "Usuario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "audit_log" ADD CONSTRAINT "audit_log_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "Empresa"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "audit_log" ADD CONSTRAINT "audit_log_actor_user_id_fkey" FOREIGN KEY ("actor_user_id") REFERENCES "Usuario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
