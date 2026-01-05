import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import {
	createQuotation,
	deleteQuotation,
	duplicateQuotation,
	getQuotation,
	listQuotations,
	sendQuotation,
	updateQuotation,
} from './quotations.controller';

export const quotationsRouter = Router();

quotationsRouter.use(authMiddleware);

quotationsRouter.get('/', expressAsyncHandler(listQuotations));
quotationsRouter.get('/:id', expressAsyncHandler(getQuotation));
quotationsRouter.post('/', expressAsyncHandler(createQuotation));
quotationsRouter.put('/:id', expressAsyncHandler(updateQuotation));
quotationsRouter.post('/:id/duplicate', expressAsyncHandler(duplicateQuotation));
quotationsRouter.delete('/:id', expressAsyncHandler(deleteQuotation));
quotationsRouter.post('/:id/send', expressAsyncHandler(sendQuotation));
