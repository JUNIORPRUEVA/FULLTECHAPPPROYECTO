import { Router } from 'express';

import { getUiSettings, updateUiSettings } from './ui.controller';

export const uiSettingsRouter = Router();

uiSettingsRouter.get('/', getUiSettings);
uiSettingsRouter.put('/', updateUiSettings);
