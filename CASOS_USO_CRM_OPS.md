# 📖 Casos de Uso: CRM → Operaciones

## Escenarios Reales de Prueba

Este documento muestra ejemplos prácticos de cómo funciona el flujo CRM → Operaciones con datos reales.

---

## 🎬 Caso 1: Levantamiento para Cliente Nuevo

### Situación
Un cliente potencial contactó por WhatsApp pidiendo información sobre instalación de aire acondicionado. Después de conversar, acordamos hacer un levantamiento técnico.

### Pasos

1. **En CRM**: Chat con +54 9 11 2345-6789
   - Display name: "Roberto González"
   - Estado actual: "primer_contacto"

2. **Cambiar estado a "por_levantamiento"**:
   ```json
   POST /api/crm/chats/chat-abc-123/status
   {
     "status": "por_levantamiento",
     "scheduled_at": "2026-01-15T10:00:00-03:00",
     "location_text": "Av. Santa Fe 1234, CABA",
     "lat": -34.595454,
     "lng": -58.394344,
     "assigned_technician_id": "tech-juan-001",
     "service_id": "service-ac-install",
     "note": "Cliente quiere cotización para 3 ambientes. Llamar antes de ir."
   }
   ```

### Resultado Esperado

✅ **Cliente creado automáticamente**:
```sql
SELECT * FROM customer WHERE telefono LIKE '%23456789';

id              | customer-001
nombre          | Roberto González
telefono        | +5491123456789
origen          | whatsapp
empresa_id      | empresa-123
created_at      | 2026-01-10 15:30:00
```

✅ **Job de operaciones creado**:
```sql
SELECT * FROM operations_jobs WHERE crm_chat_id = 'chat-abc-123';

id                  | job-lev-001
crm_chat_id         | chat-abc-123
crm_customer_id     | customer-001
crm_task_type       | LEVANTAMIENTO
status              | pending_survey
customer_name       | Roberto González
customer_phone      | +5491123456789
service_type        | Levantamiento
scheduled_at        | 2026-01-15 10:00:00
location_text       | Av. Santa Fe 1234, CABA
assigned_tech_id    | tech-juan-001
service_id          | service-ac-install
notes               | Cliente quiere cotización para 3 ambientes...
empresa_id          | empresa-123
```

✅ **Schedule creado para agenda**:
```sql
SELECT * FROM operations_schedule WHERE job_id = 'job-lev-001';

id                      | schedule-001
job_id                  | job-lev-001
scheduled_date          | 2026-01-15
preferred_time          | 10:00
assigned_tech_id        | tech-juan-001
```

✅ **Visible en módulo Operaciones**:
- Pestaña "Levantamientos": ✅ Aparece
- Pestaña "Agenda": ✅ Aparece (15 de enero)
- Técnico asignado: Juan Pérez
- Estado: "Pendiente de levantamiento"

---

## 🎬 Caso 2: Servicio Agendado Directo

### Situación
Un cliente que ya compró quiere agendar la instalación directamente, sin levantamiento previo.

### Pasos

1. **En CRM**: Chat con +54 9 11 8765-4321
   - Display name: "María López"
   - Estado actual: "compro"

2. **Cliente ya existe en sistema**:
   - ID: customer-002
   - Compró 2 equipos de AC

3. **Cambiar estado a "servicio_reservado"**:
   ```json
   POST /api/crm/chats/chat-xyz-456/status
   {
     "status": "servicio_reservado",
     "scheduled_at": "2026-01-20T14:30:00-03:00",
     "location_text": "Calle Corrientes 5678, Apto 5B",
     "lat": -34.603722,
     "lng": -58.381592,
     "assigned_technician_id": "tech-carlos-002",
     "service_id": "service-ac-install",
     "note": "Instalación de 2 equipos Split. Cliente disponible todo el día."
   }
   ```

### Resultado Esperado

✅ **Cliente existente se reutiliza** (NO se duplica):
```sql
-- Solo debe existir UN registro
SELECT COUNT(*) FROM customer WHERE telefono LIKE '%87654321';
-- Result: 1
```

✅ **Job de servicio creado**:
```sql
SELECT * FROM operations_jobs WHERE crm_chat_id = 'chat-xyz-456';

id                  | job-serv-001
crm_chat_id         | chat-xyz-456
crm_customer_id     | customer-002
crm_task_type       | SERVICIO_RESERVADO
status              | scheduled
customer_name       | María López
service_type        | Servicio reservado
scheduled_at        | 2026-01-20 14:30:00
location_text       | Calle Corrientes 5678, Apto 5B
assigned_tech_id    | tech-carlos-002
```

