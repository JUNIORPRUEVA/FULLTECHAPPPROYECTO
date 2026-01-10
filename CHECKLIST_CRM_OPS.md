# ✅ Checklist Rápido: Verificación CRM → Operaciones

## 🎯 Verificación en 5 Minutos

Use este checklist para verificar rápidamente que el flujo funciona correctamente.

---

## 📋 Prerequisitos

- [ ] Backend está corriendo
- [ ] Tengo credenciales de acceso (email + password)
- [ ] Existe al menos 1 chat en CRM
- [ ] Existe al menos 1 servicio activo
- [ ] Existe al menos 1 técnico activo

---

## 🚀 Opción 1: Script Automatizado (Recomendado)

```bash
# Ejecutar desde la raíz del proyecto
node test_crm_operations_flow.js admin@fulltech.com password123
```

### Resultado esperado:
```
🎉 TODAS LAS PRUEBAS PASARON EXITOSAMENTE
Pruebas exitosas: 4/4
```

- [ ] Script ejecutó sin errores
- [ ] Prueba 1 (por_levantamiento): ✅ PASÓ
- [ ] Prueba 2 (servicio_reservado): ✅ PASÓ
- [ ] Prueba 3 (idempotencia): ✅ PASÓ
- [ ] Prueba 4 (sesión correcta): ✅ PASÓ

**Si todas las pruebas pasan → El sistema funciona correctamente ✅**

---

## 🧪 Opción 2: Prueba Manual Rápida

### Paso 1: Preparar chat de prueba

- [ ] Abrir aplicación y ir al CRM
- [ ] Seleccionar un chat (que NO esté en estado "compro")
- [ ] Anotar el teléfono del chat: `___________________`

### Paso 2: Cambiar a "Por Levantamiento"

- [ ] Cambiar estado a "Por levantamiento"
- [ ] Llenar formulario:
  - [ ] Fecha/hora: [Seleccionar fecha futura]
  - [ ] Ubicación: "Calle de Prueba 123"
  - [ ] Técnico: [Seleccionar cualquiera]
  - [ ] Servicio: [Seleccionar cualquiera]
- [ ] Guardar cambios
- [ ] No hubo errores al guardar

### Paso 3: Verificar en Operaciones

- [ ] Ir al módulo "Operaciones"
- [ ] Abrir pestaña "Levantamientos"
- [ ] **¿Aparece el nuevo job?** ☐ Sí ☐ No
- [ ] **¿Muestra el nombre correcto?** ☐ Sí ☐ No
- [ ] **¿Muestra el teléfono correcto?** ☐ Sí ☐ No
- [ ] **¿Muestra la fecha correcta?** ☐ Sí ☐ No
- [ ] **¿Muestra el técnico correcto?** ☐ Sí ☐ No

### Paso 4: Verificar Cliente

- [ ] Ir al módulo "Clientes"
- [ ] Buscar por teléfono del chat
- [ ] **¿Aparece el cliente?** ☐ Sí ☐ No
- [ ] **¿Origen es "whatsapp"?** ☐ Sí ☐ No

### Paso 5: Verificar Agenda

- [ ] Ir a Operaciones → Agenda
- [ ] **¿Aparece en la fecha correcta?** ☐ Sí ☐ No

### Paso 6: Probar Idempotencia

- [ ] Volver al chat en CRM
- [ ] Cambiar solo la nota y guardar nuevamente
- [ ] Ir a Operaciones
- [ ] **¿Solo hay 1 job activo?** ☐ Sí ☐ No

---

## 🔍 Verificación Detallada (Opcional)

### SQL Query Rápido

```sql
-- Reemplazar 'TELEFONO_AQUI' con los últimos 8 dígitos
SELECT 
  c.nombre as cliente,
  c.telefono,
  oj.id as job_id,
  oj.crm_task_type as tipo,
  oj.status as estado,
  oj.scheduled_at as fecha
FROM operations_jobs oj
JOIN customer c ON oj.crm_customer_id = c.id
WHERE c.telefono LIKE '%TELEFONO_AQUI%'
  AND oj.deleted_at IS NULL
ORDER BY oj.created_at DESC;
```

- [ ] Query retorna resultados
- [ ] Solo hay 1 job activo por tipo
- [ ] Todos los datos son correctos

---

## ✅ Resultado Final

### Todo funciona si:

✅ Cliente se creó automáticamente  
✅ Job aparece en Operaciones/Levantamientos  
✅ Job aparece en Operaciones/Agenda  
✅ Todos los datos son correctos (nombre, teléfono, fecha, técnico)  
✅ No hay duplicados al guardar varias veces  

### Hay problema si:

❌ Cliente no se creó  
❌ Job no aparece en Operaciones  
❌ Los datos son incorrectos o están vacíos  
❌ Se crean múltiples jobs del mismo tipo  
❌ Error al guardar el estado  

---

## 🆘 Si Algo Falla

### Error: "scheduled_at is required"
➡️ **Solución**: Llena todos los campos requeridos del formulario

### Error: "service_id is invalid"
➡️ **Solución**: Ve a Configuración → Servicios y activa al menos uno

### Error: "assigned_tech_id is invalid"
➡️ **Solución**: Crea un usuario con rol "Técnico"

### Job no aparece en Operaciones
➡️ **Solución**: 
1. Verifica que no haya filtros activos
2. Revisa logs del backend
3. Ejecuta script SQL de verificación

### Se crearon duplicados
➡️ **Solución**: Esto NO debería pasar. Contacta al desarrollador.

---

## 📊 Tiempos Estimados

- ⚡ **Script automatizado**: ~1 minuto
- 🧪 **Prueba manual**: ~5 minutos
- 🔍 **Verificación SQL**: ~2 minutos

---

## 📞 Documentación Completa

Para más información, consultar:

- **Guía completa**: `PRUEBA_CRM_OPERACIONES.md`
- **Resumen ejecutivo**: `RESUMEN_VERIFICACION_CRM_OPS.md`
- **Casos de uso**: `CASOS_USO_CRM_OPS.md`

---

## 🎯 Casos de Uso a Probar

| Caso | Descripción | Tiempo |
|------|-------------|--------|
| 1 | Por levantamiento | 3 min |
| 2 | Servicio reservado | 3 min |
| 3 | Idempotencia | 2 min |
| 4 | Garantía | 3 min |

**Total**: ~15 minutos para probar todos los casos

---

**Fecha**: 2026-01-10  
**Versión**: 1.0  
**Última actualización**: Hoy
