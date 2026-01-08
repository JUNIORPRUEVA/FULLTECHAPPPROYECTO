# Troubleshooting: Backend Logs 400/401 Spam

## Problema 1: POST /api/attendance/punches 400 (Bad Request) Spam

### Síntomas
```
POST /api/attendance/punches 400 3.338 ms - 46
POST /api/attendance/punches 400 2.981 ms - 46
POST /api/attendance/punches 400 3.320 ms - 46
... (se repite constantemente)
```

### Causa Raíz
La app Flutter tiene **registros de ponchado pendientes en la cola de sincronización offline** con datos inválidos o incompletos. Estos registros están en la base de datos SQLite local y el sistema de auto-sync intenta enviarlos repetidamente.

### Por qué pasa
1. Usuario intentó ponchar sin conexión
2. Datos se guardaron en cola offline con formato incorrecto
3. Cuando hay conexión, el auto-sync intenta enviarlos
4. Backend rechaza con 400 (validación falla)
5. Se reintenta indefinidamente

### Solución RÁPIDA (para el usuario afectado)

#### Opción A: Limpiar base de datos local (Flutter app)
```bash
cd fulltech_app
dart run tool/clear_pending_punches.dart
```

Esto:
- ✅ Encuentra la base de datos SQLite local
- ✅ Elimina registros pendientes de attendance/ponchado
- ✅ No afecta otros módulos (CRM, ventas, etc.)
- ✅ Usuario puede seguir usando la app

#### Opción B: Eliminar base de datos completamente
**Windows:**
```
%APPDATA%\fulltech_app\*.db
```
Borrar todos los archivos `.db` en esa carpeta.

**Consecuencia:** Se pierden todos los datos offline pendientes de sincronización (no solo punches).

### Solución PERMANENTE (código)

#### Backend: Mejor logging de errores 400
Actualmente el backend solo responde `400 - 46 bytes`, pero no logea QUÉ campo falló en validación.

**TODO:**
```typescript
// attendance.controller.ts
export async function createPunch(req: Request, res: Response) {
  try {
    const body = createAttendancePunchSchema.parse(req.body);
    // ...
  } catch (error) {
    if (error instanceof z.ZodError) {
      console.error('[ATTENDANCE] Validation error:', error.errors);
      return res.status(400).json({ 
        error: 'Validation error', 
        details: error.errors 
      });
    }
    // ...
  }
}
```

#### Flutter: Validar antes de encolar
Asegurar que SOLO se encolan punches con todos los campos requeridos:

**TODO:**
```dart
// punch_repository.dart
Future<PunchRecord> createPunchOfflineFirst(CreatePunchDto dto) async {
  // Validate BEFORE queuing
  if (dto.datetimeUtc.isEmpty) {
    throw ArgumentError('datetimeUtc is required');
  }
  // ... more validations
  
  // Then queue
  await localDataSource.insertPendingPunch(dto);
}
```

### Prevención

1. **No permitir ponchar sin GPS** (si es requerido):
   ```dart
   if (locationRequired && position == null) {
     throw Exception('Location is required');
   }
   ```

2. **Validar datos antes de encolar**:
   ```dart
   CreatePunchDto.validate(dto); // throws if invalid
   ```

3. **Limpiar cola de errores viejos** (auto-expire después de 7 días):
   ```dart
   await db.execute('''
     DELETE FROM sync_queue 
     WHERE created_at_ms < ? AND status = 2
   ''', [sevenDaysAgoMs]);
   ```

---

## Problema 2: MIGRATION CHECKSUM MISMATCH (11 archivos)

### Síntomas
```
⚠️  MIGRATION CHECKSUM MISMATCH: 2026-01-02_crm_customers.sql
This file was edited AFTER it was already applied to the database.
...
Current behavior: SKIPPING this file (SQL_MIGRATIONS_STRICT=false)
```

### Causa Raíz
Alguien editó archivos de migración SQL **después de que ya fueron aplicados** a la base de datos. Esto viola la regla de oro: **migraciones son inmutables una vez aplicadas**.

### Por qué es un problema
- **Schema drift**: diferentes ambientes tienen esquemas diferentes
- **Historia perdida**: no se puede recrear la BD desde cero
- **Conflictos**: otros devs no pueden replicar el schema

### Solución RÁPIDA (Actualizar checksums)

Si los cambios ya están aplicados en la BD y solo necesitas sincronizar checksums:

```bash
cd fulltech_api
npm run migrate:fix-checksums
```

Esto:
- ✅ Lee todos los archivos .sql actuales
- ✅ Calcula sus checksums
- ✅ Actualiza la tabla `_sql_migrations`
- ⚠️  Oculta la historia de cambios (no ideal, pero funciona)

### Solución CORRECTA (Crear nuevas migraciones)

Si sabes QUÉ se editó y quieres mantener historial:

