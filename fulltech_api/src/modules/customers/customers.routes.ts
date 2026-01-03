import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { authMiddleware } from '../../middleware/auth';
import {
  createCustomer,
  deleteCustomer,
  getCustomer,
  listCustomers,
  updateCustomer,
} from './customers.controller';

export const customersRouter = Router();

customersRouter.use(authMiddleware);

customersRouter.get('/', expressAsyncHandler(listCustomers));
customersRouter.get('/:id', expressAsyncHandler(getCustomer));
customersRouter.post('/', expressAsyncHandler(createCustomer));
customersRouter.put('/:id', expressAsyncHandler(updateCustomer));
customersRouter.delete('/:id', expressAsyncHandler(deleteCustomer));
