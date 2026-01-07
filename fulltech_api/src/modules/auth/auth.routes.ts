import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { login, me, register } from './auth.controller';
import { authMiddleware } from '../../middleware/auth';

export const authRouter = Router();

authRouter.post('/register', expressAsyncHandler(register));
authRouter.post('/login', expressAsyncHandler(login));
authRouter.get('/me', authMiddleware, expressAsyncHandler(me));
