# QA — Attendance (Ponchado)

## Objetivo
Evitar bucles de requests a `POST /api/attendance/punches` y asegurar que los ponches se sincronicen correctamente (offline-first).

## Checklist
1) Login exitoso → no aparece spam de `POST /api/attendance/punches` en consola.
2) Abrir módulo `Ponchado` → no dispara sincronizaciones en bucle.
3) Crear un ponche válido (IN) → responde 200/201 y aparece en la lista.
4) Reintentar (mismo tipo el mismo día) → backend devuelve 200 con el registro existente (idempotencia), no 400.
5) Caso inválido (OUT sin IN) → backend devuelve 400 `BUSINESS_RULE`; cliente marca el item como fallido permanente y NO reintenta.
6) Apagar internet, crear un ponche → queda PENDING local; al reconectar se sincroniza una sola vez.

## Notas de implementación
- Cliente nunca reintenta automáticamente errores 400/422 para sync de ponches.
- Backend devuelve 422 `VALIDATION_ERROR` para errores de payload y 400 `BUSINESS_RULE` para reglas de negocio.
- Backend es idempotente para duplicados por día y tipo: devuelve 200 con el ponche existente.
