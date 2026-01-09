# ✅ Lista de Verificación - Servicios y Agenda

## 🎯 Objetivo
Verificar que toda la implementación de Servicios y Agenda funciona correctamente end-to-end.

---

## 📋 Pre-requisitos

- [ ] Backend corriendo en puerto 3000 (o configurado)
- [ ] Base de datos PostgreSQL accesible
- [ ] Flutter app compilada y corriendo
- [ ] Usuario autenticado en la app
- [ ] Empresa activa con usuarios técnicos

---

## 🔧 FASE 1: Backend - Migraciones

### 1.1 Verificar Migraciones SQL
```bash
cd fulltech_api

# Listar archivos de migración
ls sql/ | grep 20260108

# Deberías ver:
# 20260108000001_create_services_table.sql
# 20260108000002_create_agenda_items_table.sql
```

- [ ] Archivos de migración existen
- [ ] Contienen CREATE TABLE services
- [ ] Contienen CREATE TABLE agenda_items
- [ ] Contienen CREATE TYPE AgendaItemType

### 1.2 Aplicar Migraciones
```bash
npx prisma migrate dev
```

**Resultado esperado:**
```
✔ Generated Prisma Client
✔ The migration(s) have been applied
```

- [ ] Migraciones aplicadas sin errores
- [ ] Prisma Client regenerado

### 1.3 Verificar Tablas en PostgreSQL
```sql
-- En tu cliente PostgreSQL
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('services', 'agenda_items');

-- Verificar columnas de services
\d services

-- Verificar columnas de agenda_items
\d agenda_items

-- Verificar tipo enum
SELECT enum_range(NULL::AgendaItemType);
```

- [ ] Tabla `services` existe
- [ ] Tabla `agenda_items` existe
- [ ] Tipo `AgendaItemType` existe con 4 valores

---

## 🌐 FASE 2: Backend - API Endpoints

### 2.1 Servicios - Listar (vacío)
```bash
curl -X GET "http://localhost:3000/api/services" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Resultado esperado:**
```json
{
  "services": [],
  "total": 0
}
```

- [ ] Status 200
- [ ] Array vacío (si no hay servicios)

### 2.2 Servicios - Crear
```bash
curl -X POST http://localhost:3000/api/services \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Instalación de Aires",
    "description": "Instalación completa de aire acondicionado",
    "default_price": 150.00
  }'
```

**Resultado esperado:**
```json
{
  "service": {
    "id": "uuid-aqui",
    "empresa_id": "uuid-empresa",
    "name": "Instalación de Aires",
    "description": "Instalación completa de aire acondicionado",
    "default_price": 150.00,
    "is_active": true,
    "created_at": "2026-01-08T...",
    "updated_at": "2026-01-08T..."
  }
}
```

- [ ] Status 201
- [ ] Servicio creado con ID
- [ ] is_active = true por defecto

### 2.3 Servicios - Listar (con datos)
```bash
curl -X GET "http://localhost:3000/api/services?is_active=true" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

- [ ] Status 200
- [ ] Array con al menos 1 servicio
- [ ] Filtro is_active funciona

### 2.4 Servicios - Obtener por ID
```bash
curl -X GET "http://localhost:3000/api/services/UUID_DEL_SERVICIO" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

- [ ] Status 200
- [ ] Devuelve el servicio correcto

### 2.5 Servicios - Actualizar
```bash
curl -X PUT "http://localhost:3000/api/services/UUID_DEL_SERVICIO" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Instalación de Aires (Actualizado)",
    "default_price": 175.00
  }'
```

- [ ] Status 200
- [ ] Campos actualizados correctamente

### 2.6 Servicios - Eliminar (soft delete)
```bash
curl -X DELETE "http://localhost:3000/api/services/UUID_DEL_SERVICIO" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

- [ ] Status 200
- [ ] Servicio marcado como is_active = false
- [ ] No aparece en listado con is_active=true

### 2.7 Agenda - Crear Item
```bash
curl -X POST http://localhost:3000/api/operations/agenda \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "SERVICIO_RESERVADO",
    "service_id": "UUID_DEL_SERVICIO",
    "assigned_tech_id": "UUID_DEL_TECNICO",
    "scheduled_date": "2026-01-15",
    "scheduled_time": "10:00",
    "customer_name": "Juan Pérez",
    "customer_phone": "809-555-1234",
    "location": "Calle Principal #123"
  }'
```

- [ ] Status 201
- [ ] Agenda item creado
- [ ] Relaciones cargadas (service, technician)

