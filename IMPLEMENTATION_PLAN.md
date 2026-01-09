# CRM/CLIENTS/OPERATIONS FIXES - Implementation Plan

## ISSUE 1: Clientes Activos Page Empty Despite Having Data

### Root Cause
When `convertChatToCustomer` is called from CRM status change (activo, compro, compra_finalizada), it creates a customer with NO tags. The backend's `isActiveCustomer` logic requires tags=['compro'] or tags=['activo'] to consider a customer as "active". Result: counters see the customer record, but list filters them out.

### Fix Implementation

#### Backend: `fulltech_api/src/modules/crm/crm_whatsapp.controller.ts`
- Modify `convertChatToCustomer` to accept `status` query parameter
- Map CRM status to appropriate customer tags:
  - `activo` → tags: ['activo']
  - `compro` → tags: ['compro']  
  - `compra_finalizada` → tags: ['compro', 'finalizado']
- Ensure upsert logic updates existing customer tags instead of skipping

#### Frontend: `fulltech_app/lib/features/crm/presentation/widgets/right_panel_crm.dart`
- Pass `status` parameter when calling convertChatToCustomer
- Add logging to verify the flow
- Trigger immediate refresh of customers list

---

## ISSUE 2: Mandatory Dialogs Must Block Status Change

### Current Issue
Dialogs exist but user can potentially close/cancel and still have status applied.

### Fix Implementation

#### `right_panel_crm.dart` Status Change Flow
1. User selects new status from dropdown
2. Check `CrmStatuses.needsDialog(status)`
3. If true:
   - Open dialog and await result
   - If result is null (cancelled) → RETURN without changing status
   - If result is valid → save dialog data, THEN apply status
4. Only after successful dialog submission → call onSave with new status

#### Dialog Validation
All dialogs already have proper validation. Ensure:
- Cancel button returns `null`
- Submit button validates and returns result object
- X button returns `null`

---

## ISSUE 3: Technicians from Users + Services Catalog

### Part A: Load Technicians from Users Table

#### Backend Endpoint
**GET /api/users?rol=tecnico_fijo,contratista&estado=activo**

Already exists in `fulltech_api/src/modules/users/users.controller.ts:listUsers`

#### Frontend Implementation
1. Create `technicians_provider.dart`:
   - Load users with roles: tecnico_fijo, contratista
   - Filter by estado=activo
   - Return list with id, nombre_completo, telefono

2. Update Dialogs:
   - Replace TextFormField for technician with Dropdown
   - Load from technicians provider
   - Save technician_id instead of free text

### Part B: Services Catalog

#### Database Schema (Cloud + Local)

**Cloud (Postgres): `fulltech_api/prisma/schema.prisma`**
```prisma
model Service {
  id            String   @id @default(uuid()) @db.Uuid
  empresa_id    String   @db.Uuid
  name          String
  description   String?
  default_price Decimal? @db.Decimal(10,2)
  is_active     Boolean  @default(true)
  created_at    DateTime @default(now())
  updated_at    DateTime @updatedAt
  
  empresa       Empresa  @relation(fields: [empresa_id], references: [id])
  
  @@index([empresa_id])
  @@index([empresa_id, is_active])
  @@map("services")
}
```

**Local (SQLite): `fulltech_app/lib/core/storage/local_db_io.dart`**
```sql
CREATE TABLE services(
  id TEXT PRIMARY KEY,
  empresa_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  default_price REAL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'pending',
  last_error TEXT
);
```

#### Backend Endpoints
**`fulltech_api/src/modules/services/`** (new module)
- GET /api/services → list services
- POST /api/services → create service
- PUT /api/services/:id → update service
- DELETE /api/services/:id → soft delete

#### Frontend Implementation
1. Create services feature module
2. CRUD UI for managing services
3. Service selector in dialogs
4. Sync services between local and cloud

### Part C: Unified Agenda Table

#### Database Schema

**Cloud (Postgres):**
```prisma
enum AgendaItemType {
  RESERVA
  SERVICIO_RESERVADO
  GARANTIA
  SOLUCION_GARANTIA
}

model AgendaItem {
  id                String         @id @default(uuid()) @db.Uuid
  empresa_id        String         @db.Uuid
  thread_id         String?        @db.Uuid
  client_id         String?        @db.Uuid
  client_phone      String?
  client_name       String?
  type              AgendaItemType
  scheduled_at      DateTime?
  service_id        String?        @db.Uuid
  service_name      String?
  product_name      String?
  technician_id     String?        @db.Uuid
  note              String?
  serial_number     String?
  warranty_months   Int?
  is_completed      Boolean        @default(false)
  created_at        DateTime       @default(now())
  updated_at        DateTime       @updatedAt
  
  empresa           Empresa        @relation(fields: [empresa_id], references: [id])
  thread            CrmThread?     @relation(fields: [thread_id], references: [id])
  
  @@index([empresa_id, type])
  @@index([empresa_id, scheduled_at])
  @@index([technician_id])
  @@map("agenda_items")
}
```