✅ **Visible en Operaciones**:
- Pestaña "Instalaciones": ✅ Aparece
- Pestaña "Agenda": ✅ Aparece (20 de enero, 14:30)
- Técnico: Carlos Martínez

---

## 🎬 Caso 3: Actualización Sin Duplicar (Idempotencia)

### Situación
El cliente llamó y pidió cambiar la fecha del levantamiento.

### Pasos

1. **Estado actual**: Ya existe job-lev-001 (del Caso 1)

2. **Cambiar fecha en CRM**:
   ```json
   POST /api/crm/chats/chat-abc-123/status
   {
     "status": "por_levantamiento",
     "scheduled_at": "2026-01-16T15:00:00-03:00",  // ← Cambió
     "location_text": "Av. Santa Fe 1234, CABA",
     "lat": -34.595454,
     "lng": -58.394344,
     "assigned_technician_id": "tech-juan-001",
     "service_id": "service-ac-install",
     "note": "Cliente pidió reprogramar para el día siguiente"  // ← Cambió
   }
   ```

### Resultado Esperado

✅ **NO se crea job duplicado**:
```sql
-- Solo debe existir 1 job activo de tipo LEVANTAMIENTO
SELECT COUNT(*) 
FROM operations_jobs 
WHERE crm_chat_id = 'chat-abc-123' 
  AND crm_task_type = 'LEVANTAMIENTO'
  AND status NOT IN ('cancelled', 'completed', 'closed');
-- Result: 1
```

✅ **Job existente se actualiza**:
```sql
SELECT * FROM operations_jobs WHERE id = 'job-lev-001';

id              | job-lev-001  (← MISMO ID)
scheduled_at    | 2026-01-16 15:00:00  (← Actualizado)
notes           | Cliente pidió reprogramar...  (← Actualizado)
updated_at      | 2026-01-10 16:00:00  (← Cambió)
```

✅ **Historial registra el cambio**:
```sql
SELECT * FROM operations_job_history WHERE job_id = 'job-lev-001';

id          | hist-001
action_type | crm_status
old_status  | pending_survey
new_status  | pending_survey
note        | CRM -> por_levantamiento (programado 2026-01-16T15:00:00)
created_at  | 2026-01-10 16:00:00
```

---

## 🎬 Caso 4: Cambio de Tipo de Servicio

### Situación
El cliente decidió que ya no necesita levantamiento, quiere agendar la instalación directamente.

### Pasos

1. **Estado actual**: job-lev-001 (LEVANTAMIENTO, pending_survey)

2. **Cambiar a servicio reservado**:
   ```json
   POST /api/crm/chats/chat-abc-123/status
   {
     "status": "servicio_reservado",  // ← Cambió de tipo
     "scheduled_at": "2026-01-18T09:00:00-03:00",
     "location_text": "Av. Santa Fe 1234, CABA",
     "lat": -34.595454,
     "lng": -58.394344,
     "assigned_technician_id": "tech-juan-001",
     "service_id": "service-ac-install",
     "note": "Cliente ya no quiere levantamiento, va directo a instalación"
   }
   ```

### Resultado Esperado

✅ **Job anterior se cancela**:
```sql
SELECT * FROM operations_jobs WHERE id = 'job-lev-001';

id          | job-lev-001
status      | cancelled  (← Cambió)
cancel_reason | Actualizado desde CRM: servicio_reservado
```

✅ **Nuevo job se crea del nuevo tipo**:
```sql
SELECT * FROM operations_jobs 
WHERE crm_chat_id = 'chat-abc-123' 
  AND status NOT IN ('cancelled');

id              | job-serv-002
crm_task_type   | SERVICIO_RESERVADO  (← Nuevo tipo)
status          | scheduled
scheduled_at    | 2026-01-18 09:00:00
```

✅ **En Operaciones**:
- "Levantamientos": ❌ No aparece (cancelado)
- "Instalaciones": ✅ Aparece el nuevo job
- "Agenda": ✅ Muestra fecha 18 de enero

---

## 🎬 Caso 5: Cliente con Problema (Garantía)

### Situación
Un cliente que ya compró reporta un problema con su equipo.

### Pasos

1. **En CRM**: Chat con +54 9 11 5555-1234
   - Display name: "Juan Pérez"
   - Estado actual: "compro"

2. **Cambiar a "garantía"**:
   ```json
   POST /api/crm/chats/chat-def-789/status
   {
     "status": "garantia",
     "problemDescription": "El equipo hace ruido extraño y no enfría bien. Cliente dice que empezó hace 2 días.",
     "assigned_technician_id": "tech-juan-001",
     "note": "Urgente: cliente necesita atención rápido por calor"
   }
   ```

### Resultado Esperado

