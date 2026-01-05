import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import {
  createLetter,
  createLetterExport,
  deleteLetter,
  getLetter,
  listLetters,
  markLetterSent,
  updateLetter,
} from './letters.controller';

export const lettersRouter = Router();

lettersRouter.use(authMiddleware);

lettersRouter.get('/', expressAsyncHandler(listLetters));
lettersRouter.post('/', expressAsyncHandler(createLetter));
lettersRouter.get('/:id', expressAsyncHandler(getLetter));
lettersRouter.put('/:id', expressAsyncHandler(updateLetter));
lettersRouter.delete('/:id', expressAsyncHandler(deleteLetter));
lettersRouter.post('/:id/mark-sent', expressAsyncHandler(markLetterSent));
lettersRouter.post('/:id/exports', expressAsyncHandler(createLetterExport));
