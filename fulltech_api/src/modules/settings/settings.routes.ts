import { Router } from 'express';

import { authMiddleware } from '../../middleware/auth';
import { permissionsRouter } from './permissions/permissions.routes';
import { printerSettingsRouter } from './printer/printer.routes';
import { uiSettingsRouter } from './ui/ui.routes';

export const settingsRouter = Router();

settingsRouter.use(authMiddleware);

settingsRouter.use('/permissions', permissionsRouter);
settingsRouter.use('/printer', printerSettingsRouter);
settingsRouter.use('/ui', uiSettingsRouter);
