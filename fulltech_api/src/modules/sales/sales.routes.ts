import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import {
	addSaleEvidence,
	createSale,
	deleteSale,
	getSale,
	listSales,
	updateSale,
} from './sales.controller';

export const salesRouter = Router();

salesRouter.use(authMiddleware);

salesRouter.get('/', expressAsyncHandler(listSales));
salesRouter.post('/', requireRole(['admin', 'vendedor']), expressAsyncHandler(createSale));

salesRouter.get('/:id', expressAsyncHandler(getSale));
salesRouter.put('/:id', requireRole(['admin', 'vendedor']), expressAsyncHandler(updateSale));
salesRouter.delete('/:id', requireRole(['admin', 'vendedor']), expressAsyncHandler(deleteSale));

salesRouter.post('/:id/evidence', requireRole(['admin', 'vendedor']), expressAsyncHandler(addSaleEvidence));
