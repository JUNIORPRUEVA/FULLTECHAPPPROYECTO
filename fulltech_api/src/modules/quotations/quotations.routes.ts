import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import {
	convertQuotationToTicket,
	createQuotation,
	deleteQuotation,
	duplicateQuotation,
	getQuotation,
	listQuotations,
	sendQuotation,
	sendQuotationWhatsappPdf,
	updateQuotation,
} from './quotations.controller';

export const quotationsRouter = Router();

quotationsRouter.use(authMiddleware);

quotationsRouter.get('/', expressAsyncHandler(listQuotations));
quotationsRouter.get('/:id', expressAsyncHandler(getQuotation));
quotationsRouter.post('/', expressAsyncHandler(createQuotation));
quotationsRouter.put('/:id', expressAsyncHandler(updateQuotation));
quotationsRouter.post('/:id/duplicate', expressAsyncHandler(duplicateQuotation));
quotationsRouter.post('/:id/convert-to-ticket', expressAsyncHandler(convertQuotationToTicket));
quotationsRouter.delete('/:id', expressAsyncHandler(deleteQuotation));
quotationsRouter.post('/:id/send', expressAsyncHandler(sendQuotation));
quotationsRouter.post(
	'/:id/send-whatsapp-pdf',
	expressAsyncHandler(sendQuotationWhatsappPdf),
);
