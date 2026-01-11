import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import {
  createLetter,
  createLetterExport,
  deleteLetter,
  generatePDF,
  generateWithAI,
  getLetter,
  listLetters,
  markLetterSent,
  sendWhatsApp,
  updateLetter,
} from './letters.controller';

export const lettersRouter = Router();

lettersRouter.use(authMiddleware);

lettersRouter.get('/', expressAsyncHandler(listLetters));
lettersRouter.post('/', expressAsyncHandler(createLetter));
lettersRouter.post('/generate-ai', expressAsyncHandler(generateWithAI));
lettersRouter.get('/:id', expressAsyncHandler(getLetter));
lettersRouter.put('/:id', expressAsyncHandler(updateLetter));
lettersRouter.delete('/:id', expressAsyncHandler(deleteLetter));
lettersRouter.get('/:id/pdf', expressAsyncHandler(generatePDF));
lettersRouter.post('/:id/mark-sent', expressAsyncHandler(markLetterSent));
lettersRouter.post('/:id/send-whatsapp', expressAsyncHandler(sendWhatsApp));
lettersRouter.post('/:id/exports', expressAsyncHandler(createLetterExport));
