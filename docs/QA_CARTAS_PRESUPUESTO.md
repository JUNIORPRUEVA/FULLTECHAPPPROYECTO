# QA – Cartas desde Presupuesto

## Objetivo
Validar el flujo de **Cartas** generado desde la pantalla **Presupuesto**:
- **Crear carta** (solo desde Presupuesto, vía modal).
- **Cartas** (lista por Presupuesto, sin acciones de creación).
- Generación AI en backend (OpenAI Responses API) + PDF automático.
- Persistencia, detalle, PDF (preview/share/download), eliminar.
- Envío por WhatsApp vía Evolution API (backend).

## Pre-requisitos
- Backend `fulltech_api` corriendo.
- Migración SQL aplicada (ver `fulltech_api/sql/2026-01-11_cartas_feature.sql`).
- `.env` con OpenAI configurado o backend iniciado con `OPENAI_MOCK=true` para pruebas determinísticas.
- Evolution API configurada (o instancia CRM activa) si se va a probar envío.

## Smoke (backend)
1. Iniciar backend con `OPENAI_MOCK=true`.
2. Ejecutar: `node fulltech_api/test_cartas_smoke.js <TOKEN> <COTIZACION_ID>`.
3. Confirmar:
   - POST `/api/cartas/generate` devuelve `201`.
   - GET `/api/cartas/:id/pdf` devuelve `200` con `application/pdf`.

## Flujo UI (Flutter)
### A) Crear Carta (modal)
1. Abrir **Presupuesto** con una cotización existente (`quotationId`).
2. Presionar **Crear carta**.
3. Validar:
   - `Tipo de carta` (dropdown) obligatorio.
   - `Asunto` obligatorio.
   - `Instrucciones para la IA` obligatorio.
   - `Adjuntar esta cotización`:
     - ON: no exige teléfono.
     - OFF: exige **Nombre** y **Teléfono**.
4. Presionar **Generar**.
5. Resultado esperado:
   - Navega automáticamente a **Detalle de Carta**.

### B) Listado de Cartas
1. En **Presupuesto**, presionar **Cartas**.
2. Resultado esperado:
   - Abre lista filtrada por `presupuestoId`.
   - No existe botón/acción de crear desde esta lista.

### C) Detalle de Carta
1. Abrir cualquier carta del listado.
2. Validar:
   - Se muestra asunto, tipo, cliente, estado.
   - Acción **Ver PDF** abre visor.
   - Acción **Enviar WhatsApp** solicita/usa teléfono y envía por backend.
   - Acción **Eliminar** elimina y regresa.

### D) PDF – Preview/Share/Download
1. En detalle, abrir **Ver PDF**.
2. Validar:
   - Se muestra el PDF en pantalla.
   - **Compartir** usa `Printing.sharePdf`.
   - **Descargar** abre diálogo de guardado (desktop) y escribe archivo.

## Casos negativos
- Presupuesto sin `quotationId`: botones **Cartas** y **Crear carta** deben mostrar aviso (no crashear).
- AI deshabilitada/OPENAI sin key: **Crear carta** debe mostrar error claro.
- Carta sin PDF en disco: detalle/visor debe reportar “PDF no disponible”.
- Teléfono inválido: envío WhatsApp debe fallar con mensaje claro.
