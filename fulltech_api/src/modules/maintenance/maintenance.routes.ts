import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import * as maintenanceController from './maintenance.controller';
import * as warrantyController from './warranty.controller';
import * as auditController from './audit.controller';

const router = Router();

// All routes require authentication and admin/assistant role
router.use(authMiddleware);
router.use(requireRole(['admin', 'administrador', 'asistente_administrativo']));

// === MAINTENANCE ===
router.get('/maintenance/summary', maintenanceController.getMaintenanceSummary);
router.post('/maintenance', maintenanceController.createMaintenance);
router.get('/maintenance', maintenanceController.listMaintenance);
router.get('/maintenance/:id', maintenanceController.getMaintenance);
router.put('/maintenance/:id', maintenanceController.updateMaintenance);
router.delete('/maintenance/:id', maintenanceController.deleteMaintenance);

// === WARRANTY ===
router.get('/warranty/summary', warrantyController.getWarrantySummary);
router.post('/warranty', warrantyController.createWarranty);
router.get('/warranty', warrantyController.listWarranty);
router.get('/warranty/:id', warrantyController.getWarranty);
router.put('/warranty/:id', warrantyController.updateWarranty);
router.delete('/warranty/:id', warrantyController.deleteWarranty);

// === INVENTORY AUDITS ===
router.post('/inventory-audits', auditController.createAudit);
router.get('/inventory-audits', auditController.listAudits);
router.get('/inventory-audits/:id', auditController.getAudit);
router.put('/inventory-audits/:id', auditController.updateAudit);
router.get('/inventory-audits/:id/items', auditController.getAuditItems);
router.post('/inventory-audits/:id/items', auditController.upsertAuditItem);
router.delete('/inventory-audits/:id/items/:itemId', auditController.deleteAuditItem);

export default router;
