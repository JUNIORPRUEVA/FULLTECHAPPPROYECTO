# Deploy FULLTECH API to EasyPanel

## 1) Build/Run
- Use the included `Dockerfile` (multi-stage build).
- Expose container port `3000`.
- Add a persistent volume for `/app/uploads`.

## 2) Required environment variables
Set these in EasyPanel (Secrets/Env):

- `NODE_ENV=production`
- `PORT=3000` (or let EasyPanel map it; app reads `PORT`)
- `JWT_SECRET=...`
- `DATABASE_URL=postgresql://...`

## 3) Recommended environment variables
- `CORS_ORIGIN=https://tu-frontend-dominio` (comma separated allowed)
- `PUBLIC_BASE_URL=https://tu-api-dominio` (IMPORTANT for absolute media URLs)
- `UPLOADS_DIR=./uploads`
- `MAX_UPLOAD_MB=25`

## 4) Evolution WhatsApp (CRM)
If you use Evolution API:
- `EVOLUTION_BASE_URL=https://...`
- `EVOLUTION_API_KEY=...`
- `EVOLUTION_INSTANCE=fulltech`
- `WEBHOOK_SECRET=...` (optional but recommended)

Configure Evolution webhook URL to:
- `https://tu-api-dominio/webhooks/evolution`

## 5) Health check
- `GET https://tu-api-dominio/api/health`

## 6) Database: migraciones SQL
Este repo incluye scripts SQL en `fulltech_api/sql/` para crear/actualizar tablas en Postgres.

### Automático (recomendado)
El backend aplica automáticamente los `.sql` dentro de `fulltech_api/sql/` al arrancar y guarda un registro en la tabla `_sql_migrations`.

- Para desactivar (por seguridad/entornos controlados): `SKIP_SQL_MIGRATIONS=true`
- Para forzar modo estricto (si un .sql cambió de checksum, el backend falla): `SQL_MIGRATIONS_STRICT=true`
- Para verificar conexión a Postgres: `GET /api/health/db`

### Manual (si lo necesitas)
Si prefieres hacerlo manualmente, en EasyPanel (o tu proveedor) abre el panel de tu Postgres y ejecuta los scripts necesarios.

### Scripts SQL recomendados

- Módulo Mantenimiento / Garantías / Auditorías: `sql/2026-01-05_maintenance_module.sql`

Ejecuta el script en tu Postgres (local o nube) antes de probar los endpoints del módulo.

## Notes
- Chats/mensajes se crean cuando llega un webhook de Evolution a `/webhooks/evolution`.
- Si tu backend está local, Evolution en la nube no podrá enviar webhooks. Deploy público o túnel.
