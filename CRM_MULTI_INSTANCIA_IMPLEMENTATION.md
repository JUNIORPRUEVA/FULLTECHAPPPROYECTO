# CRM Multi-Instancia - Implementación Completa

## 📋 Resumen de la Implementación

Se ha implementado un sistema CRM completamente aislado por usuario, donde cada usuario puede configurar su propia instancia de Evolution API y todos los datos (chats, mensajes, operaciones) están completamente segregados por instancia.

---

## 🗂️ Cambios en Base de Datos

### 1. Nueva Tabla: `crm_instancias`

```sql
CREATE TABLE crm_instancias (
  id UUID PRIMARY KEY,
  empresa_id UUID REFERENCES empresas(id),
  user_id UUID REFERENCES users(id),
  nombre_instancia TEXT NOT NULL,
  evolution_base_url TEXT NOT NULL,
  evolution_api_key TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP(3) DEFAULT NOW(),
  updated_at TIMESTAMP(3) DEFAULT NOW()
);

-- Constraint: Solo una instancia activa por usuario
CREATE UNIQUE INDEX ON crm_instancias(user_id, is_active) WHERE is_active = TRUE;
```

### 2. Modificaciones en `crm_chats`

- ✅ `instancia_id UUID` - FK a crm_instancias
- ✅ `owner_user_id UUID` - Usuario propietario del chat
- ✅ `asignado_a_user_id UUID` - Usuario actualmente asignado
- ✅ UNIQUE INDEX sobre (instancia_id, wa_id) - Evita duplicados

### 3. Modificaciones en `crm_messages`

- ✅ `instancia_id UUID` - FK a crm_instancias (para auditoría)

### 4. Nueva Tabla: `crm_chat_transfer_events`

```sql
CREATE TABLE crm_chat_transfer_events (
  id UUID PRIMARY KEY,
  chat_id UUID REFERENCES crm_chats(id),
  from_user_id UUID REFERENCES users(id),
  to_user_id UUID REFERENCES users(id),
  from_instancia_id UUID REFERENCES crm_instancias(id),
  to_instancia_id UUID REFERENCES crm_instancias(id),
  notes TEXT,
  created_at TIMESTAMP(3) DEFAULT NOW()
);
```

---

## 🔧 Backend - Archivos Creados/Modificados

### Nuevos Archivos

1. **`sql/migrations/2026-01-10_add_crm_multi_instance.sql`**
   - Migración SQL completa
   - Crea tablas, índices, constraints
   - Migra datos existentes a instancia por defecto

2. **`src/modules/crm/crm_instances.schema.ts`**
   - Schemas de validación Zod
   - crmInstanceCreateSchema
   - crmInstanceUpdateSchema
   - crmChatTransferSchema

3. **`src/modules/crm/crm_instances.controller.ts`**
   - listInstances()
   - getActiveInstance()
   - createInstance()
   - updateInstance()
   - deleteInstance()
   - testConnection()
   - transferChat()
   - listUsersForTransfer()

### Archivos Modificados

1. **`src/modules/crm/crm.routes.ts`**
   - Añadidos endpoints de instancias:
     - GET /api/crm/instances
     - GET /api/crm/instances/active
     - POST /api/crm/instances
     - PATCH /api/crm/instances/:id
     - DELETE /api/crm/instances/:id
     - POST /api/crm/instances/test-connection
     - POST /api/crm/chats/:chatId/transfer
     - GET /api/crm/users/transfer-list

2. **`src/modules/webhooks/evolution_webhook.controller.ts`**
   - Detecta nombre de instancia del payload webhook
   - Busca instancia en BD por nombre
   - Asigna chat y mensajes a instancia correcta
   - Asigna owner_user_id y asignado_a_user_id automáticamente

3. **`src/modules/crm/crm_whatsapp.controller.ts`**
   - `listChats()`: Filtra solo chats de la instancia activa del usuario
   - `getChat()`: Verifica que el usuario tenga acceso al chat
   - `createAndSendTextForChat()`: 
     - Obtiene config de instancia del chat
     - Crea EvolutionClient con config específica
     - Envía mensaje desde instancia correcta

---

## 📱 Flutter - Archivos Creados

### Modelos

1. **`lib/features/crm/models/crm_instance.dart`**
   - `CrmInstance` class
   - `CrmTransferUser` class

### Repositorio

2. **`lib/features/crm/data/crm_instances_repository.dart`**
   - Métodos CRUD para instancias
   - transferChat()
   - listUsersForTransfer()
   - testConnection()

### Providers

