import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { login, me, refresh, register } from './auth.controller';
import { authMiddleware } from '../../middleware/auth';

export const authRouter = Router();

authRouter.post('/register', expressAsyncHandler(register));
authRouter.post('/login', expressAsyncHandler(login));
authRouter.post('/refresh', expressAsyncHandler(refresh));
authRouter.get('/me', authMiddleware, expressAsyncHandler(me));
