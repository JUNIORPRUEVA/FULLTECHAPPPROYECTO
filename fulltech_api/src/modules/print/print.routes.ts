import { Router } from 'express';

import express from 'express';
import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/requirePermission';
import { printInvoice, printPdf, printTest } from './print.controller';

export const printRouter = Router();

printRouter.use(authMiddleware);

printRouter.get('/test', requirePermission('printing.use'), printTest);
printRouter.post(
  '/pdf',
  requirePermission('printing.use'),
  // accept raw pdf bytes
  express.raw({ type: 'application/pdf', limit: '20mb' }),
  printPdf,
);

printRouter.post('/invoice/:saleId', requirePermission('printing.use'), printInvoice);
