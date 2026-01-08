# FULLTECH API (Node.js + TypeScript + Express + Prisma)

## Requisitos
- Node.js 18+
- PostgreSQL

## Setup rápido
1. Crear `.env` (puedes copiar de `.env.example`).
2. Instalar dependencias:
   - `npm install`
3. Generar Prisma Client:
   - `npm run prisma:generate`
4. Migrar BD (dev):
   - `npm run prisma:migrate`
5. Levantar en desarrollo:
   - `npm run dev`

## Endpoints base
- `POST /auth/register`
- `POST /auth/login`
- `GET /api/health`
- `CRUD /clientes`
- `CRUD /ventas`

## SQL Migrations

El proyecto usa un sistema automático de migraciones SQL que:
- Lee archivos `.sql` de la carpeta `sql/` en orden alfabético
- Rastrea qué archivos ya fueron aplicados usando checksums
- Previene re-aplicar migraciones ya ejecutadas
- Detecta si un archivo fue editado después de aplicarse

### ⚠️ REGLA DE ORO: Nunca edites migraciones ya aplicadas

Una vez que un archivo SQL ha sido aplicado a CUALQUIER ambiente (dev, staging, prod):
- ❌ **NO lo edites** - esto rompe el historial de migraciones
- ✅ **Crea un archivo nuevo** con tus cambios

### Crear una nueva migración

```bash
# Formato: YYYY-MM-DD_descripcion.sql
sql/2026-01-07_add_user_status_column.sql
```

Ejemplo:
```sql
-- sql/2026-01-07_add_user_status_column.sql
ALTER TABLE users ADD COLUMN status text DEFAULT 'active';
```

### Variables de entorno

- `SKIP_SQL_MIGRATIONS=true` - deshabilita el sistema de migraciones
- `SQL_MIGRATIONS_STRICT=true` - convierte warnings en errores (recomendado para CI/CD)

### Troubleshooting

**Problema**: "Checksum changed for X.sql"
- **Causa**: Editaste un archivo después de aplicarlo
- **Solución**: 
  1. Revertir cambios al archivo original
  2. Crear un nuevo archivo con fecha actual
  3. Poner tus cambios en el nuevo archivo

Ver [SQL_MIGRATIONS_BEST_PRACTICES.md](SQL_MIGRATIONS_BEST_PRACTICES.md) para más detalles.

## Deploy (EasyPanel)
Ver [README_EASYPANEL.md](README_EASYPANEL.md).

> TODO: Añadir más módulos y reglas de negocio por área.
