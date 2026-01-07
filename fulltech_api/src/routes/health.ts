import { Router } from 'express';
import { prisma } from '../config/prisma';

export const healthRouter = Router();

healthRouter.get('/', (_req, res) => {
  res.json({ ok: true, service: 'fulltech-api' });
});

healthRouter.get('/db', async (_req, res) => {
  const startedAt = Date.now();
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ ok: true, db: 'ok', ms: Date.now() - startedAt });
  } catch (error: any) {
    res.status(500).json({ ok: false, db: 'error', ms: Date.now() - startedAt, error: String(error?.message ?? error) });
  }
});
