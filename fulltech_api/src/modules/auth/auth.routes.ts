import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { login, register } from './auth.controller';

export const authRouter = Router();

authRouter.post('/register', expressAsyncHandler(register));
authRouter.post('/login', expressAsyncHandler(login));
