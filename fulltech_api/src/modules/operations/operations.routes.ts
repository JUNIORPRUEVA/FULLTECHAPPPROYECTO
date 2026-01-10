import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import * as operationsController from './operations.controller';

export const operationsRouter = Router();

operationsRouter.use(authMiddleware);
operationsRouter.use(
  requireRole([
    'admin',
    'administrador',
    'asistente_administrativo',
    'vendedor',
    'tecnico',
    'tecnico_fijo',
    'contratista',
  ]),
);

// Jobs
operationsRouter.post('/jobs', expressAsyncHandler(operationsController.createJob));
operationsRouter.get('/jobs', expressAsyncHandler(operationsController.listJobs));
operationsRouter.get('/jobs/:id', expressAsyncHandler(operationsController.getJob));
operationsRouter.patch('/jobs/:id', expressAsyncHandler(operationsController.patchJob));
operationsRouter.get('/jobs/:id/history', expressAsyncHandler(operationsController.listJobHistory));
operationsRouter.patch('/jobs/:id/status', expressAsyncHandler(operationsController.patchJobStatus));

// Technicians (for CRM scheduling dialogs, etc.)
operationsRouter.get('/technicians', expressAsyncHandler(operationsController.listTechnicians));

// Tasks alias (single-source entity is OperationsJob)
operationsRouter.get('/tasks', expressAsyncHandler(operationsController.listJobs));
operationsRouter.get('/tasks/:id', expressAsyncHandler(operationsController.getJob));
operationsRouter.get('/tasks/:id/history', expressAsyncHandler(operationsController.listJobHistory));
operationsRouter.patch('/tasks/:id/status', expressAsyncHandler(operationsController.patchJobStatus));

// Survey
operationsRouter.post('/surveys', expressAsyncHandler(operationsController.submitSurvey));

// Scheduling
operationsRouter.post('/schedules', expressAsyncHandler(operationsController.scheduleJob));

// Installation
operationsRouter.post('/installations/start', expressAsyncHandler(operationsController.startInstallation));
operationsRouter.post('/installations/complete', expressAsyncHandler(operationsController.completeInstallation));

// Warranty
operationsRouter.post('/warranty-tickets', expressAsyncHandler(operationsController.createWarrantyTicket));
operationsRouter.patch(
  '/warranty-tickets/:id',
  expressAsyncHandler(operationsController.patchWarrantyTicket),
);
