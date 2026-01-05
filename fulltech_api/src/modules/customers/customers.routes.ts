import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { authMiddleware } from '../../middleware/auth';
import {
  addCustomerNote,
  createCustomer,
  deleteCustomer,
  getCustomer,
  getCustomerChats,
  listCustomers,
  lookupProducts,
  patchCustomer,
} from './customers_simple.controller';

export const customersRouter = Router();

customersRouter.use(authMiddleware);

customersRouter.get('/', expressAsyncHandler(listCustomers));
customersRouter.get('/:id', expressAsyncHandler(getCustomer));
customersRouter.get('/:id/chats', expressAsyncHandler(getCustomerChats));
customersRouter.post('/', expressAsyncHandler(createCustomer));
customersRouter.patch('/:id', expressAsyncHandler(patchCustomer));
customersRouter.post('/:id/notes', expressAsyncHandler(addCustomerNote));
customersRouter.delete('/:id', expressAsyncHandler(deleteCustomer));

// Products lookup
export const crmProductsRouter = Router();
crmProductsRouter.use(authMiddleware);
crmProductsRouter.get('/lookup', expressAsyncHandler(lookupProducts));
