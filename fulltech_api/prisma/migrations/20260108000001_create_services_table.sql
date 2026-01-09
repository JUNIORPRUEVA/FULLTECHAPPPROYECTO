-- CreateTable: services
-- Description: Catalog of services offered by the company
-- Date: 2026-01-08

CREATE TABLE "services" (
  "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "empresa_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT,
  "default_price" DECIMAL(10,2),
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT "services_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "Empresa"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "services_empresa_id_idx" ON "services"("empresa_id");
CREATE INDEX "services_empresa_id_is_active_idx" ON "services"("empresa_id", "is_active");
CREATE INDEX "services_name_idx" ON "services"("name");

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_services_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER services_updated_at_trigger
BEFORE UPDATE ON "services"
FOR EACH ROW
EXECUTE FUNCTION update_services_updated_at();
