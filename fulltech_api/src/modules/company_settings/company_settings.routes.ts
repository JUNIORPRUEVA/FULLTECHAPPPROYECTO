import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import { getCompanySettings, upsertCompanySettings, uploadCompanyLogo } from './company_settings.controller';
import { uploadCompanyLogo as uploadCompanyLogoMiddleware } from './company_logo_upload';

export const companySettingsRouter = Router();

companySettingsRouter.use(authMiddleware);

companySettingsRouter.get('/', requireRole(['admin', 'administrador']), expressAsyncHandler(getCompanySettings));
companySettingsRouter.put('/', requireRole(['admin', 'administrador']), expressAsyncHandler(upsertCompanySettings));

// multipart/form-data: field "file"
companySettingsRouter.post(
	'/logo',
	requireRole(['admin', 'administrador']),
	uploadCompanyLogoMiddleware,
	expressAsyncHandler(uploadCompanyLogo),
);