**Local (SQLite):**
```sql
CREATE TABLE agenda_items(
  id TEXT PRIMARY KEY,
  empresa_id TEXT NOT NULL,
  thread_id TEXT,
  client_id TEXT,
  client_phone TEXT,
  client_name TEXT,
  type TEXT NOT NULL, -- RESERVA, SERVICIO_RESERVADO, GARANTIA, SOLUCION_GARANTIA
  scheduled_at TEXT,
  service_id TEXT,
  service_name TEXT,
  product_name TEXT,
  technician_id TEXT,
  note TEXT,
  serial_number TEXT,
  warranty_months INTEGER,
  is_completed INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'pending',
  last_error TEXT
);
```

---

## Implementation Order

### Phase 1: Fix Clientes Activos (ISSUE 1) - CRITICAL
1. ✅ Backend: Update convertChatToCustomer to accept status and set tags
2. ✅ Frontend: Pass status when calling convertChatToCustomer
3. ✅ Test: Mark chat as "Activo" → verify appears in Clientes Activos immediately

### Phase 2: Enforce Mandatory Dialogs (ISSUE 2)
1. ✅ Update right_panel_crm.dart status change logic
2. ✅ Ensure all dialog cancellations prevent status change
3. ✅ Test: Try to cancel each dialog → status should not change

### Phase 3: Services Module (ISSUE 3 - Part B)
1. ✅ Create database migration for services table (cloud)
2. ✅ Update local DB schema for services table (local)
3. ✅ Create backend CRUD endpoints
4. ✅ Create frontend services repository
5. ✅ Create services management UI
6. ✅ Implement sync for services

### Phase 4: Technicians Integration (ISSUE 3 - Part A)
1. ✅ Create technicians provider (loads from users API)
2. ✅ Update all dialogs to use technician dropdown
3. ✅ Save technician_id instead of free text

### Phase 5: Unified Agenda (ISSUE 3 - Part C)
1. ✅ Create agenda_items table migration (cloud)
2. ✅ Update local DB schema for agenda_items (local)
3. ✅ Create backend CRUD endpoints for agenda
4. ✅ Update dialog submissions to save to agenda_items
5. ✅ Update Operations agenda_page to query agenda_items
6. ✅ Implement sync for agenda items

### Phase 6: Integration Testing
1. ✅ End-to-end test: CRM status change → client creation → appears in list
2. ✅ Test each dialog: required fields, technician selection, service selection
3. ✅ Test Operations agenda: shows all items, filters work, technician assignment
4. ✅ Test offline → online sync for all new tables

---

## Acceptance Criteria (from User Request)

✅ 1. Clients Activos list shows all active clients; counters match list
✅ 2. Mark chat as Activo in CRM → client appears immediately
✅ 3. Dialogs are MANDATORY for special statuses; cancel = no status change
✅ 4. Technician dropdown lists users with roles tecnico/contratista
✅ 5. Service dropdown lists services from SERVICES table
✅ 6. Services + agenda items stored locally and in cloud and sync immediately
✅ 7. No duplicate clients (idempotent upsert)
✅ 8. Multi-tenant empresa_id filtering works everywhere

---

## Migration Files Needed

1. `fulltech_api/prisma/migrations/YYYYMMDD_create_services.sql`
2. `fulltech_api/prisma/migrations/YYYYMMDD_create_agenda_items.sql`
3. Update `fulltech_app/lib/core/storage/local_db_io.dart` schema version 11

---

## Files to Create/Modify

### Backend (fulltech_api)
- [ ] `src/modules/services/services.controller.ts` (NEW)
- [ ] `src/modules/services/services.routes.ts` (NEW)
- [ ] `src/modules/services/services.schema.ts` (NEW)
- [ ] `src/modules/crm/crm_agenda.controller.ts` (NEW)
- [ ] `src/modules/crm/crm_agenda.routes.ts` (NEW)
- [ ] `src/modules/crm/crm_whatsapp.controller.ts` (MODIFY - convertChatToCustomer)
- [ ] `prisma/schema.prisma` (ADD Service and AgendaItem models)

### Frontend (fulltech_app)
- [ ] `lib/features/services/` (NEW MODULE)
- [ ] `lib/features/crm/providers/technicians_provider.dart` (NEW)
- [ ] `lib/features/crm/presentation/widgets/right_panel_crm.dart` (MODIFY)
- [ ] `lib/features/crm/presentation/widgets/status_dialogs/*.dart` (MODIFY ALL)
- [ ] `lib/features/operations/presentation/pages/agenda_page.dart` (MODIFY)
- [ ] `lib/core/storage/local_db_io.dart` (MODIFY - add tables)
