# 🚀 CRM Multi-Instancia - Guía Rápida de Integración

## ⚡ Inicio Rápido

### 1. Ejecutar Migración (Backend)

```bash
cd fulltech_api

# Opción A: Via npm script (si existe)
npm run migrate:custom sql/migrations/2026-01-10_add_crm_multi_instance.sql

# Opción B: Via psql directo
psql -h localhost -U postgres -d fulltech_db -f sql/migrations/2026-01-10_add_crm_multi_instance.sql
```

### 2. Reiniciar Backend

```bash
npm run build
npm restart
# O si usas PM2:
pm2 restart fulltech-api
```

### 3. Verificar Endpoints

```bash
# Obtener token primero (login)
TOKEN="tu_token_aqui"

# Test de endpoints
curl -X GET http://localhost:3000/api/crm/instances \
  -H "Authorization: Bearer $TOKEN"

# Debería retornar: { "items": [] } si no hay instancias
```

### 4. Configurar Instancia (Primera Vez)

#### Via API:

```bash
curl -X POST http://localhost:3000/api/crm/instances \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre_instancia": "mi_instancia",
    "evolution_base_url": "https://tu-evolution-api.com",
    "evolution_api_key": "TU_API_KEY"
  }'
```

#### Via Flutter UI:

1. Login con tu usuario
2. Ir a: **Configuración → CRM → Instancia Evolution**
3. Completar formulario:
   - **Nombre**: `mi_instancia`
   - **URL**: `https://tu-evolution-api.com`
   - **API Key**: Tu clave
4. Click **"Probar Conexión"** (opcional)
5. Click **"Guardar"**

---

## 🔗 Configurar Webhook de Evolution

### Importante: Campo `instance` es OBLIGATORIO

Tu webhook de Evolution debe incluir el campo `instance` en el payload:

```json
{
  "instance": "mi_instancia",
  "event": "messages.upsert",
  "data": {
    "key": {
      "remoteJid": "1234567890@s.whatsapp.net",
      ...
    },
    "message": {
      ...
    }
  }
}
```

### Configurar en Evolution:

```bash
curl -X POST https://tu-evolution-api.com/instance/mi_instancia/webhook \
  -H "apikey: TU_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "webhook": {
      "url": "https://tu-backend.com/webhooks/evolution",
      "webhook_by_events": false,
      "enabled": true
    }
  }'
```

---

## 🧪 Pruebas Básicas

### Test 1: Configurar 2 Usuarios

**Terminal 1 (Usuario A):**
```bash
# Login como Usuario A
TOKEN_A="token_usuario_a"

# Crear instancia
curl -X POST http://localhost:3000/api/crm/instances \
  -H "Authorization: Bearer $TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre_instancia": "agente_a",
    "evolution_base_url": "https://evolution-api.com",
    "evolution_api_key": "KEY_A"
  }'
```

**Terminal 2 (Usuario B):**
```bash
# Login como Usuario B
TOKEN_B="token_usuario_b"

# Crear instancia
curl -X POST http://localhost:3000/api/crm/instances \
  -H "Authorization: Bearer $TOKEN_B" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre_instancia": "agente_b",
    "evolution_base_url": "https://evolution-api.com",
    "evolution_api_key": "KEY_B"
  }'
```

### Test 2: Simular Webhook

```bash
# Simular mensaje para Usuario A
curl -X POST http://localhost:3000/webhooks/evolution \
  -H "Content-Type: application/json" \
  -d '{
    "instance": "agente_a",
    "event": "messages.upsert",
    "data": {
      "key": {
        "remoteJid": "1234567890@s.whatsapp.net",
        "fromMe": false,
        "id": "MSG123"
      },
      "message": {
        "conversation": "Hola, necesito ayuda"
      },
      "messageTimestamp": 1234567890,
      "pushName": "Cliente Test"
    }
  }'
```

### Test 3: Verificar Aislamiento

```bash
# Usuario A ve sus chats
curl -X GET "http://localhost:3000/api/crm/chats?limit=10" \
  -H "Authorization: Bearer $TOKEN_A"

# Usuario B NO debe ver chats de A
curl -X GET "http://localhost:3000/api/crm/chats?limit=10" \
  -H "Authorization: Bearer $TOKEN_B"

# Debe retornar listas diferentes
```

### Test 4: Transferir Chat

```bash
# 1. Obtener lista de usuarios para transferir
curl -X GET http://localhost:3000/api/crm/users/transfer-list \
  -H "Authorization: Bearer $TOKEN_A"

# 2. Transferir chat (Usuario A → Usuario B)
curl -X POST http://localhost:3000/api/crm/chats/CHAT_ID/transfer \
  -H "Authorization: Bearer $TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{
    "toUserId": "USER_B_ID",
    "notes": "Cliente solicitó gerente"
  }'

# 3. Verificar: chat desaparece de A y aparece en B
curl -X GET http://localhost:3000/api/crm/chats?limit=10 \
  -H "Authorization: Bearer $TOKEN_A"
# No debe incluir el chat transferido

curl -X GET http://localhost:3000/api/crm/chats?limit=10 \
  -H "Authorization: Bearer $TOKEN_B"
# Debe incluir el chat transferido
```

---

## 📱 Integración en Flutter

### Agregar Rutas

