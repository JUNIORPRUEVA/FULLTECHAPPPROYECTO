# FULLTECHAPPPROYECTO

Monorepo:

- `fulltech_api/` (Node.js + TypeScript + Prisma + PostgreSQL)
- `fulltech_app/` (Flutter)

## Deploy backend (EasyPanel)

See `fulltech_api/README_EASYPANEL.md`.

---

## 📚 Documentación CRM → Operaciones

### 🎯 Verificación Completa del Flujo

Hemos creado una suite completa de herramientas y documentación para verificar el flujo de creación automática desde el CRM hacia el módulo de Operaciones:

### 📖 Documentos Principales

1. **[RESUMEN_VERIFICACION_CRM_OPS.md](./RESUMEN_VERIFICACION_CRM_OPS.md)** - 📊 Resumen ejecutivo
   - Estado de verificación completa
   - Funcionalidades confirmadas
   - Herramientas disponibles
   - Métricas de calidad

2. **[PRUEBA_CRM_OPERACIONES.md](./PRUEBA_CRM_OPERACIONES.md)** - 🧪 Guía completa de pruebas
   - Método 1: Script automatizado
   - Método 2: Pruebas manuales paso a paso
   - Verificación en base de datos
   - Troubleshooting y problemas comunes

3. **[CASOS_USO_CRM_OPS.md](./CASOS_USO_CRM_OPS.md)** - 📖 Casos de uso reales
   - 7 escenarios prácticos con datos de ejemplo
   - Resultados esperados detallados
   - Ejemplos de queries SQL

### 🛠️ Herramientas de Verificación

1. **Script Automatizado Node.js** - `test_crm_operations_flow.js`
   ```bash
   node test_crm_operations_flow.js admin@email.com password
   ```
   - Ejecuta 4 pruebas automáticas
   - Verifica cliente, jobs, idempotencia, sesión
   - Output con colores y resumen

2. **Script PowerShell** - `test_crm_operations_flow.ps1`
   ```powershell
   .\test_crm_operations_flow.ps1
   ```
   - Interfaz amigable para Windows
   - Verifica prerequisitos
   - Solicita credenciales interactivamente

3. **Script SQL** - `fulltech_api/sql/verify_crm_operations_flow.sql`
   ```bash
   psql -d db -v chat_id='id' -v empresa_id='id' -f verify_crm_operations_flow.sql
   ```
   - 11 verificaciones detalladas
   - Checklist automático
   - Resumen visual con emojis

### ✅ Qué se Verifica

Cuando se marca un chat con estado **"agendado"** o **"por levantamiento"**:

✅ Se crea el cliente automáticamente si no existe  
✅ Se crea el registro en `operations_jobs`  
✅ Se asocia correctamente con el chat (`crm_chat_id`)  
✅ Se crea el registro en `operations_schedule` para agenda  
✅ Todo está en la sesión correcta (`empresa_id`)  
✅ No se crean duplicados (idempotencia)  
✅ Se preserva toda la información (nombre, teléfono, fecha, técnico, servicio)  
✅ Se registra en el historial  

### 🚀 Inicio Rápido

```bash
# 1. Ejecutar prueba automatizada
node test_crm_operations_flow.js admin@fulltech.com password123

# 2. Ver resultados
# ✓ TODAS LAS PRUEBAS PASARON EXITOSAMENTE

# 3. Para más detalles, consultar:
# - PRUEBA_CRM_OPERACIONES.md
# - RESUMEN_VERIFICACION_CRM_OPS.md
```

### 📋 Estados CRM que Crean Jobs

| Estado CRM           | Tipo Job            | Requiere Formulario |
|---------------------|---------------------|---------------------|
| `por_levantamiento` | `LEVANTAMIENTO`     | ✅ Sí              |
| `servicio_reservado`| `SERVICIO_RESERVADO`| ✅ Sí              |
| `agendado`*         | `SERVICIO_RESERVADO`| ✅ Sí              |
| `garantia`          | `GARANTIA`          | ✅ Sí              |

\* Alias aceptado

### 🔗 Documentación Relacionada

- [RESUMEN_IMPLEMENTACION_CRM_ESTADOS.md](./RESUMEN_IMPLEMENTACION_CRM_ESTADOS.md) - Implementación completa del sistema de estados
- [docs/QA_CRM_OPERATIONS_BUYFLOW.md](./docs/QA_CRM_OPERATIONS_BUYFLOW.md) - Checklist QA oficial
- [docs/QA_OPERATIONS_CRM.md](./docs/QA_OPERATIONS_CRM.md) - Sesión/Auth + CRM ↔ Operaciones
