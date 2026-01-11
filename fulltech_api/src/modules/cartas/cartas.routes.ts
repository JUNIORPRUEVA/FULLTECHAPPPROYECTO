import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import {
  deleteCarta,
  generateCarta,
  getCarta,
  getCartaPdf,
  listCartas,
  sendCartaWhatsApp,
} from './cartas.controller';

export const cartasRouter = Router();

cartasRouter.use(authMiddleware);

cartasRouter.post('/generate', expressAsyncHandler(generateCarta));
cartasRouter.get('/', expressAsyncHandler(listCartas));
cartasRouter.get('/:id', expressAsyncHandler(getCarta));
cartasRouter.get('/:id/pdf', expressAsyncHandler(getCartaPdf));
cartasRouter.delete('/:id', expressAsyncHandler(deleteCarta));
cartasRouter.post('/:id/send-whatsapp', expressAsyncHandler(sendCartaWhatsApp));
