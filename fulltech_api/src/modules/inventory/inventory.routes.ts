import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/requirePermission';
import {
  addStock,
  adjustStock,
  getProductKardex,
  listInventoryProducts,
  updateProductMinMax,
} from './inventory.controller';

export const inventoryRouter = Router();

inventoryRouter.use(authMiddleware);

inventoryRouter.get('/products', requirePermission('inventory.view'), expressAsyncHandler(listInventoryProducts));
inventoryRouter.get('/products/:id/kardex', requirePermission('inventory.view'), expressAsyncHandler(getProductKardex));

// Admin/manager only (administrador treated as manager)
inventoryRouter.post('/add-stock', requirePermission('inventory.manage'), expressAsyncHandler(addStock));
inventoryRouter.post('/adjust-stock', requirePermission('inventory.manage'), expressAsyncHandler(adjustStock));
inventoryRouter.put('/products/:id/minmax', requirePermission('inventory.manage'), expressAsyncHandler(updateProductMinMax));