### 2.8 Agenda - Listar con Filtros
```bash
# Por tipo
curl -X GET "http://localhost:3000/api/operations/agenda?type=SERVICIO_RESERVADO" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Por técnico
curl -X GET "http://localhost:3000/api/operations/agenda?tech_id=UUID_TECNICO" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Por rango de fechas
curl -X GET "http://localhost:3000/api/operations/agenda?from=2026-01-01&to=2026-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

- [ ] Filtro por type funciona
- [ ] Filtro por tech_id funciona
- [ ] Filtro por rango de fechas funciona
- [ ] Includes trae service y technician

---

## 📱 FASE 3: Flutter - Local Database

### 3.1 Verificar Schema Version
```dart
// En local_db_io.dart
static const _schemaVersion = 11;
```

- [ ] Schema version es 11

### 3.2 Instalar/Actualizar App
```bash
cd fulltech_app

# Desinstalar app completamente (para onCreate)
flutter clean

# Reinstalar
flutter run
```

**Al iniciar, verificar logs:**
```
Opening database at: /path/to/fulltech_app.db
Database version: 11
onCreate executed
```

- [ ] Database version = 11
- [ ] onCreate o onUpgrade ejecutado

### 3.3 Verificar Tablas Locales
Usar DB Browser for SQLite o similar:

```sql
SELECT name FROM sqlite_master WHERE type='table' AND name IN ('services', 'agenda_items');
```

- [ ] Tabla `services` existe
- [ ] Tabla `agenda_items` existe
- [ ] Columnas correctas en ambas tablas

---

## 🎨 FASE 4: Flutter - Services Module

### 4.1 Navegación a Servicios
1. Abrir app
2. Ir al menú
3. Buscar "Servicios" o "Operaciones → Servicios"

- [ ] Pantalla de servicios abre correctamente

### 4.2 Lista Vacía
Si no hay servicios:
- [ ] Muestra icono grande de herramienta
- [ ] Muestra mensaje "No hay servicios registrados"
- [ ] Botón FAB (+) visible

### 4.3 Crear Servicio Online
1. Presionar botón **+**
2. Completar formulario:
   - Nombre: "Test Servicio 1"
   - Descripción: "Descripción de prueba"
   - Precio: 100.00
   - Activo: ✅
3. Presionar "Crear Servicio"

**Resultado esperado:**
- [ ] Loading indicator aparece
- [ ] Mensaje "Servicio creado exitosamente"
- [ ] Navegación de regreso a lista
- [ ] Servicio aparece en la lista

### 4.4 Crear Servicio Offline
1. Desactivar WiFi/datos
2. Presionar botón **+**
3. Crear servicio "Test Offline"
4. Guardar

**Resultado esperado:**
- [ ] Servicio se guarda localmente
- [ ] Aparece en la lista con indicador de sync pendiente (si existe)
- [ ] Cuando regresa red, se sincroniza automáticamente

### 4.5 Editar Servicio
1. Presionar icono "Editar" en un servicio
2. Cambiar nombre a "Test Editado"
3. Cambiar precio a 125.00
4. Desactivar toggle "Activo"
5. Guardar

**Resultado esperado:**
- [ ] Cambios guardados
- [ ] Lista se actualiza
- [ ] Servicio muestra estado "Inactivo"
- [ ] Aparece tachado si está inactivo

### 4.6 Eliminar Servicio
1. Presionar icono "Eliminar"
2. Confirmar en diálogo

**Resultado esperado:**
- [ ] Diálogo de confirmación aparece
- [ ] Al confirmar, servicio se elimina
- [ ] Mensaje "Servicio eliminado"
- [ ] Desaparece de la lista

### 4.7 Refresh Manual
1. Pull to refresh en la lista
2. O presionar botón refresh en toolbar

**Resultado esperado:**
- [ ] Loading indicator aparece
- [ ] Lista se actualiza desde backend
- [ ] Servicios remotos aparecen

---

## 🔄 FASE 5: Integración CRM - Dropdowns

### 5.1 Preparación
- Crear al menos 2 servicios activos
- Verificar que hay usuarios con rol técnico

### 5.2 Servicio Reservado Dialog
1. Ir a CRM
2. Abrir un chat
3. Cambiar status a "Servicio reservado"

**Verificar en dialog:**
- [ ] Dropdown "Servicio" aparece
- [ ] Lista servicios activos
- [ ] Opción "-- Sin servicio --" presente
- [ ] Al seleccionar servicio, campo "Tipo de servicio" se auto-completa
- [ ] Dropdown "Técnico asignado" aparece
- [ ] Lista técnicos disponibles
- [ ] Opción "-- Sin asignar --" presente

### 5.3 Guardar Servicio Reservado
1. Seleccionar:
   - Fecha: Mañana
   - Hora: 10:00 AM
   - Servicio: "Instalación de Aires"
   - Técnico: (seleccionar uno)
   - Ubicación: "Calle Principal #123"
2. Guardar

**Verificar:**
- [ ] Dialog se cierra
- [ ] No hay errores
- [ ] Status del chat cambia a "Servicio reservado"
- [ ] (Backend) Se crea registro en agenda_items con service_id y assigned_tech_id

### 5.4 Solución Garantía Dialog
1. Cambiar status a "Solución de garantía"

**Verificar en dialog:**
- [ ] Dropdown "Técnico responsable" aparece
- [ ] Lista técnicos disponibles
- [ ] Se puede seleccionar técnico
- [ ] Al guardar, se guarda tecnico_id

### 5.5 Garantía Dialog
Similar a Solución Garantía:
- [ ] Sin dropdowns (solo campos de texto por ahora, OK)

### 5.6 Reserva Dialog
- [ ] Sin dropdowns de servicio/técnico (opcional para v2)

---

## 🔍 FASE 6: Verificación de Datos

### 6.1 Backend Database
```sql
-- Verificar servicios creados
SELECT id, name, is_active FROM services WHERE empresa_id = 'UUID_TU_EMPRESA';

