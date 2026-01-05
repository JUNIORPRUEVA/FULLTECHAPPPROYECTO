import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import {
  getAiSettings,
  getAiSettingsPublic,
  generateLetter,
  patchAiSettings,
  suggestAiReplies,
} from './ai.controller';

export const aiRouter = Router();

aiRouter.use(authMiddleware);

aiRouter.get('/settings/public', expressAsyncHandler(getAiSettingsPublic));
aiRouter.get(
  '/settings',
  requireRole(['admin', 'administrador']),
  expressAsyncHandler(getAiSettings),
);
aiRouter.patch(
  '/settings',
  requireRole(['admin', 'administrador']),
  expressAsyncHandler(patchAiSettings),
);

aiRouter.post('/suggest', expressAsyncHandler(suggestAiReplies));
aiRouter.post('/generate-letter', expressAsyncHandler(generateLetter));
