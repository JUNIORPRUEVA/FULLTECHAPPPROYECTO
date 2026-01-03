import { Router } from 'express';
import { healthRouter } from './health';
import { authRouter } from '../modules/auth/auth.routes';
import { clientesRouter } from '../modules/clientes/clientes.routes';
import { ventasRouter } from '../modules/ventas/ventas.routes';
import { catalogRouter } from '../modules/catalog/catalog.routes';
import { uploadsRouter } from '../modules/uploads/uploads.routes';
import { usersRouter } from '../modules/users/users.routes';
import { companySettingsRouter } from '../modules/company_settings/company_settings.routes';
import { crmRouter } from '../modules/crm/crm.routes';
import { customersRouter } from '../modules/customers/customers.routes';
import { salesRouter } from '../modules/sales/sales.routes';
import { adminRouter } from '../modules/webhooks/admin.routes';
import { webhooksRouter } from '../modules/webhooks/webhooks.routes';

export const apiRouter = Router();

// Webhook alias (some reverse proxies only forward /api/*)
// Canonical public path is mounted at /webhooks/* in src/index.ts
apiRouter.use('/webhooks', webhooksRouter);

apiRouter.use('/health', healthRouter);
apiRouter.use('/auth', authRouter);
apiRouter.use('/clientes', clientesRouter);
apiRouter.use('/ventas', ventasRouter);
apiRouter.use('/catalog', catalogRouter);
apiRouter.use('/uploads', uploadsRouter);
apiRouter.use('/users', usersRouter);
apiRouter.use('/company-settings', companySettingsRouter);
apiRouter.use('/crm', crmRouter);
apiRouter.use('/customers', customersRouter);
apiRouter.use('/sales', salesRouter);
apiRouter.use('/admin', adminRouter);

// TODO: Montar módulos restantes (operaciones, garantía, nómina, rrhh, guagua, etc.)
