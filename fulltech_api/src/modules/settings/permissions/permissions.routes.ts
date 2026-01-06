import { Router } from 'express';

import { requirePermission } from '../../../middleware/requirePermission';
import {
  getPermissionsCatalog,
  getMyPermissions,
  listRoles,
  listUsersWithPermissions,
  updateUserPermissions,
} from './permissions.controller';

export const permissionsRouter = Router();

permissionsRouter.get('/me', getMyPermissions);
permissionsRouter.get('/catalog', requirePermission('settings.manage'), getPermissionsCatalog);
permissionsRouter.get('/roles', requirePermission('settings.manage'), listRoles);
permissionsRouter.get('/users', requirePermission('settings.manage'), listUsersWithPermissions);
permissionsRouter.put('/users/:id', requirePermission('settings.manage'), updateUserPermissions);
