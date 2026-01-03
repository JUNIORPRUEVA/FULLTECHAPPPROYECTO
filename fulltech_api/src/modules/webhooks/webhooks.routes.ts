import express, { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { evolutionWebhook } from './evolution_webhook.controller';

export const webhooksRouter = Router();

// Some Evolution deployments send JSON with a non-standard content-type.
// We accept raw text and parse JSON best-effort in the handler below.
webhooksRouter.use(express.text({ type: '*/*', limit: '10mb' }));

// Simple connectivity check from browser/curl.
webhooksRouter.get('/evolution', (_req, res) => {
	res.json({ ok: true });
});

// NOTE: Webhooks are generally unauthenticated, protected by a secret header.
webhooksRouter.post(
	'/evolution',
	expressAsyncHandler(async (req, res) => {
		if (typeof req.body === 'string' && req.body.trim().length > 0) {
			try {
				(req as any).body = JSON.parse(req.body);
			} catch {
				// keep raw string; controller will treat it as unknown shape
			}
		}
		return evolutionWebhook(req, res);
	}),
);
