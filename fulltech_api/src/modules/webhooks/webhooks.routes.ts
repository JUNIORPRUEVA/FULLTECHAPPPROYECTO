import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { evolutionWebhook } from './evolution_webhook.controller';

export const webhooksRouter = Router();

// NOTE: Webhooks are generally unauthenticated, protected by a secret header.
webhooksRouter.post('/evolution', expressAsyncHandler(evolutionWebhook));
