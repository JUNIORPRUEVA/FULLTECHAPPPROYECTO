import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';

import * as payrollController from './payroll.controller';
import * as myPayrollController from './my_payroll.controller';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// === ADMIN payroll ===
router.post('/payroll/periods/ensure-current', requireRole(['admin']), payrollController.ensureCurrentPeriods);
router.post('/payroll/runs', requireRole(['admin']), payrollController.createPayrollRun);
router.get('/payroll/runs', requireRole(['admin']), payrollController.listPayrollRuns);
router.get('/payroll/runs/:runId', requireRole(['admin']), payrollController.getPayrollRun);
router.post('/payroll/runs/:runId/import-movements', requireRole(['admin']), payrollController.importMovements);
router.post('/payroll/runs/:runId/recalculate', requireRole(['admin']), payrollController.recalculateRun);
router.post('/payroll/runs/:runId/approve', requireRole(['admin']), payrollController.approveRun);
router.post('/payroll/runs/:runId/mark-paid', requireRole(['admin']), payrollController.markPaid);

// Movements CRUD
router.post('/payroll/movements', requireRole(['admin']), payrollController.createMovement);
router.get('/payroll/movements', requireRole(['admin']), payrollController.listMovements);
router.put('/payroll/movements/:id', requireRole(['admin']), payrollController.updateMovement);
router.delete('/payroll/movements/:id', requireRole(['admin']), payrollController.voidMovement);

// === EMPLOYEE payroll ===
router.get('/my/payroll', myPayrollController.myPayrollHistory);
router.get('/my/payroll/notifications', myPayrollController.myPayrollNotifications);
router.get('/my/payroll/:runId', myPayrollController.myPayrollDetail);

export default router;
