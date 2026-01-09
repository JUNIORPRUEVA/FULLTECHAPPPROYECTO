import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { authMiddleware } from '../../middleware/auth';
import {
  listAgendaItems,
  getAgendaItem,
  createAgendaItem,
  updateAgendaItem,
  deleteAgendaItem,
} from './agenda.controller';

export const agendaRouter = Router();

agendaRouter.use(authMiddleware);

agendaRouter.get('/', expressAsyncHandler(listAgendaItems));
agendaRouter.get('/:id', expressAsyncHandler(getAgendaItem));
agendaRouter.post('/', expressAsyncHandler(createAgendaItem));
agendaRouter.put('/:id', expressAsyncHandler(updateAgendaItem));
agendaRouter.delete('/:id', expressAsyncHandler(deleteAgendaItem));
