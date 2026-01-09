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
import { customersRouter, crmProductsRouter } from '../modules/customers/customers.routes';
import { salesRouter } from '../modules/sales/sales.routes';
import { adminRouter } from '../modules/webhooks/admin.routes';
import { webhooksRouter } from '../modules/webhooks/webhooks.routes';
import { integrationsRouter } from '../modules/integrations/integrations.routes';
import { aiRouter } from '../modules/ai/ai.routes';
import punchesRouter from '../modules/punches/punches.routes';
import attendanceRouter from '../modules/attendance/attendance.routes';
import maintenanceRouter from '../modules/maintenance/maintenance.routes';
import payrollRouter from '../modules/payroll/payroll.routes';
import { quotationsRouter } from '../modules/quotations/quotations.routes';
import { lettersRouter } from '../modules/letters/letters.routes';
import { operationsRouter } from '../modules/operations/operations.routes';
import { rulesRouter } from '../modules/rules/rules.routes';
import { posRouter } from '../modules/pos/pos.routes';
import { inventoryRouter } from '../modules/inventory/inventory.routes';
import { settingsRouter } from '../modules/settings/settings.routes';
import { printRouter } from '../modules/print/print.routes';
import { servicesRouter } from '../modules/services/services.routes';
import { agendaRouter } from '../modules/agenda/agenda.routes';

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
apiRouter.use('/crm/products', crmProductsRouter); // /api/crm/products/lookup
apiRouter.use('/sales', salesRouter);
apiRouter.use('/integrations', integrationsRouter);
apiRouter.use('/ai', aiRouter);
apiRouter.use('/punches', punchesRouter);
apiRouter.use('/attendance', attendanceRouter);
apiRouter.use('/', maintenanceRouter); // maintenance, warranty, inventory-audits
apiRouter.use('/', payrollRouter); // payroll (admin) + my/payroll (employee)
apiRouter.use('/quotations', quotationsRouter);
apiRouter.use('/letters', lettersRouter);
apiRouter.use('/operations', operationsRouter);
apiRouter.use('/rules', rulesRouter);
apiRouter.use('/admin', adminRouter);
apiRouter.use('/pos', posRouter);
apiRouter.use('/inventory', inventoryRouter);
apiRouter.use('/settings', settingsRouter);
apiRouter.use('/print', printRouter);
apiRouter.use('/services', servicesRouter);
apiRouter.use('/operations/agenda', agendaRouter);

// TODO: Montar módulos restantes (operaciones, nómina, rrhh, guagua, etc.)
