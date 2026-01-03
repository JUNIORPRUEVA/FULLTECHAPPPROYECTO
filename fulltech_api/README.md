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

## Deploy (EasyPanel)
Ver [README_EASYPANEL.md](README_EASYPANEL.md).

> TODO: Añadir más módulos y reglas de negocio por área.
