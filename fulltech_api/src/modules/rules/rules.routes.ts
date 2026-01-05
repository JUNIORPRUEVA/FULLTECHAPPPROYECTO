import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';

import {
  createRule,
  deleteRule,
  getRule,
  listRules,
  toggleRuleActive,
  updateRule,
} from './rules.controller';

export const rulesRouter = Router();

rulesRouter.use(authMiddleware);

// List is role-filtered server-side for non-admin users.
rulesRouter.get('/', expressAsyncHandler(listRules));
rulesRouter.get('/:id', expressAsyncHandler(getRule));

// Admin-only management
rulesRouter.post('/', requireRole(['admin', 'administrador']), expressAsyncHandler(createRule));
rulesRouter.put('/:id', requireRole(['admin', 'administrador']), expressAsyncHandler(updateRule));
rulesRouter.delete('/:id', requireRole(['admin', 'administrador']), expressAsyncHandler(deleteRule));
rulesRouter.patch(
  '/:id/toggle-active',
  requireRole(['admin', 'administrador']),
  expressAsyncHandler(toggleRuleActive),
);
