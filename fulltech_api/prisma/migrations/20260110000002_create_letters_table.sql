-- CreateEnum para LetterType y LetterStatus si no existen
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'LetterType') THEN
        CREATE TYPE "LetterType" AS ENUM ('GARANTIA', 'AGRADECIMIENTO', 'SEGUIMIENTO', 'CONFIRMACION_INSTALACION', 'RECORDATORIO_PAGO', 'RECHAZO', 'PERSONALIZADA');
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'LetterStatus') THEN
        CREATE TYPE "LetterStatus" AS ENUM ('DRAFT', 'SENT');
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'LetterExportFormat') THEN
        CREATE TYPE "LetterExportFormat" AS ENUM ('PDF');
    END IF;
END $$;

-- CreateTable letters
CREATE TABLE IF NOT EXISTS "letters" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "company_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "quotation_id" UUID,
    "customer_name" TEXT NOT NULL,
    "customer_phone" TEXT,
    "customer_email" TEXT,
    "letter_type" "LetterType" NOT NULL,
    "subject" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "status" "LetterStatus" NOT NULL DEFAULT 'DRAFT',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "letters_pkey" PRIMARY KEY ("id")
);

-- CreateTable letter_exports
CREATE TABLE IF NOT EXISTS "letter_exports" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "letter_id" UUID NOT NULL,
    "format" "LetterExportFormat" NOT NULL,
    "file_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "letter_exports_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "letters_company_id_idx" ON "letters"("company_id");
CREATE INDEX IF NOT EXISTS "letters_user_id_idx" ON "letters"("user_id");
CREATE INDEX IF NOT EXISTS "letters_quotation_id_idx" ON "letters"("quotation_id");
CREATE INDEX IF NOT EXISTS "letters_letter_type_idx" ON "letters"("letter_type");
CREATE INDEX IF NOT EXISTS "letters_created_at_idx" ON "letters"("created_at");
CREATE INDEX IF NOT EXISTS "letter_exports_letter_id_idx" ON "letter_exports"("letter_id");

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'letters_company_id_fkey'
    ) THEN
        ALTER TABLE "letters" ADD CONSTRAINT "letters_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "empresas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'letters_user_id_fkey'
    ) THEN
        ALTER TABLE "letters" ADD CONSTRAINT "letters_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'letters_quotation_id_fkey'
    ) THEN
        ALTER TABLE "letters" ADD CONSTRAINT "letters_quotation_id_fkey" FOREIGN KEY ("quotation_id") REFERENCES "quotations"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'letter_exports_letter_id_fkey'
    ) THEN
        ALTER TABLE "letter_exports" ADD CONSTRAINT "letter_exports_letter_id_fkey" FOREIGN KEY ("letter_id") REFERENCES "letters"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
