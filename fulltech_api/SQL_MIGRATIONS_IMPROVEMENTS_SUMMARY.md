# SQL Migrations Workflow - Summary of Improvements

## ✅ PROBLEMA RESUELTO

**Antes:**
```
[SQL_MIGRATIONS] Checksum changed for 2026-01-05_maintenance_module.sql. 
This usually means the file was edited after being applied. 
Best practice: create a new SQL file instead of editing old ones. 
Skipping (SQL_MIGRATIONS_STRICT=false).
```
- Mensaje poco claro
- No explica las consecuencias
- No da solución paso a paso
- Fácil de ignorar

**Ahora:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  MIGRATION CHECKSUM MISMATCH: 2026-01-05_maintenance_module.sql
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This file was edited AFTER it was already applied to the database.

  Applied checksum:  5e2a8f3c9d1b...
  Current checksum:  abc123def456...

❌ PROBLEM:
   Editing already-applied migrations can cause:
   - Schema drift between environments
   - Lost migration history
   - Inability to recreate database from scratch

✅ SOLUTION:
   1. Revert changes to 2026-01-05_maintenance_module.sql
   2. Create a NEW migration file with today's date:
      sql/2026-01-07_your_change_description.sql
   3. Put your schema changes in the new file

💡 TIP: Never edit files in sql/ after they've been applied.

Current behavior: SKIPPING this file (SQL_MIGRATIONS_STRICT=false)
To make this an error instead, set: SQL_MIGRATIONS_STRICT=true
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
- Visualmente claro
- Explica consecuencias
- Paso a paso accionable
- Muestra checksums para debug

## 🎯 CAMBIOS IMPLEMENTADOS

### 1. Mejor Logging (`runSqlMigrations.ts`)
- ✅ Mensaje de error visual con bordes
- ✅ Emojis para destacar secciones
- ✅ Muestra checksums (primeros 12 chars)
- ✅ Instrucciones específicas con fecha actual
- ✅ JSDoc completo en el código

### 2. Documentación Principal (`README.md`)
```markdown
## SQL Migrations

### ⚠️ REGLA DE ORO: Nunca edites migraciones ya aplicadas

✅ Crea un archivo nuevo con tus cambios
❌ NO edites archivos existentes

### Crear nueva migración:
npm run migrate:new "descripcion"

### Variables de entorno:
- SKIP_SQL_MIGRATIONS=true - deshabilita sistema
- SQL_MIGRATIONS_STRICT=true - convierte warnings en errores
```

### 3. Guía Completa (`SQL_MIGRATIONS_BEST_PRACTICES.md`)
- 📖 **200+ líneas** de documentación detallada
- ✅ Workflow paso a paso
- ❌ Anti-patterns explicados
- 🔍 Debugging tips
- 📊 Tablas comparativas
- 💡 Ejemplos de código

**Secciones:**
- Overview del sistema
- Regla de oro
- Workflow correcto
- Qué pasa si editas migraciones
- Variables de entorno
- Tabla de control `_sql_migrations`
- Anti-patterns (NO hacer)
- Patterns correctos (SÍ hacer)
- Debugging
- Resumen con tabla DO/DON'T

### 4. CLI Helper (`scripts/create-migration.js`)
```bash
# Uso
npm run migrate:new add_user_status_column
npm run migrate:new "create orders table"

# Genera
sql/2026-01-07_add_user_status_column.sql

# Con template:
-- 2026-01-07_add_user_status_column.sql
-- Purpose: [Describe what this migration does]
-- Author: [Your name]
-- Date: 2026-01-07

-- Example: Add a new column
-- ALTER TABLE users ADD COLUMN status text DEFAULT 'active';

-- TODO: Write your migration SQL here
```

**Features:**
- ✅ Fecha automática (YYYY-MM-DD)
- ✅ Normaliza descripción (lowercase, underscores)
- ✅ Detecta archivos duplicados
- ✅ Crea template con ejemplos
- ✅ Muestra next steps después de crear

### 5. Advertencias Visuales
**`sql/README.txt`:**
```
⚠️  WARNING: DO NOT EDIT FILES IN THIS FOLDER AFTER THEY'VE BEEN APPLIED

Once a migration file has been applied to ANY database (dev, staging, prod), 
it becomes IMMUTABLE.

WHY? ...
WHAT TO DO INSTEAD? ...
QUICK COMMANDS: ...
```

**`sql/.gitattributes`:**
```
# SQL migrations should be treated as immutable once applied
*.sql text eol=lf
```

