# SQL Migrations - Best Practices & Workflow

## Overview

Este proyecto usa un sistema de migraciones SQL basado en checksums que:
- Lee archivos `.sql` de `sql/` en orden alfabético
- Ejecuta solo los archivos que aún no han sido aplicados
- Guarda un checksum (hash SHA-256) de cada archivo aplicado
- **Detecta automáticamente si un archivo fue editado después de aplicarse**

## 🎯 Regla de Oro

**NUNCA edites un archivo de migración después de que ha sido aplicado a CUALQUIER base de datos (dev, staging, production).**

Si necesitas cambiar el schema:
1. ✅ Crea un NUEVO archivo de migración
2. ❌ NO edites archivos existentes

## 📋 Workflow Correcto

### Paso 1: Crear nueva migración

```bash
# Formato del nombre: YYYY-MM-DD_descripcion_breve.sql
touch sql/2026-01-07_add_email_verification.sql
```

### Paso 2: Escribir el SQL

```sql
-- sql/2026-01-07_add_email_verification.sql
-- Purpose: Add email verification columns to users table

ALTER TABLE users 
  ADD COLUMN email_verified boolean DEFAULT false,
  ADD COLUMN email_verification_token text,
  ADD COLUMN email_verification_expires_at timestamptz;

CREATE INDEX idx_users_email_verification 
  ON users(email_verification_token) 
  WHERE email_verification_token IS NOT NULL;
```

**Tips**:
- Añade comentarios explicando el propósito
- Usa operaciones idempotentes cuando sea posible (CREATE IF NOT EXISTS, etc.)
- No uses transacciones explícitas (BEGIN/COMMIT) - el runner las maneja
- Prueba el SQL localmente antes de commitear

### Paso 3: Aplicar la migración

Las migraciones se aplican automáticamente al iniciar el servidor:

```bash
npm run dev
# o
npm start
```

Verás en los logs:
```
[SQL_MIGRATIONS] Found 21 .sql files
[SQL_MIGRATIONS] Applying 2026-01-07_add_email_verification.sql...
[SQL_MIGRATIONS] Applied 2026-01-07_add_email_verification.sql
```

### Paso 4: Commitear el archivo

```bash
git add sql/2026-01-07_add_email_verification.sql
git commit -m "feat: add email verification columns to users"
git push
```

## ⚠️ Qué pasa si editas una migración ya aplicada

Si editas un archivo que ya fue aplicado, el sistema detectará el cambio de checksum:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  MIGRATION CHECKSUM MISMATCH: 2026-01-05_maintenance_module.sql
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This file was edited AFTER it was already applied to the database.

  Applied checksum:  abc123def456...
  Current checksum:  789xyz012abc...

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

### Cómo solucionarlo:

```bash
# 1. Revertir el archivo editado
git checkout HEAD -- sql/2026-01-05_maintenance_module.sql

# 2. Crear un nuevo archivo con tus cambios
touch sql/2026-01-07_update_maintenance_schema.sql

# 3. Escribir los cambios en el nuevo archivo
# (el contenido que querías agregar al archivo viejo)

# 4. Commitear ambos cambios
git add sql/2026-01-05_maintenance_module.sql  # reverted
git add sql/2026-01-07_update_maintenance_schema.sql  # new
git commit -m "fix: revert edited migration + create new one"
```

## 🔧 Variables de Entorno

### `SKIP_SQL_MIGRATIONS`
```bash
# Deshabilita completamente el sistema de migraciones
SKIP_SQL_MIGRATIONS=true
```

Útil cuando:
- Estás desarrollando y no quieres esperar las migraciones
- El servidor debe iniciar sin base de datos (testing, CI)

### `SQL_MIGRATIONS_STRICT`
```bash
# Convierte warnings en errores fatales
SQL_MIGRATIONS_STRICT=true
```

**Recomendado para**:
- ✅ Ambientes de producción (previene deploys con migraciones editadas)
- ✅ CI/CD pipelines (falla el build si detecta problemas)
- ❌ Desarrollo local (permite experimentar más libremente)

**Comportamiento**:

| Situación | STRICT=false (default) | STRICT=true |
|-----------|------------------------|-------------|
| Checksum diferente | ⚠️ Warning + SKIP | ❌ Error + CRASH |
| Archivo nuevo | ✅ Aplica | ✅ Aplica |
| Sin cambios | ✅ Skip silencioso | ✅ Skip silencioso |

## 📊 Tabla de Control: `_sql_migrations`

El sistema guarda el estado en una tabla interna:

```sql
CREATE TABLE _sql_migrations (
  filename text PRIMARY KEY,
  checksum text NOT NULL,
  applied_at timestamptz NOT NULL DEFAULT now()
);
```

### Ver historial de migraciones aplicadas:

```sql
SELECT filename, 
       LEFT(checksum, 12) as checksum_prefix,
       applied_at
FROM _sql_migrations
ORDER BY applied_at DESC;
```

Resultado:
```
filename                              | checksum_prefix | applied_at
--------------------------------------|-----------------|--------------------------
2026-01-07_crm_messages_empresa_id.sql| a3f5d8c9b2e1   | 2026-01-07 10:23:45+00
2026-01-06_pos_module.sql            | 7b9c4e1a6d3f   | 2026-01-06 15:12:30+00
2026-01-05_maintenance_module.sql    | 5e2a8f3c9d1b   | 2026-01-05 09:45:12+00
```

