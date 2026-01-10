import expressAsyncHandler from 'express-async-handler';
import { Router } from 'express';
import { requireRole } from '../../../middleware/requireRole';
import {
  createService,
  deleteService,
  getService,
  listServices,
  updateService,
} from '../../services/services.controller';

export const settingsServicesRouter = Router();

// Read-only for any authenticated user (authMiddleware is applied at /settings root)
settingsServicesRouter.get('/', expressAsyncHandler(listServices));
settingsServicesRouter.get('/:id', expressAsyncHandler(getService));

// Admin/manager-only for modifications
settingsServicesRouter.post(
  '/',
  requireRole(['admin', 'administrador', 'asistente_administrativo']),
  expressAsyncHandler(createService),
);
settingsServicesRouter.patch(
  '/:id',
  requireRole(['admin', 'administrador', 'asistente_administrativo']),
  expressAsyncHandler(updateService),
);
settingsServicesRouter.delete(
  '/:id',
  requireRole(['admin', 'administrador', 'asistente_administrativo']),
  expressAsyncHandler(deleteService),
);