En tu archivo de rutas (`app_routes.dart` o similar):

```dart
GoRoute(
  path: '/crm/instance-config',
  builder: (context, state) => const CrmInstanceConfigScreen(),
),
```

### Agregar Botón en Configuración

En tu pantalla de configuración del CRM:

```dart
ListTile(
  leading: const Icon(Icons.settings_input_antenna),
  title: const Text('Configurar Instancia Evolution'),
  subtitle: const Text('Mi instancia personal de WhatsApp'),
  trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () => context.go('/crm/instance-config'),
),
```

### Agregar Botón de Transferencia en Chat

En tu pantalla de detalle de chat:

```dart
IconButton(
  icon: const Icon(Icons.swap_horiz),
  tooltip: 'Transferir chat',
  onPressed: () async {
    final result = await showTransferChatDialog(
      context,
      chatId: chatId,
      chatDisplayName: chat.displayName ?? 'Cliente',
    );
    
    if (result == true) {
      // Refresh chat list
      ref.invalidate(crmChatsProvider);
    }
  },
),
```

---

## 🔍 Verificación de Funcionamiento

### Consultas SQL Útiles

```sql
-- Ver todas las instancias
SELECT 
  i.nombre_instancia,
  u.username,
  i.is_active,
  COUNT(c.id) as total_chats
FROM crm_instancias i
LEFT JOIN users u ON u.id = i.user_id
LEFT JOIN crm_chats c ON c.instancia_id = i.id
GROUP BY i.id, u.username;

-- Ver distribución de chats
SELECT 
  i.nombre_instancia,
  COUNT(*) as chats
FROM crm_chats c
JOIN crm_instancias i ON i.id = c.instancia_id
GROUP BY i.nombre_instancia;

-- Chats sin instancia (debe ser 0)
SELECT COUNT(*) FROM crm_chats WHERE instancia_id IS NULL;

-- Historial de transferencias
SELECT 
  t.created_at,
  uf.username as desde,
  ut.username as hacia,
  t.notes
FROM crm_chat_transfer_events t
LEFT JOIN users uf ON uf.id = t.from_user_id
JOIN users ut ON ut.id = t.to_user_id
ORDER BY t.created_at DESC
LIMIT 10;
```

### Logs del Backend

```bash
# Ver logs en tiempo real
tail -f /var/log/fulltech-api.log

# O con PM2:
pm2 logs fulltech-api --lines 100

# Buscar logs de webhook
grep "WEBHOOK" /var/log/fulltech-api.log | tail -20

# Buscar logs de instancia
grep "Instance matched" /var/log/fulltech-api.log | tail -20
```

---

## ⚠️ Troubleshooting Común

### Problema: "No instance found" en logs

**Causa**: Webhook no incluye campo `instance`

**Solución**:
1. Verificar payload del webhook en tabla `crm_webhook_events`
2. Añadir campo `instance` en configuración de Evolution
3. Si Evolution no lo envía, modificar webhook controller para extraerlo de otra parte

### Problema: Usuario no ve chats

**Causa**: No tiene instancia activa

**Solución**:
```sql
SELECT * FROM crm_instancias WHERE user_id = 'USER_ID';
-- Si no hay resultado, crear instancia via UI o API
```

### Problema: Error al enviar mensajes

**Causa**: Config de instancia inválida

**Solución**:
1. Verificar URL y API Key en BD
2. Probar conexión desde UI
3. Revisar logs de Evolution API

---

## 📚 Archivos Importantes

```
fulltech_api/
├── sql/migrations/2026-01-10_add_crm_multi_instance.sql  # Migración principal
├── src/modules/crm/
│   ├── crm_instances.controller.ts                       # Lógica de instancias
│   ├── crm_instances.schema.ts                          # Validaciones
│   └── crm.routes.ts                                    # Rutas actualizadas
├── src/modules/webhooks/
│   └── evolution_webhook.controller.ts                   # Webhook con instancias
└── test_crm_instances.js                                # Script de prueba

fulltech_app/
└── lib/features/crm/
    ├── models/crm_instance.dart                          # Modelos
    ├── data/crm_instances_repository.dart                # Repositorio
    ├── state/crm_instances_providers.dart                # Providers
    ├── screens/crm_instance_config_screen.dart           # UI Config
    └── widgets/transfer_chat_dialog.dart                 # UI Transfer
```

---

## 🎯 Checklist de Implementación

- [ ] Migración SQL ejecutada
- [ ] Backend reiniciado
- [ ] Endpoints de instancias funcionando
- [ ] Usuario A configuró instancia
- [ ] Usuario B configuró instancia
- [ ] Webhook enviando campo `instance`
- [ ] Mensajes llegan a usuario correcto
- [ ] No hay cross-contamination de chats
- [ ] Transferencia funciona A → B
- [ ] Mensajes post-transferencia usan instancia correcta
- [ ] UI de configuración integrada
- [ ] UI de transferencia integrada

---

## 🆘 Soporte

Si encuentras problemas:

1. **Revisar logs del backend**
2. **Consultar tabla `crm_webhook_events`** para debug
3. **Ejecutar script de prueba**: `node test_crm_instances.js TOKEN`
4. **Verificar consultas SQL** de la sección de verificación

---

**¡Listo para producción!** 🎉
