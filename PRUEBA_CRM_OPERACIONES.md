# Guía de Prueba: Flujo CRM → Operaciones

## 📋 Objetivo

Verificar que al marcar un chat en el CRM con estado **"agendado"** o **"por levantamiento"**, se cumplan los siguientes requisitos:

1. ✅ Se crea automáticamente el cliente si no existe
2. ✅ Se crea el registro en `operations_jobs` con toda la información
3. ✅ Se asocia correctamente con el chat (`crm_chat_id`)
4. ✅ Se crea el registro en `operations_schedule` para servicios agendados
5. ✅ Todo está en la sesión correcta (`empresa_id` del usuario logueado)
6. ✅ No se crean duplicados (idempotencia)

---

## 🚀 Método 1: Script Automatizado

### Prerequisitos

- Node.js instalado
- Backend corriendo en `http://localhost:3000` (o configurar `API_URL`)
- Al menos un chat disponible en CRM
- Al menos un servicio activo
- Al menos un técnico activo

### Ejecución

```bash
# Desde la raíz del proyecto
node test_crm_operations_flow.js <email> <password>

# Ejemplo:
node test_crm_operations_flow.js admin@fulltech.com password123
```

### Qué verifica el script

El script ejecuta 4 pruebas automáticas:

1. **Prueba 1**: Estado "por_levantamiento"
   - Cambia el estado de un chat a "por_levantamiento"
   - Verifica que se cree el cliente automáticamente
   - Verifica que se cree el job con tipo `LEVANTAMIENTO`
   - Verifica todos los campos requeridos

2. **Prueba 2**: Estado "servicio_reservado"
   - Cambia el estado a "servicio_reservado"
   - Verifica que se cree/actualice el job con tipo `SERVICIO_RESERVADO`
   - Verifica que se asocie el servicio correctamente

3. **Prueba 3**: Idempotencia
   - Cambia el estado varias veces al mismo tipo
   - Verifica que NO se creen duplicados
   - Solo debe existir 1 job activo del mismo tipo

4. **Prueba 4**: Sesión correcta
   - Verifica que todos los jobs tengan el `empresa_id` correcto
   - Confirma que el usuario solo ve sus propios datos

### Output Esperado

```
╔═══════════════════════════════════════════════════════════╗
║  PRUEBA DE FLUJO CRM → OPERACIONES                        ║
║  Verificación de creación de clientes y jobs              ║
╚═══════════════════════════════════════════════════════════╝

ℹ Intentando login con: admin@fulltech.com
✓ Login exitoso
ℹ Usuario: Admin User (admin)
ℹ Empresa ID: empresa-123

ℹ Buscando chat de prueba existente...
✓ Usando chat existente: chat-456 (Test User)
ℹ Obteniendo servicios disponibles...
✓ Encontrados 3 servicios
ℹ Obteniendo técnicos disponibles...
✓ Encontrados 2 técnicos

📋 Recursos para pruebas:
ℹ   Chat: Test User (chat-456)
ℹ   Servicio: Instalación AC (service-789)
ℹ   Técnico: Juan Pérez (tech-123)

═══════════════════════════════════════════════
PRUEBA 1: Estado "por_levantamiento"
═══════════════════════════════════════════════
ℹ Cambiando estado del chat a: por_levantamiento
✓ Estado cambiado exitosamente
✓ Job creado con ID: job-001
ℹ Verificando que se creó el cliente con teléfono: +541123456789
✓ Cliente encontrado: Test User (ID: customer-123)
ℹ Verificando job de operaciones para chat chat-456...
✓ Job encontrado: ID job-001

  Verificaciones del job:
✓     Tipo de tarea: LEVANTAMIENTO
✓     Chat ID: chat-456
✓     Cliente ID: customer-123
✓     Nombre cliente: Test User
✓     Teléfono cliente: +541123456789
✓     Fecha programada: 2026-01-11T12:00:00.000Z
✓     Ubicación: Calle Test 123, Ciudad Test
✓     Técnico asignado correctamente: Juan Pérez

✓ PRUEBA 1 COMPLETADA EXITOSAMENTE

[... más pruebas ...]

╔═══════════════════════════════════════════════════════════╗
║  RESUMEN DE PRUEBAS                                        ║
╚═══════════════════════════════════════════════════════════╝

Pruebas exitosas: 4/4

🎉 TODAS LAS PRUEBAS PASARON EXITOSAMENTE
```

