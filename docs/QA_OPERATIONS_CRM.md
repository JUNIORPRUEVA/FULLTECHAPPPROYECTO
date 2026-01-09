# QA Checklist — Sesión/Auth + CRM ↔ Operaciones

## A) Sesión / Auth (Windows)
1. Iniciar sesión con usuario válido.
2. Cerrar la app (Windows) y volver a abrir:
   - Debe entrar directo al sistema (sin pantalla de login).
3. Forzar 401 (ej. invalidar token_version o esperar expiración del JWT):
   - Debe intentar `POST /api/auth/refresh` y reintentar la request.
   - Solo debe salir a login si el refresh falla.
4. Cambiar servidor en `Configuración > Servidor`:
   - Debe mostrar confirmación.
   - Si confirma: hace logout una sola vez y cambia el servidor.
   - Si cancela: no cambia servidor ni sesión.

## B) CRM → Operaciones
1. En CRM (chat), cambiar estado a `Por levantamiento` (con nota):
   - Debe crear/upsert `operations_jobs` y verse en Operaciones:
     - `Agenda` y `Levantamientos`.
2. En CRM, cambiar estado a `Servicio reservado`:
   - Debe exigir fecha/hora + nota + producto/servicio.
   - Debe aparecer en `Agenda` y `Instalaciones`, con fecha agrupada.
3. En CRM, cambiar estado a `Garantía` / `Con problema` / `Solución de garantía`:
   - Debe exigir descripción del problema.
   - Debe aparecer en `Agenda` y `Garantías`.
4. Repetir el mismo cambio de estado varias veces:
   - No debe crear duplicados (upsert idempotente por chat + tipo activo).

## C) Operaciones → CRM
1. Con rol técnico, abrir una tarea en Operaciones y marcar:
   - `Iniciar` → status operativo pasa a “en proceso”.
   - `Terminar` → requiere nota y cambia CRM a `Servicio finalizado`.
   - `Cancelar` → requiere motivo y cambia CRM a `Cancelado`.
2. Validar historial:
   - Operaciones debe mostrar `Historial` y reflejar cambios.
3. Validar enlace CRM:
   - Desde Operaciones se debe poder abrir el chat CRM asociado.

## Logs esperados (debug)
- `[AUTH] bootstrap...`, `[AUTH] refresh...`
- `[AUTH][HTTP] 401 ... baseUrl=...`
- `[CRM] ...` (SSE `chat.updated`)

