# ✅ Guía de Pruebas - Envío de Mensajes CRM

## Estado Actual

### ✅ Completado
1. **Esquema de base de datos** - Migrado correctamente (thread_id → chat_id)
2. **Recepción de mensajes** - Funcionando correctamente
3. **Configuración de Evolution API** - Verificada y funcionando
4. **Backend endpoints** - Listos para envío de texto, imagen y audio

### 🔧 Configuración Actual

**Backend (Evolution API):**
- URL: `https://evolucionapi-evolution-api.gcdndd.easypanel.host`
- Instancia: `fulltech`
- Estado: `open` (conectado)
- API Key: Configurada ✅

**Endpoints disponibles:**
- `POST /api/crm/chats/:chatId/messages/text` - Enviar texto
- `POST /api/crm/chats/:chatId/messages/media` - Enviar imagen/audio/video
- `POST /api/crm/chats/outbound/text` - Enviar texto a nuevo número

## 📱 Cómo Probar en la App Flutter

### 1. Configurar Evolution Direct (Opcional pero Recomendado)

En la app Flutter:

1. Abre el módulo **CRM**
2. Haz clic en el ícono de **engranaje** (⚙️) en la esquina superior derecha
3. Ve a la pestaña **"Evolution (Directo)"**
4. Activa **"Activar envío directo a Evolution"**
5. Completa los campos:
   - **Evolution Base URL**: `https://evolucionapi-evolution-api.gcdndd.easypanel.host`
   - **Nombre de Instancia**: `fulltech`
   - **API Key**: `[Tu API Key de Evolution]`
   - **Código País por Defecto**: `1` (para República Dominicana/USA)
6. Haz clic en **Guardar**

> **Nota:** El envío directo hace que la app envíe directamente a Evolution API sin pasar por el backend. Esto es útil para debugging pero menos seguro (la API key queda en el cliente).

### 2. Probar Envío de Texto

1. En el módulo CRM, selecciona un chat existente (o crea uno nuevo respondiendo a un mensaje recibido)
2. Escribe un mensaje en el campo de texto
3. Presiona Enter o haz clic en el botón de enviar
4. El mensaje debería:
   - ✅ Aparecer en el chat inmediatamente con estado "enviando"
   - ✅ Cambiar a estado "enviado" cuando Evolution confirme
   - ✅ Llegar al WhatsApp del destinatario

### 3. Probar Envío de Imagen

1. En el chat, haz clic en el botón de **clip** (📎) o **imagen** (🖼️)
2. Selecciona una imagen de tu computadora
3. Opcionalmente, agrega un caption (texto descriptivo)
4. Envía la imagen
5. La imagen debería:
   - ✅ Subirse al servidor
   - ✅ Enviarse via Evolution API
   - ✅ Aparecer en el chat con preview
   - ✅ Llegar al WhatsApp del destinatario

### 4. Probar Envío de Audio

1. En el chat, busca el botón de **audio** (🎤) o **clip**
2. Selecciona un archivo de audio (.mp3, .m4a, .ogg, etc.)
3. Opcionalmente, agrega un caption
4. Envía el audio
5. El audio debería:
   - ✅ Subirse al servidor
   - ✅ Enviarse via Evolution API
   - ✅ Aparecer en el chat
   - ✅ Llegar al WhatsApp del destinatario como nota de voz o audio

## 🧪 Pruebas desde el Backend

### Prueba 1: Verificar Configuración

```bash
cd fulltech_api
npx tsx scripts/verify_evolution_config.ts
```

Deberías ver:
- ✅ Todas las variables de entorno configuradas
- ✅ Estado de la instancia: "open"

### Prueba 2: Enviar Mensaje de Prueba

Edita el archivo `scripts/test_evolution_send.ts` y cambia el número de prueba:

```typescript
const testPhone = '18295344286'; // ← Cambia por tu número
```

Luego ejecuta:

```bash
npx tsx scripts/test_evolution_send.ts
```