3. **`lib/features/crm/state/crm_instances_providers.dart`**
   - crmInstancesListProvider
   - crmActiveInstanceProvider
   - crmTransferUsersProvider
   - createCrmInstanceProvider
   - updateCrmInstanceProvider
   - testCrmConnectionProvider
   - transferChatProvider

### Pantallas

4. **`lib/features/crm/screens/crm_instance_config_screen.dart`**
   - Formulario de configuración de instancia
   - Campos: nombre, base URL, API key
   - Botón "Probar Conexión"
   - Validaciones completas

### Widgets

5. **`lib/features/crm/widgets/transfer_chat_dialog.dart`**
   - Diálogo para transferir chats
   - Lista de usuarios disponibles con sus instancias
   - Campo de notas opcional
   - Confirmación visual

---

## 🚀 Pasos para Despliegue

### 1. Ejecutar Migración SQL

```bash
cd fulltech_api
npm run migrate:custom sql/migrations/2026-01-10_add_crm_multi_instance.sql
```

O ejecutar manualmente en la base de datos:

```bash
psql -h localhost -U postgres -d fulltech_db -f sql/migrations/2026-01-10_add_crm_multi_instance.sql
```

### 2. Verificar Migración

```sql
-- Verificar tablas creadas
SELECT COUNT(*) FROM crm_instancias;

-- Verificar columnas agregadas
SELECT instancia_id, owner_user_id, asignado_a_user_id 
FROM crm_chats 
LIMIT 5;
```

### 3. Compilar Backend

```bash
cd fulltech_api
npm run build
npm restart
```

### 4. Compilar Flutter

```bash
cd fulltech_app
flutter pub get
flutter build apk --release
# O para desarrollo:
flutter run
```

---

## 🧪 Plan de Pruebas

### Prueba 1: Configuración de Instancia

**Usuario A:**
1. ✅ Login como Usuario A
2. ✅ Ir a Configuración → CRM → Instancia Evolution
3. ✅ Ingresar:
   - Nombre: "agente_a"
   - URL: "https://evolution-api.com"
   - API Key: "KEY_USER_A"
4. ✅ Click "Probar Conexión" → debe mostrar éxito
5. ✅ Click "Guardar"

**Usuario B:**
1. ✅ Repetir pasos con Usuario B usando:
   - Nombre: "agente_b"
   - API Key: "KEY_USER_B"

### Prueba 2: Recepción de Chats (Webhook)

**Setup Webhook:**
- Configurar Evolution para Usuario A que envíe webhooks a:
  ```
  POST /webhooks/evolution
  Body: { "instance": "agente_a", ... }
  ```

**Test:**
1. ✅ Enviar mensaje desde WhatsApp al número de Usuario A
2. ✅ Verificar que el chat aparece en lista de Usuario A
3. ✅ Verificar que Usuario B NO ve ese chat

**Repetir con Usuario B:**
1. ✅ Enviar mensaje al número de Usuario B
2. ✅ Verificar aislamiento completo

### Prueba 3: Envío de Mensajes

**Usuario A:**
1. ✅ Abrir un chat en su lista
2. ✅ Enviar mensaje de texto
3. ✅ Verificar en logs que se usa config de instancia de Usuario A
4. ✅ Verificar que mensaje llega correctamente al cliente

### Prueba 4: Transferencia de Chat

**Transferir de A → B:**
1. ✅ Usuario A abre un chat
2. ✅ Click en menú → "Transferir"
3. ✅ Seleccionar Usuario B de la lista
4. ✅ Agregar nota: "Cliente solicita atencion de gerente"
5. ✅ Confirmar transferencia

**Verificaciones:**
1. ✅ Chat desaparece de lista de Usuario A
2. ✅ Chat aparece en lista de Usuario B
3. ✅ Usuario B puede ver historial completo
4. ✅ Usuario B puede responder
5. ✅ Respuestas se envían desde instancia de Usuario B

**Verificar BD:**
```sql
SELECT * FROM crm_chat_transfer_events 
WHERE chat_id = 'CHAT_ID'
ORDER BY created_at DESC;
```

### Prueba 5: Seguridad - Intento de Acceso Cruzado

**Via API:**
```bash
# Usuario A intenta acceder a chat de Usuario B
curl -X GET \
  http://api.com/crm/chats/CHAT_ID_DE_B \
  -H "Authorization: Bearer TOKEN_USER_A"

# Debe retornar: 403 Forbidden
```

### Prueba 6: Instancia Inactiva

1. ✅ Usuario A desactiva su instancia
2. ✅ Verificar que su lista de chats queda vacía
3. ✅ No puede enviar mensajes
4. ✅ Reactiva instancia → chats vuelven a aparecer

