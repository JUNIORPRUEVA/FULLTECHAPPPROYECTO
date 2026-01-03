import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { prisma } from '../../config/prisma';
import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';

export const adminRouter = Router();

// Admin-only debug endpoints
adminRouter.use(authMiddleware);
adminRouter.use(requireRole(['admin']));

// ==============================================================
// GET /api/admin/webhook-events - List recent webhook events
// ==============================================================
adminRouter.get(
  '/webhook-events',
  expressAsyncHandler(async (req, res) => {
    const limit = Math.min(parseInt(req.query.limit as string) || 50, 200);

    const events = await prisma.crmWebhookEvent.findMany({
      orderBy: { created_at: 'desc' },
      take: limit,
      select: {
        id: true,
        created_at: true,
        event_type: true,
        payload: true,
      } as any,
    });

    res.json({ events });
  }),
);

// ==============================================================
// GET /api/admin/webhook-events/:id - Get single event details
// ==============================================================
adminRouter.get(
  '/webhook-events/:id',
  expressAsyncHandler(async (req, res) => {
    const { id } = req.params;

    const event = await prisma.crmWebhookEvent.findUnique({
      where: { id },
    });

    if (!event) {
      res.status(404).json({ error: 'Event not found' });
      return;
    }

    res.json({ event });
  }),
);
