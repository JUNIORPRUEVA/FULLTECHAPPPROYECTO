# Fix: /api/attendance/punches 400 spam

## Síntoma
- En backend: flood de logs con `POST /api/attendance/punches -> 400` repetido.
- En app: ponchados quedan en estado FAILED/PENDING y se reintentan en cada auto-sync.

## Causa
- El módulo de Ponchado hacía `retryFailed()` automáticamente y re-enfilaba registros FAILED sin distinguir errores 4xx (reglas de negocio/validación).
- Resultado: el mismo ponchado inválido se intentaba enviar una y otra vez.

## Cambios implementados
- Cliente:
  - Remote-first al crear ponchado: si el servidor responde 4xx (por ejemplo “Ya registraste la salida hoy”), se muestra error al usuario y NO se encola.
  - Sync queue: cualquier 4xx en `syncPending()` se marca como fallo permanente y se elimina del queue (no reintentos automáticos).
  - Retry policy: solo reintenta fallos transitorios con backoff y límite de intentos.
- Backend:
  - Errores de validación (Zod) devuelven `422` con `details`.

## Checklist de verificación
1. Con sesión iniciada, intenta ponchar una acción inválida (ej: OUT cuando ya existe OUT hoy).
   - Esperado: snackbar con el error del backend.
   - Esperado: NO aparece spam de `POST /api/attendance/punches` en logs.
2. Simula offline (sin internet), poncha una vez y vuelve online.
   - Esperado: el ponchado se encola y se sincroniza una vez al recuperar conectividad.
3. Si existe un ponchado local inválido previo:
   - Esperado: se marca FAILED permanente (no vuelve a intentarse automáticamente).

## Archivos clave
- Cliente: `fulltech_app/lib/features/ponchado/data/repositories/punch_repository.dart`
- Backend: `fulltech_api/src/modules/attendance/attendance.controller.ts`
