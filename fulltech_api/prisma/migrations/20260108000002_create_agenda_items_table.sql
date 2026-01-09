-- CreateEnum: AgendaItemType
CREATE TYPE "AgendaItemType" AS ENUM ('RESERVA', 'SERVICIO_RESERVADO', 'GARANTIA', 'SOLUCION_GARANTIA');

-- CreateTable: agenda_items
-- Description: Unified agenda for reservations, services, warranties, and solutions
-- Date: 2026-01-08

CREATE TABLE "agenda_items" (
  "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "empresa_id" UUID NOT NULL,
  "thread_id" UUID,
  "client_id" UUID,
  "client_phone" TEXT,
  "client_name" TEXT,
  "type" "AgendaItemType" NOT NULL,
  "scheduled_at" TIMESTAMP(3),
  "service_id" UUID,
  "service_name" TEXT,
  "product_name" TEXT,
  "technician_id" UUID,
  "technician_name" TEXT,
  "note" TEXT,
  "details" TEXT,
  "serial_number" TEXT,
  "warranty_months" INTEGER,
  "warranty_time" TEXT,
  "is_completed" BOOLEAN NOT NULL DEFAULT false,
  "completed_at" TIMESTAMP(3),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT "agenda_items_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "Empresa"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "agenda_items_thread_id_fkey" FOREIGN KEY ("thread_id") REFERENCES "crm_threads"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT "agenda_items_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "services"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT "agenda_items_technician_id_fkey" FOREIGN KEY ("technician_id") REFERENCES "Usuario"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "agenda_items_empresa_id_idx" ON "agenda_items"("empresa_id");
CREATE INDEX "agenda_items_empresa_id_type_idx" ON "agenda_items"("empresa_id", "type");
CREATE INDEX "agenda_items_empresa_id_scheduled_at_idx" ON "agenda_items"("empresa_id", "scheduled_at");
CREATE INDEX "agenda_items_technician_id_idx" ON "agenda_items"("technician_id");
CREATE INDEX "agenda_items_thread_id_idx" ON "agenda_items"("thread_id");
CREATE INDEX "agenda_items_is_completed_idx" ON "agenda_items"("is_completed");

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_agenda_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER agenda_items_updated_at_trigger
BEFORE UPDATE ON "agenda_items"
FOR EACH ROW
EXECUTE FUNCTION update_agenda_items_updated_at();
