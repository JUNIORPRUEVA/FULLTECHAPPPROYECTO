import { Router } from 'express';

import { requirePermission } from '../../../middleware/requirePermission';
import { getPrinterSettings, updatePrinterSettings } from './printer.controller';

export const printerSettingsRouter = Router();

printerSettingsRouter.get('/', requirePermission('printing.use'), getPrinterSettings);
printerSettingsRouter.put('/', requirePermission('printing.use'), updatePrinterSettings);