Deberías recibir el mensaje en WhatsApp.

## 🔍 Verificar Logs

### En el Backend (PowerShell):

El servidor ya está corriendo. Para ver los logs en tiempo real, observa la terminal donde está `npm run dev`.

Cuando envíes un mensaje desde la app, deberías ver logs como:

```
[WEBHOOK] Received event: messages.upsert
[CRM] Processing message...
[CRM] Message saved: <message-id>
[SSE] Emitting event: message.new
```

### En la App Flutter:

Si activaste el modo debug, verás logs en la consola de VS Code:

```
[CRM][SEND] using Evolution direct baseUrl=... instance=fulltech
[CRM][SEND] Evolution direct send result messageId=ABC123...
```

## ⚠️ Solución de Problemas

### Problema: "Evolution API key is empty"

**Solución:** Configura el API key en la configuración de Evolution Direct en la app.

### Problema: "Mensaje no llega a WhatsApp"

**Solución:**
1. Verifica que el número esté en formato correcto (código país + número)
2. Verifica que la instancia de Evolution esté conectada (`npx tsx scripts/verify_evolution_config.ts`)
3. Revisa los logs del backend para ver errores específicos

### Problema: "Upload failed" al enviar imagen

**Solución:**
1. Verifica que el servidor backend esté corriendo
2. Verifica que la carpeta `uploads/` tenga permisos de escritura
3. Revisa el tamaño del archivo (límite: 25MB por defecto)

## 🚀 Desplegar a Producción (Easypanel)

Cuando todo funcione correctamente en local:

1. Todos los cambios ya están en Git (commit `0370dcc`)
2. En Easypanel:
   - Ve a tu proyecto `fulltechapp`
   - Haz clic en **Deploy**
   - Espera a que se complete el deployment
3. La migración SQL se aplicará automáticamente
4. Verifica que las variables de entorno estén configuradas:
   - `EVOLUTION_BASE_URL`
   - `EVOLUTION_API_KEY`
   - `EVOLUTION_INSTANCE`
   - `PUBLIC_BASE_URL` (debe ser tu dominio de Easypanel)
5. Configura el webhook en Evolution para apuntar a:
   ```
   https://fulltechapp-fulltechapp.gcdndd.easypanel.host/api/webhooks/evolution
   ```

## 📋 Checklist Final

- [ ] ✅ Recibir mensajes de WhatsApp (YA FUNCIONA)
- [ ] Enviar mensajes de texto desde la app
- [ ] Enviar imágenes desde la app
- [ ] Enviar audios desde la app
- [ ] Verificar que los mensajes aparezcan en tiempo real (SSE)
- [ ] Probar en producción después de desplegar

## 📝 Notas Técnicas

### Flujo de Envío de Mensajes

1. **Usuario escribe mensaje** en la app Flutter
2. **App Flutter** verifica si tiene "envío directo" activado:
   - **SI**: Envía directamente a Evolution API, luego registra en backend con `skipEvolution=true`
   - **NO**: Envía al backend, el backend envía a Evolution API
3. **Backend** guarda el mensaje en la base de datos
4. **Backend** emite evento SSE para actualizar la UI en tiempo real
5. **Evolution API** envía el mensaje a WhatsApp
6. **WhatsApp** entrega el mensaje al destinatario

### Tipos de Medios Soportados

- ✅ **Texto** - Mensajes de texto simples
- ✅ **Imagen** - image/jpeg, image/png, image/gif, image/webp
- ✅ **Audio** - audio/mpeg, audio/ogg, audio/wav, audio/m4a
- ✅ **Video** - video/mp4, video/quicktime
- ✅ **Documento** - application/pdf, application/msword, etc.

### Límites

- **Tamaño máximo de archivo**: 25 MB (configurable con `MAX_UPLOAD_MB`)
- **Rate limiting**: Depende de tu plan de Evolution API
- **Formatos de número soportados**: E.164 (ej: 18295344286)
