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

## Notes
- Chats/mensajes se crean cuando llega un webhook de Evolution a `/webhooks/evolution`.
- Si tu backend está local, Evolution en la nube no podrá enviar webhooks. Deploy público o túnel.