### Resetear una migración (SOLO EN DEV)

```sql
-- ⚠️ PELIGRO: Solo hacer esto en desarrollo local
DELETE FROM _sql_migrations WHERE filename = '2026-01-07_my_test.sql';

-- Ahora puedes re-aplicar la migración editada
-- (pero recuerda: en prod NUNCA hagas esto)
```

## 🚫 Anti-Patterns (NO hacer)

### ❌ Editar archivo ya aplicado
```bash
# MAL: Editar un archivo viejo
vim sql/2026-01-02_crm_customers.sql  # ya aplicado hace días
```

**Consecuencia**: Checksum mismatch, migración skipeada, schema drift.

### ❌ Eliminar archivos aplicados
```bash
# MAL: Borrar un archivo de migración
rm sql/2026-01-03_payroll_quincenal.sql
```

**Consecuencia**: 
- El registro en `_sql_migrations` queda huérfano
- Imposible recrear la BD desde cero
- Otros devs no podrán replicar tu schema

### ❌ Renombrar archivos aplicados
```bash
# MAL: Cambiar el nombre de un archivo
mv sql/2026-01-04_letters.sql sql/2026-01-04_cartas.sql
```

**Consecuencia**: 
- El sistema lo verá como una migración nueva
- Intentará aplicarlo de nuevo (posible error de "table already exists")
- Historial roto

### ❌ Cambiar orden alfabético retroactivamente
```bash
# MAL: Agregar un archivo con fecha anterior
touch sql/2026-01-03_forgot_this.sql  # fecha entre archivos ya aplicados
```

**Consecuencia**:
- En ambientes nuevos: se aplicará en orden correcto
- En ambientes existentes: se aplicará DESPUÉS (fuera de orden)
- Posible inconsistencia si depende de otros cambios

## ✅ Patterns Correctos

### ✅ Siempre crear archivos nuevos
```bash
# BIEN: Archivo nuevo con fecha actual
touch sql/2026-01-07_add_user_preferences.sql
```

### ✅ Usar operaciones idempotentes
```sql
-- BIEN: Puede ejecutarse múltiples veces sin error
CREATE TABLE IF NOT EXISTS user_preferences (
  user_id bigint PRIMARY KEY REFERENCES users(id),
  theme text DEFAULT 'light',
  language text DEFAULT 'es'
);

-- BIEN: No falla si la columna ya existe
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS avatar_url text;

-- BIEN: Índice con IF NOT EXISTS (Postgres 9.5+)
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
```

### ✅ Documentar dependencias
```sql
-- sql/2026-01-07_add_order_items.sql
-- DEPENDS ON: 2026-01-06_create_orders_table.sql
-- Purpose: Add items table that references orders

CREATE TABLE order_items (
  id bigserial PRIMARY KEY,
  order_id bigint NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id bigint NOT NULL,
  quantity int NOT NULL,
  price decimal(10,2) NOT NULL
);
```

### ✅ Usar migraciones de rollback (opcional)
```sql
-- sql/2026-01-07_add_user_level.sql
ALTER TABLE users ADD COLUMN level int DEFAULT 1;

-- Si necesitas revertir, crea:
-- sql/2026-01-07_rollback_user_level.sql
-- ALTER TABLE users DROP COLUMN level;
```

## 🔍 Debugging

### Ver migraciones pendientes (manualmente)
```bash
# En la carpeta sql/
ls -1 *.sql | sort

# Comparar con BD
psql $DATABASE_URL -c "SELECT filename FROM _sql_migrations ORDER BY filename;"
```

### Forzar re-aplicación (SOLO DEV)
```sql
-- 1. Borrar registro de migración
DELETE FROM _sql_migrations WHERE filename = '2026-01-07_test.sql';

-- 2. Reiniciar servidor
npm run dev
-- La migración se aplicará de nuevo
```

### Verificar checksum actual
```bash
# En terminal
sha256sum sql/2026-01-05_maintenance_module.sql

# En Node.js
node -e "
const fs = require('fs');
const crypto = require('crypto');
const content = fs.readFileSync('sql/2026-01-05_maintenance_module.sql', 'utf8');
console.log(crypto.createHash('sha256').update(content, 'utf8').digest('hex'));
"
```

## 🎓 Resumen

| ✅ DO | ❌ DON'T |
|-------|----------|
| Crear archivos nuevos | Editar archivos aplicados |
| Usar `IF NOT EXISTS` | Asumir que tablas no existen |
| Documentar dependencias | Crear migraciones huérfanas |
| Usar fechas consistentes | Cambiar fechas pasadas |
| Commitear archivos SQL | Ignorar archivos en .gitignore |
| Probar localmente primero | Aplicar sin probar |
| Usar STRICT=true en prod | Ignorar warnings |

## 📞 Ayuda

Si encuentras un problema:
1. Lee el error completo (tiene instrucciones específicas)
2. Revisa este documento
3. Busca en `_sql_migrations` qué se aplicó
4. En duda: crea un archivo nuevo (nunca edites viejos)

---

**Remember**: Los archivos de migración son el historial inmutable de tu schema. Una vez aplicados, son read-only.
