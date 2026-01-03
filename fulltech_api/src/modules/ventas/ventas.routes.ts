import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import {
  createVenta,
  deleteVenta,
  getVenta,
  listVentas,
  updateVenta,
} from './ventas.controller';

export const ventasRouter = Router();

ventasRouter.use(authMiddleware);

ventasRouter.get('/', expressAsyncHandler(listVentas));
ventasRouter.post('/', requireRole(['admin', 'vendedor']), expressAsyncHandler(createVenta));
ventasRouter.get('/:id', expressAsyncHandler(getVenta));
ventasRouter.put('/:id', requireRole(['admin', 'vendedor']), expressAsyncHandler(updateVenta));
ventasRouter.delete('/:id', requireRole(['admin']), expressAsyncHandler(deleteVenta));