---

## 🧪 Método 2: Pruebas Manuales

### Paso 1: Preparación

1. Asegúrate de tener el backend corriendo
2. Accede a la aplicación móvil o web
3. Inicia sesión con tu cuenta

### Paso 2: Verificar recursos

1. **Servicios**: Ve a Configuración → Servicios
   - Debe haber al menos 1 servicio activo
   - Si no hay, crea uno nuevo

2. **Técnicos**: Ve a Usuarios
   - Debe haber al menos 1 usuario con rol "Técnico"
   - Si no hay, crea uno nuevo

3. **Chat de prueba**: Ve al CRM
   - Debe haber al menos 1 chat
   - El chat NO debe estar en estado "compró" (irreversible)
   - Si no hay, envía un mensaje de WhatsApp al número configurado

### Paso 3: Prueba "Por Levantamiento"

1. Ve al CRM y selecciona un chat
2. Cambia el estado a **"Por levantamiento"**
3. Completa el formulario:
   - **Fecha/Hora**: Selecciona una fecha futura
   - **Ubicación**: Escribe una dirección
   - **Coordenadas**: Opcional (puedes dejarlas en 0 o usar el mapa)
   - **Técnico**: Selecciona un técnico
   - **Servicio**: Selecciona un servicio
   - **Nota**: (Opcional) Agrega una nota
4. Guarda los cambios

### Paso 4: Verificar creación en Operaciones

1. Ve al módulo **Operaciones**
2. Selecciona la pestaña **"Levantamientos"** o **"Agenda"**
3. Verifica que aparezca el nuevo job:
   - ✅ Debe mostrar el nombre del cliente
   - ✅ Debe mostrar el teléfono del chat
   - ✅ Debe mostrar la fecha programada
   - ✅ Debe mostrar el técnico asignado
   - ✅ Debe mostrar el servicio asociado
   - ✅ El estado debe ser "Pendiente de levantamiento"

### Paso 5: Verificar el cliente

1. Ve al módulo **Clientes**
2. Busca el teléfono del chat
3. Verifica que el cliente fue creado automáticamente:
   - ✅ Nombre del cliente (del WhatsApp o "Cliente WhatsApp +...")
   - ✅ Teléfono correcto
   - ✅ Origen: "whatsapp"

### Paso 6: Prueba "Servicio Reservado"

1. Vuelve al mismo chat en el CRM
2. Cambia el estado a **"Servicio reservado"** (o usa el alias "agendado")
3. Completa el formulario (igual que el anterior)
4. Guarda los cambios

### Paso 7: Verificar actualización

1. Ve a Operaciones → Agenda
2. Verifica que el job se **actualizó** (no duplicó):
   - ✅ El job anterior de "levantamiento" debe estar cancelado o actualizado
   - ✅ Solo debe existir 1 job activo del tipo "SERVICIO_RESERVADO"
   - ✅ La información debe estar actualizada

### Paso 8: Prueba de idempotencia

1. Sin cambiar nada, vuelve a cambiar el estado a "servicio_reservado"
2. Modifica solo la nota o la fecha
3. Guarda los cambios
4. Ve a Operaciones y verifica:
   - ✅ NO se creó un job duplicado
   - ✅ El job existente se actualizó con la nueva información

---

## 🔍 Verificación en Base de Datos (Opcional)

Si tienes acceso directo a la base de datos, puedes verificar manualmente:

```sql
-- 1. Verificar que el cliente fue creado
SELECT id, nombre, telefono, origen, empresa_id 
FROM customer 
WHERE telefono LIKE '%{últimos_4_dígitos}%'
AND deleted_at IS NULL;

-- 2. Verificar el job de operaciones
SELECT 
  id,
  crm_chat_id,
  crm_customer_id,
  crm_task_type,
  customer_name,
  customer_phone,
  scheduled_at,
  location_text,
  assigned_tech_id,
  service_id,
  status,
  empresa_id
FROM operations_jobs
WHERE crm_chat_id = '{chat_id}'
AND deleted_at IS NULL
ORDER BY created_at DESC;

-- 3. Verificar el schedule (para servicios agendados)
SELECT 
  id,
  job_id,
  scheduled_date,
  preferred_time,
  assigned_tech_id
FROM operations_schedule
WHERE job_id IN (
  SELECT id FROM operations_jobs 
  WHERE crm_chat_id = '{chat_id}'
  AND deleted_at IS NULL
);

-- 4. Verificar historial
SELECT 
  id,
  job_id,
  action_type,
  old_status,
  new_status,
  note,
  created_at
FROM operations_job_history
WHERE job_id IN (
  SELECT id FROM operations_jobs 
  WHERE crm_chat_id = '{chat_id}'
)
ORDER BY created_at DESC;
```