---

## 📊 Consultas de Verificación

### Distribución de Chats por Instancia

```sql
SELECT 
  i.nombre_instancia,
  u.username as owner,
  COUNT(c.id) as total_chats,
  COUNT(CASE WHEN c.status != 'eliminado' THEN 1 END) as chats_activos
FROM crm_instancias i
LEFT JOIN users u ON u.id = i.user_id
LEFT JOIN crm_chats c ON c.instancia_id = i.id
GROUP BY i.id, u.username
ORDER BY total_chats DESC;
```

### Chats Sin Instancia (debe ser 0)

```sql
SELECT COUNT(*) as orphaned_chats
FROM crm_chats
WHERE instancia_id IS NULL;
```

### Historial de Transferencias

```sql
SELECT 
  t.created_at,
  c.display_name as chat_name,
  uf.username as from_user,
  ut.username as to_user,
  if.nombre_instancia as from_instance,
  it.nombre_instancia as to_instance,
  t.notes
FROM crm_chat_transfer_events t
JOIN crm_chats c ON c.id = t.chat_id
LEFT JOIN users uf ON uf.id = t.from_user_id
JOIN users ut ON ut.id = t.to_user_id
LEFT JOIN crm_instancias if ON if.id = t.from_instancia_id
JOIN crm_instancias it ON it.id = t.to_instancia_id
ORDER BY t.created_at DESC
LIMIT 20;
```

---

## 🔒 Seguridad Implementada

### Backend

✅ **Scoping por Usuario**: Todos los endpoints filtran por instancia del usuario actual

✅ **Validación en Transferencias**: No se puede transferir un chat que no te pertenece

✅ **API Key Protegida**: Nunca se retorna en respuestas GET

✅ **Unique Constraints**: Previene duplicados de chats en misma instancia

### Frontend

✅ **Validaciones de Formulario**: Campos requeridos, formato URL, etc.

✅ **Confirmación de Acciones**: Dialog de confirmación para transferencias

✅ **Mensajes de Error Claros**: Feedback visual en todas las operaciones

---

## 🐛 Troubleshooting

### Problema: "Instance not found" en webhook

**Causa**: El payload del webhook no incluye el campo `instance`

**Solución**: 
1. Verificar configuración de Evolution API
2. Asegurarse de que el campo `instance` esté en el payload
3. Revisar logs: `[WEBHOOK] Instance matched: ...`

### Problema: Usuario no ve sus chats

**Causa**: Usuario no tiene instancia activa

**Solución**:
```sql
SELECT * FROM crm_instancias WHERE user_id = 'USER_ID' AND is_active = TRUE;
```
Si no hay resultado, usuario debe configurar instancia.

### Problema: Error al enviar mensaje

**Causa**: Instancia del chat no tiene configuración válida

**Solución**:
1. Verificar que el chat tenga `instancia_id`
2. Verificar que la instancia exista y esté activa
3. Verificar URL y API key de la instancia

---

## ✅ Checklist Final

### Base de Datos
- [ ] Migración ejecutada sin errores
- [ ] Tabla `crm_instancias` creada
- [ ] Columnas agregadas a `crm_chats`
- [ ] Columna agregada a `crm_messages`
- [ ] Tabla `crm_chat_transfer_events` creada
- [ ] Índices creados correctamente
- [ ] Datos existentes migrados

### Backend
- [ ] Endpoints de instancias funcionando
- [ ] Webhook detecta instancia correctamente
- [ ] `listChats` filtra por instancia
- [ ] `sendTextMessage` usa instancia del chat
- [ ] Transferencia funciona end-to-end

### Frontend
- [ ] Pantalla de configuración accesible
- [ ] Formulario guarda correctamente
- [ ] Test de conexión funciona
- [ ] Diálogo de transferencia muestra usuarios
- [ ] Transferencia actualiza UI

### Pruebas
- [ ] Usuario A y B configuran instancias
- [ ] Chats llegan a usuario correcto
- [ ] No hay cross-contamination
- [ ] Transferencias funcionan
- [ ] Mensajes se envían desde instancia correcta

---

## 📞 Soporte

Para preguntas o issues:
1. Revisar logs del backend: `docker logs fulltech-api`
2. Revisar logs de Flutter: `flutter logs`
3. Consultar tabla `crm_webhook_events` para debug de webhooks
4. Verificar tabla `crm_chat_transfer_events` para auditoría

---

**Implementado por:** GitHub Copilot  
**Fecha:** 2026-01-10  
**Estado:** ✅ Completo y listo para pruebas
