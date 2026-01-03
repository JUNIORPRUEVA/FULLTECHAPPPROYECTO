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
import { webhooksRouter } from '../modules/webhooks/webhooks.routes';
import { salesRouter } from '../modules/sales/sales.routes';

export const apiRouter = Router();

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
apiRouter.use('/webhooks', webhooksRouter);
apiRouter.use('/sales', salesRouter);

// TODO: Montar módulos restantes (operaciones, garantía, nómina, rrhh, guagua, etc.)