---

## ✅ Checklist de Verificación

Marca cada item después de verificarlo:

### Creación de Cliente
- [ ] El cliente se crea automáticamente si no existe
- [ ] El nombre del cliente viene del WhatsApp
- [ ] El teléfono está en formato correcto
- [ ] El origen es "whatsapp"
- [ ] El `empresa_id` es correcto

### Creación de Job
- [ ] Se crea el job en `operations_jobs`
- [ ] El `crm_chat_id` apunta al chat correcto
- [ ] El `crm_customer_id` apunta al cliente creado
- [ ] El `crm_task_type` es correcto (LEVANTAMIENTO o SERVICIO_RESERVADO)
- [ ] El estado inicial es correcto
- [ ] Todos los campos requeridos están presentes:
  - [ ] `scheduled_at`
  - [ ] `location_text`
  - [ ] `assigned_tech_id`
  - [ ] `service_id`

### Schedule (solo para servicios agendados)
- [ ] Se crea registro en `operations_schedule`
- [ ] La fecha está correcta
- [ ] La hora está correcta
- [ ] El técnico está asignado

### Idempotencia
- [ ] Al cambiar el estado varias veces al mismo tipo, NO se duplica
- [ ] Solo existe 1 job activo del mismo tipo para el mismo chat
- [ ] Los jobs anteriores de otros tipos se cancelan

### Sesión/Empresa
- [ ] El `empresa_id` del job coincide con el del usuario logueado
- [ ] El usuario solo ve jobs de su empresa
- [ ] No hay "cross-contamination" entre empresas

### Historial
- [ ] Se crea entrada en `operations_job_history`
- [ ] El historial muestra correctamente el cambio de estado

---

## 🐛 Problemas Comunes

### Error: "scheduled_at is required"
- **Causa**: Falta fecha/hora en el formulario
- **Solución**: Asegúrate de llenar todos los campos requeridos

### Error: "service_id is invalid"
- **Causa**: El servicio no existe o está inactivo
- **Solución**: Ve a Configuración → Servicios y activa al menos uno

### Error: "assigned_tech_id is invalid"
- **Causa**: El técnico no existe
- **Solución**: Crea un usuario con rol "Técnico"

### No se ve el job en Operaciones
- **Causa 1**: El job fue creado pero con filtros activos
- **Solución**: Limpia los filtros en la vista de Operaciones

- **Causa 2**: Error al crear el job
- **Solución**: Revisa los logs del backend

### Se crearon jobs duplicados
- **Causa**: Bug en la lógica de upsert
- **Solución**: Contacta al desarrollador, esto no debería pasar

---

## 📊 Métricas de Éxito

El sistema funciona correctamente si:

1. ✅ **100% de los chats** con estado "por_levantamiento" o "servicio_reservado" crean un job
2. ✅ **100% de los jobs** están asociados al cliente correcto
3. ✅ **0% de duplicados** en jobs activos del mismo tipo para el mismo chat
4. ✅ **100% de la información** se preserva correctamente (nombre, teléfono, fecha, técnico, etc.)
5. ✅ **100% de las sesiones** están aisladas por `empresa_id`

---

## 📞 Soporte

Si encuentras algún problema durante las pruebas:

1. Verifica los logs del backend: `fulltech_api/logs/`
2. Revisa el checklist de verificación
3. Ejecuta el script automatizado para diagnóstico detallado
4. Documenta el error con capturas de pantalla

---

## 🔄 Versión

- **Documento**: v1.0
- **Fecha**: 2026-01-10
- **Autor**: Sistema de pruebas automatizadas