✅ **Job de garantía creado**:
```sql
SELECT * FROM operations_jobs WHERE crm_chat_id = 'chat-def-789';

id              | job-gar-001
crm_task_type   | GARANTIA
status          | warranty_pending
service_type    | Garantía
```

✅ **Ticket de garantía creado**:
```sql
SELECT * FROM operations_warranty_tickets WHERE job_id = 'job-gar-001';

id              | ticket-001
job_id          | job-gar-001
reason          | El equipo hace ruido extraño y no enfría bien...
status          | pending
assigned_tech_id| tech-juan-001
reported_at     | 2026-01-10 17:00:00
```

✅ **Visible en Operaciones**:
- Pestaña "Garantías": ✅ Aparece
- Estado: "Pendiente"
- Descripción del problema visible

---

## 🎬 Caso 6: Múltiples Empresas (Aislamiento)

### Situación
Verificar que cada empresa solo ve sus propios datos.

### Pasos

1. **Empresa A** (empresa-123):
   - Chat: chat-abc-123
   - Cliente: customer-001
   - Job: job-lev-001

2. **Empresa B** (empresa-456):
   - Chat: chat-ghi-789
   - Cliente: customer-100
   - Job: job-lev-100

### Resultado Esperado

✅ **Usuario de Empresa A** (token-empresa-123):
```sql
-- Debe ver SOLO sus datos
GET /api/operations/jobs
Authorization: Bearer token-empresa-123

Response:
{
  "items": [
    { "id": "job-lev-001", "empresa_id": "empresa-123" }
    // NO incluye job-lev-100 de empresa B
  ]
}
```

✅ **Usuario de Empresa B** (token-empresa-456):
```sql
GET /api/operations/jobs
Authorization: Bearer token-empresa-456

Response:
{
  "items": [
    { "id": "job-lev-100", "empresa_id": "empresa-456" }
    // NO incluye job-lev-001 de empresa A
  ]
}
```

✅ **En base de datos**:
```sql
-- Verificar aislamiento
SELECT 
  oj.id, 
  oj.empresa_id, 
  cc.empresa_id as chat_empresa,
  c.empresa_id as customer_empresa
FROM operations_jobs oj
JOIN crm_chat cc ON oj.crm_chat_id = cc.id
JOIN customer c ON oj.crm_customer_id = c.id
WHERE oj.id IN ('job-lev-001', 'job-lev-100');

-- Resultado:
-- job-lev-001 | empresa-123 | empresa-123 | empresa-123  ✅
-- job-lev-100 | empresa-456 | empresa-456 | empresa-456  ✅
```

---

## 🎬 Caso 7: Estado Irreversible (COMPRO)

### Situación
Intentar cambiar el estado de un cliente que ya compró.

### Pasos

1. **En CRM**: Chat con estado "compro"

2. **Intentar cambiar a otro estado**:
   ```json
   POST /api/crm/chats/chat-compro/status
   {
     "status": "primer_contacto"  // ← Intento de revertir
   }
   ```

### Resultado Esperado

❌ **Request rechazado**:
```json
HTTP 422 Unprocessable Entity
{
  "error": "COMPRO is irreversible and cannot be reverted",
  "code": 422
}
```

✅ **Estado no cambia**:
```sql
SELECT status FROM crm_chat WHERE id = 'chat-compro';
-- Result: 'compro'  (← Sin cambios)
```

---

## 📊 Resumen de Verificaciones

| Caso | Descripción | Verificación Principal |
|------|-------------|------------------------|
| 1 | Cliente nuevo + levantamiento | Cliente se crea automáticamente |
| 2 | Cliente existente + servicio | Cliente NO se duplica |
| 3 | Actualizar fecha | Job se actualiza, NO duplica |
| 4 | Cambio de tipo servicio | Job anterior se cancela, nuevo se crea |
| 5 | Problema/Garantía | Ticket de garantía se crea |
| 6 | Múltiples empresas | Aislamiento por empresa_id |
| 7 | Estado irreversible | COMPRO no puede revertirse |

---

## 🧪 Ejecutar Pruebas

Para verificar todos estos casos automáticamente:

```bash
# Prueba automatizada completa
node test_crm_operations_flow.js admin@fulltech.com password123

# Prueba manual de un caso específico
# 1. Ir al CRM
# 2. Seleccionar un chat
# 3. Cambiar estado según el caso
# 4. Verificar en Operaciones

# Verificación SQL
psql -d fulltech_db -v chat_id='chat-abc-123' -v empresa_id='empresa-123' \
  -f fulltech_api/sql/verify_crm_operations_flow.sql
```

---

**Última actualización**: 2026-01-10  
**Versión**: 1.0
