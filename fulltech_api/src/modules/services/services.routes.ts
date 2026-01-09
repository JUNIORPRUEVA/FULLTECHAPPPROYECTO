import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { authMiddleware } from '../../middleware/auth';
import {
  listServices,
  getService,
  createService,
  updateService,
  deleteService,
} from './services.controller';

export const servicesRouter = Router();

servicesRouter.use(authMiddleware);

servicesRouter.get('/', expressAsyncHandler(listServices));
servicesRouter.get('/:id', expressAsyncHandler(getService));
servicesRouter.post('/', expressAsyncHandler(createService));
servicesRouter.put('/:id', expressAsyncHandler(updateService));
servicesRouter.delete('/:id', expressAsyncHandler(deleteService));
