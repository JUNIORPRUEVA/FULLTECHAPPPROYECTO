import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { authMiddleware } from '../../middleware/auth';
import {
  createCliente,
  deleteCliente,
  getCliente,
  listClientes,
  updateCliente,
} from './clientes.controller';

export const clientesRouter = Router();

clientesRouter.use(authMiddleware);

clientesRouter.get('/', expressAsyncHandler(listClientes));
clientesRouter.post('/', expressAsyncHandler(createCliente));
clientesRouter.get('/:id', expressAsyncHandler(getCliente));
clientesRouter.put('/:id', expressAsyncHandler(updateCliente));
clientesRouter.delete('/:id', expressAsyncHandler(deleteCliente));