```bash
# 1. Revertir archivos editados
git log --oneline sql/
git show <commit>:sql/2026-01-02_crm_customers.sql > sql/2026-01-02_crm_customers.sql

# 2. Crear nuevas migraciones con los cambios
npm run migrate:new fix_crm_customers_schema

# 3. Copiar los cambios al nuevo archivo
# (solo las líneas que se agregaron/modificaron)
```

### Solución NUCLEAR (Re-aplicar todo)

**SOLO EN DESARROLLO LOCAL:**

```sql
-- Eliminar tabla de control
DROP TABLE _sql_migrations;

-- Reiniciar servidor
npm run dev
-- Todas las migraciones se re-aplican
```

⚠️ **NUNCA hacer esto en producción** - perderás el historial.

### Prevención

1. **Usar `SQL_MIGRATIONS_STRICT=true` en CI/CD**:
   ```env
   # .env.production
   SQL_MIGRATIONS_STRICT=true
   ```
   Esto hace que el servidor FALLE si detecta checksum mismatch.

2. **Usar el helper para crear migraciones**:
   ```bash
   npm run migrate:new "descripcion del cambio"
   ```

3. **Leer la guía de mejores prácticas**:
   - [SQL_MIGRATIONS_BEST_PRACTICES.md](SQL_MIGRATIONS_BEST_PRACTICES.md)

4. **Agregar git pre-commit hook** (opcional):
   ```bash
   # .git/hooks/pre-commit
   #!/bin/bash
   # Prevent committing changes to old SQL files
   changed_sql=$(git diff --cached --name-only | grep '^sql/.*\.sql$')
   if [ -n "$changed_sql" ]; then
     echo "⚠️  Warning: You're modifying SQL migration files!"
     echo "$changed_sql"
     echo "Are you sure? (y/n)"
     read answer
     if [ "$answer" != "y" ]; then
       exit 1
     fi
   fi
   ```

---

## Resumen de Comandos Útiles

### Para el usuario (Flutter app)
```bash
# Limpiar punches pendientes
cd fulltech_app
dart run tool/clear_pending_punches.dart
```

### Para el desarrollador (Backend)
```bash
# Actualizar checksums de migraciones
cd fulltech_api
npm run migrate:fix-checksums

# Crear nueva migración
npm run migrate:new "descripcion"

# Ver migraciones aplicadas
psql $DATABASE_URL -c "SELECT * FROM _sql_migrations ORDER BY applied_at DESC"
```

### Variables de entorno útiles
```env
# Deshabilitar migraciones (testing)
SKIP_SQL_MIGRATIONS=true

# Hacer checksums estrictos (prod/CI)
SQL_MIGRATIONS_STRICT=true
```

---

## Logs Normales vs Problemáticos

### ✅ Logs NORMALES:
```
GET /api/crm/chats/stats 200 6.742 ms - 79
POST /api/attendance/punches 201 15.234 ms - 234
GET /uploads/products/xyz.jpg 200 2.123 ms - 45678
```

### ⚠️ Logs PROBLEMÁTICOS:
```
POST /api/attendance/punches 400 3.338 ms - 46    ← Spam de 400
GET /uploads/products/xyz.jpg 404 1.752 ms - 197  ← Archivo faltante
DELETE /api/crm/chats/xxx 404 10.773 ms - 197    ← Chat no existe

⚠️  MIGRATION CHECKSUM MISMATCH: ...              ← Migración editada
```

### ❌ Logs CRÍTICOS:
```
POST /api/attendance/punches 401 ...  ← No autenticado (ver FIX_AUTH_PERSISTENCE_401_LOOP.md)
POST /api/attendance/punches 500 ...  ← Error interno (revisar stack trace)
```

---

## FAQ

**P: ¿Por qué el 400 spam no para solo?**
R: Porque el auto-sync reintenta indefinidamente. Los datos están en la cola offline y seguirán intentando hasta que se limpien o se corrijan.

**P: ¿Perderé datos si limpio la cola de punches?**
R: Solo los punches pendientes de sincronizar. Punches ya sincronizados en el backend están seguros.

**P: ¿Debo usar migrate:fix-checksums o crear nuevas migraciones?**
R: Depende:
- `fix-checksums`: Rápido, oculta historial (OK para dev/urgencias)
- Nuevas migraciones: Correcto, mantiene historial (mejor para prod)

**P: ¿Cómo evito que esto vuelva a pasar?**
R: 
1. Backend: Loguear errores de validación completos
2. Flutter: Validar datos antes de encolar
3. Migraciones: Nunca editar archivos aplicados, usar `migrate:new`

---

**Ver también:**
- [FIX_AUTH_PERSISTENCE_401_LOOP.md](FIX_AUTH_PERSISTENCE_401_LOOP.md) - Problemas de autenticación
- [SQL_MIGRATIONS_BEST_PRACTICES.md](SQL_MIGRATIONS_BEST_PRACTICES.md) - Workflow de migraciones