-- Verificar agenda items
SELECT 
  id, 
  type, 
  scheduled_date, 
  service_id, 
  assigned_tech_id,
  customer_name
FROM agenda_items 
WHERE empresa_id = 'UUID_TU_EMPRESA';
```

- [ ] Servicios en DB coinciden con app
- [ ] Agenda items tienen service_id y assigned_tech_id correctos

### 6.2 Flutter Local Database
```sql
-- Usando DB Browser for SQLite
SELECT * FROM services;
SELECT * FROM agenda_items;
```

- [ ] Datos locales coinciden con backend
- [ ] sync_status = 'synced' para items sincronizados

---

## 🚨 FASE 7: Manejo de Errores

### 7.1 Sin Red - Crear Servicio
1. Desactivar red
2. Crear servicio

- [ ] Se guarda localmente
- [ ] Aparece en sync queue
- [ ] Cuando regresa red, se sincroniza

### 7.2 Backend Caído
1. Detener backend
2. Intentar crear servicio

- [ ] Guarda localmente
- [ ] No muestra error fatal
- [ ] Se sincroniza cuando backend regresa

### 7.3 Validaciones
1. Intentar crear servicio sin nombre

- [ ] Muestra error "El nombre es requerido"
- [ ] No permite guardar

2. Intentar poner precio negativo

- [ ] Muestra error "Ingrese un precio válido"

### 7.4 Dropdowns Vacíos
1. Si no hay servicios activos:

- [ ] Dropdown muestra solo "-- Sin servicio --"

2. Si no hay técnicos:

- [ ] Dropdown muestra solo "-- Sin asignar --"

---

## 📊 FASE 8: Performance

### 8.1 Carga de Lista
1. Con 50+ servicios en DB

- [ ] Lista carga en < 2 segundos
- [ ] Scroll fluido
- [ ] No hay lag

### 8.2 Búsqueda
1. Usar función de búsqueda (si existe)

- [ ] Búsqueda responde instantáneamente
- [ ] Filtra por nombre y descripción

### 8.3 Sync
1. Crear 10 servicios offline
2. Activar red

- [ ] Sync queue procesa todos
- [ ] No hay duplicados
- [ ] Todos llegan al backend

---

## ✅ CHECKLIST FINAL

### Backend
- [ ] Migraciones aplicadas
- [ ] Tablas creadas (services, agenda_items)
- [ ] Tipo enum AgendaItemType creado
- [ ] Endpoints services funcionan (CRUD)
- [ ] Endpoints agenda funcionan (CRUD)
- [ ] Filtros funcionan (is_active, type, tech_id, dates)
- [ ] Validaciones Zod funcionan
- [ ] Multi-tenant funciona (empresa_id)
- [ ] Logs sin errores

### Frontend
- [ ] Schema version 11
- [ ] Tablas locales creadas
- [ ] Services module funciona completo
- [ ] Offline-first funciona
- [ ] Sync queue funciona
- [ ] Dropdowns en CRM funcionan
- [ ] Validaciones UI funcionan
- [ ] No hay errores de compilación
- [ ] No hay crashes

### Integración
- [ ] CRM dialogs usan dropdowns
- [ ] service_id se guarda correctamente
- [ ] assigned_tech_id se guarda correctamente
- [ ] Datos fluyen: CRM → Agenda
- [ ] Sync bidireccional funciona

---

## 🎉 RESULTADO ESPERADO

Al completar todas las verificaciones:

✅ **Backend**: API REST funcional con 10 endpoints  
✅ **Frontend**: Módulo services completo  
✅ **Database**: PostgreSQL + SQLite sincronizados  
✅ **CRM**: Dropdowns integrados  
✅ **Sync**: Offline-first funcionando  

---

## 📝 Notas

**Pendientes para v2:**
- [ ] Agenda Page UI (visualización calendario)
- [ ] Filtros avanzados en Agenda
- [ ] Notificaciones push para citas
- [ ] Integración con calendario del sistema
- [ ] Reportes de servicios por técnico

**Documentos relacionados:**
- SERVICES_AGENDA_IMPLEMENTATION.md
- QUICK_START_SERVICES_AGENDA.md
- TESTING_GUIDE.md

---

**Fecha**: 2026-01-08  
**Versión**: 1.0  
**Estado**: ✅ Implementación completa