### 6. Package Scripts (`package.json`)
```json
{
  "scripts": {
    "migrate:new": "node scripts/create-migration.js"
  }
}
```

## 📋 ANTES VS AHORA

| Aspecto | Antes | Ahora |
|---------|-------|-------|
| **Error message** | 1 línea, poco claro | Visual, paso a paso, accionable |
| **Documentación** | Solo comentarios en código | README + guía de 200+ líneas |
| **Crear migraciones** | Crear archivo manualmente | `npm run migrate:new "desc"` |
| **Advertencias** | Solo en logs | README en carpeta sql/ |
| **Debugging** | Adivinar | Guía de troubleshooting completa |
| **Ejemplos** | No disponibles | Template + 10+ ejemplos |
| **Best practices** | Implícitas | Documentadas explícitamente |

## 🎓 FLUJO DE TRABAJO NUEVO

### Desarrollador quiere cambiar schema:

1. **Crear migración:**
   ```bash
   npm run migrate:new add_email_verification
   ```

2. **Editar archivo generado:**
   ```sql
   -- sql/2026-01-07_add_email_verification.sql
   ALTER TABLE users ADD COLUMN email_verified boolean DEFAULT false;
   ```

3. **Aplicar (automático al iniciar):**
   ```bash
   npm run dev
   # [SQL_MIGRATIONS] Applying 2026-01-07_add_email_verification.sql...
   # [SQL_MIGRATIONS] Applied 2026-01-07_add_email_verification.sql
   ```

4. **Commitear:**
   ```bash
   git add sql/2026-01-07_add_email_verification.sql
   git commit -m "feat: add email verification"
   ```

### Si alguien edita migración por error:

1. **Sistema detecta cambio:**
   ```
   ⚠️  MIGRATION CHECKSUM MISMATCH: 2026-01-05_old_file.sql
   [mensaje visual completo con instrucciones]
   ```

2. **Desarrollador sigue instrucciones:**
   ```bash
   # 1. Revertir
   git checkout HEAD -- sql/2026-01-05_old_file.sql
   
   # 2. Crear nuevo archivo
   npm run migrate:new fix_previous_issue
   
   # 3. Poner cambios en nuevo archivo
   vim sql/2026-01-07_fix_previous_issue.sql
   ```

## 🔧 CONFIGURACIÓN RECOMENDADA

### Desarrollo Local
```env
# .env
SQL_MIGRATIONS_STRICT=false  # permite warnings sin crashear
```

### CI/CD Pipeline
```env
# .env.production
SQL_MIGRATIONS_STRICT=true  # falla build si detecta problema
```

### EasyPanel (Producción)
```env
# Variables de entorno
SQL_MIGRATIONS_STRICT=true
```

## 📊 IMPACTO

**Antes del fix:**
- ❌ Devs editaban migraciones aplicadas
- ❌ Warnings ignorados por falta de claridad
- ❌ Schema drift entre ambientes
- ❌ Imposible recrear DB desde cero
- ❌ Sin proceso claro documentado

**Después del fix:**
- ✅ Mensajes claros → acción inmediata
- ✅ Documentación completa → workflow claro
- ✅ Herramientas → crear migraciones fácil
- ✅ Advertencias visibles → prevención
- ✅ Best practices explícitas → equipo alineado

## 🚀 PRÓXIMOS PASOS

Para el equipo:
1. Leer [SQL_MIGRATIONS_BEST_PRACTICES.md](SQL_MIGRATIONS_BEST_PRACTICES.md)
2. Usar `npm run migrate:new` para nuevas migraciones
3. **NUNCA** editar archivos en sql/ después de aplicarlos
4. Si ves warning de checksum, seguir las instrucciones del mensaje

Para producción:
1. Setear `SQL_MIGRATIONS_STRICT=true` en EasyPanel
2. Esto hará que el servidor falle al iniciar si detecta migraciones editadas
3. Forzará al equipo a seguir el workflow correcto

## 📞 Recursos

- [README.md](README.md#sql-migrations) - Intro y quick reference
- [SQL_MIGRATIONS_BEST_PRACTICES.md](SQL_MIGRATIONS_BEST_PRACTICES.md) - Guía completa
- [sql/README.txt](sql/README.txt) - Advertencia en la carpeta
- Código: [src/scripts/runSqlMigrations.ts](src/scripts/runSqlMigrations.ts)
- CLI: [scripts/create-migration.js](scripts/create-migration.js)

---

**RECUERDA:** Los archivos de migración son el historial inmutable de tu schema. Una vez aplicados, son read-only. 🔒
