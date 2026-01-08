# Limpieza de Base de Datos CRM

## ⚠️ IMPORTANTE

Después de solucionar el bug del webhook parser que guardaba números incorrectos en los chats, es necesario limpiar la base de datos para que todos los nuevos chats se guarden correctamente.

## ¿Qué hace este script?

El script `clear_crm_chats.ts` elimina:

1. ✅ **Todos los mensajes** (tabla `crm_messages`)
2. ✅ **Todos los metadatos de chats** (tabla `crm_chat_meta`)
3. ✅ **Todos los chats/threads** (tabla `crm_threads`)
4. ✅ **Eventos de webhook antiguos** (tabla `crm_webhook_events` - solo los de más de 7 días)

## ¿Por qué es necesario?

Antes del fix, el webhook parser guardaba el número de la INSTANCIA en lugar del número del CLIENTE. Esto causaba:
- Chats con números incorrectos (18295344286, 263101257658401)
- Mensajes enviados al número de la instancia en lugar del cliente
- Imposibilidad de distinguir entre diferentes clientes

**Ahora que el parser está corregido**, todos los chats nuevos se guardarán correctamente con el número del cliente.

## ⚠️ PRECAUCIONES

**ADVERTENCIA: Esta acción NO SE PUEDE DESHACER**

- Se perderán TODOS los chats históricos
- Se perderán TODOS los mensajes
- Se perderá el historial de conversaciones

**ANTES DE EJECUTAR:**
1. ✅ Asegúrate de que el fix del webhook parser está desplegado en producción
2. ✅ Asegúrate de que NO hay chats importantes que necesites guardar
3. ✅ Considera hacer un backup de la base de datos (opcional)

## Cómo ejecutar

### En Local (desarrollo):

```bash
cd fulltech_api
npm run clear-crm-chats
```

### En Easypanel (producción):

1. Abre el terminal de Easypanel para el proyecto `fulltech_api`
2. Asegúrate de tener el último código:
   ```bash
   git pull
   ```
3. Ejecuta el script:
   ```bash
   npm run clear-crm-chats
   ```

## Qué esperar

El script mostrará:
1. Conteo de registros actuales
2. Advertencia de 5 segundos (puedes cancelar con Ctrl+C)
3. Progreso de eliminación por tabla
4. Resumen final de registros eliminados

Ejemplo de salida:

```
========================================
[CLEAR_CRM] Iniciando limpieza de CRM
========================================

⚠️  ADVERTENCIA: Esta acción eliminará TODOS los chats y mensajes del CRM
⚠️  Los datos NO SE PUEDEN RECUPERAR después de esta operación

📊 Registros actuales:
  - Mensajes: 1250
  - Chats: 45
  - Eventos webhook: 3420

⏳ Esperando 5 segundos antes de continuar...
   Presiona Ctrl+C para cancelar

🗑️  Iniciando eliminación...

[1/4] Eliminando mensajes (crm_messages)...
✅ Eliminados 1250 mensajes
[2/4] Eliminando metadata de chats (crm_chat_meta)...
✅ Eliminados 45 registros de metadata
[3/4] Eliminando chats/threads (crm_threads)...
✅ Eliminados 45 chats
[4/4] Eliminando eventos de webhooks...
✅ Eliminados 2100 eventos de webhooks antiguos

========================================
✅ Limpieza completada exitosamente
========================================

🎉 Ahora todos los nuevos chats se guardarán con los números correctos
```

## Después de ejecutar

1. ✅ Los clientes deberán enviar nuevos mensajes para crear nuevos chats
2. ✅ Los nuevos chats se guardarán con el número CORRECTO del cliente
3. ✅ Ya no habrá confusión con números de instancia
4. ✅ Los mensajes llegarán al cliente correcto

## Verificación

Para verificar que los nuevos chats se guardan correctamente:

1. Pide a un cliente que envíe un mensaje de WhatsApp
2. Verifica en los logs del backend:
   ```
   [WEBHOOK][PARSER] ====== FIXED PARSER ======
   [WEBHOOK][PARSER] fromMe: false
   [WEBHOOK][PARSER] phoneNumber (OTHER PARTY): [número del cliente]
   ```
3. Verifica en la base de datos que el chat tiene el número del cliente:
   ```sql
   SELECT id, wa_id, phone, display_name FROM crm_threads ORDER BY created_at DESC LIMIT 5;
   ```

## Rollback

Si algo sale mal, la única forma de recuperar los datos es:
- Restaurar desde un backup de base de datos (si hiciste uno antes)
- Los datos NO se pueden recuperar de otra forma

## Soporte

Si tienes problemas:
1. Verifica que el script terminó sin errores
2. Verifica la conexión a la base de datos
3. Verifica que el usuario de la base de datos tiene permisos de DELETE
4. Revisa los logs del script para ver dónde falló
