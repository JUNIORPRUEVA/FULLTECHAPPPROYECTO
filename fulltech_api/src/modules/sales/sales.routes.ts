import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import { createSale, listSales } from './sales.controller';

export const salesRouter = Router();

salesRouter.use(authMiddleware);

salesRouter.get('/', expressAsyncHandler(listSales));
salesRouter.post('/', requireRole(['admin', 'vendedor']), expressAsyncHandler(createSale));
