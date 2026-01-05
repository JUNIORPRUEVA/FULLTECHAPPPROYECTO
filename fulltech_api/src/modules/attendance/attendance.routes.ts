import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth';
import * as attendanceController from './attendance.controller';

const router = Router();

router.use(authMiddleware);

// Spec-compliant endpoints
router.post('/punches', attendanceController.createPunch);
router.get('/punches', attendanceController.listRecords);
router.get('/punches/:id', attendanceController.getRecord);
router.put('/punches/:id', attendanceController.updateRecord);
router.delete('/punches/:id', attendanceController.deleteRecord);

// Backward-compatible aliases
router.post('/punch', attendanceController.createPunch);
router.get('/records', attendanceController.listRecords);
router.get('/records/:id', attendanceController.getRecord);
router.put('/records/:id', attendanceController.updateRecord);
router.delete('/records/:id', attendanceController.deleteRecord);
router.get('/summary', attendanceController.getSummary);

// Admin routes
router.get('/admin/records', ...(attendanceController.adminListRecords as any));

export default router;
