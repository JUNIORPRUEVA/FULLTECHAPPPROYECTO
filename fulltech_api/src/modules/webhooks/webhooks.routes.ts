import express, { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { evolutionWebhook } from './evolution_webhook.controller';

export const webhooksRouter = Router();

// Some Evolution deployments send JSON with a non-standard content-type.
// We accept raw text and parse JSON best-effort in the handler below.
webhooksRouter.use(express.text({ type: '*/*', limit: '10mb' }));

// ==============================================================
// PING ENDPOINT - Test connectivity from browser/curl
// ==============================================================
webhooksRouter.get('/evolution/ping', (_req, res) => {
	res.json({ ok: true, message: 'Evolution webhook is reachable', timestamp: new Date().toISOString() });
});

// ==============================================================
// TEST ENDPOINT - Insert dummy payload for testing
// ==============================================================
webhooksRouter.post('/evolution/test', expressAsyncHandler(async (req, res) => {
	const testPayload = {
		test: true,
		timestamp: new Date().toISOString(),
		userAgent: req.get('user-agent') || 'unknown',
		...req.body,
	};
	
	console.log('[WEBHOOK] TEST endpoint hit', { ip: req.ip, userAgent: req.get('user-agent') });
	
	// Process as normal webhook
	(req as any).body = testPayload;
	return evolutionWebhook(req, res);
}));

// ==============================================================
// MAIN WEBHOOK - Receives events from Evolution API
// ==============================================================
// NOTE: Webhooks are generally unauthenticated, protected by a secret header.
// This endpoint is PUBLIC and does NOT require authentication.
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

// Legacy GET endpoint (kept for backwards compatibility)
webhooksRouter.get('/evolution', (_req, res) => {
	res.json({ ok: true, message: 'Use POST to send webhook events' });
});

