import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth';
import * as punchController from './punches.controller';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// Create punch
router.post('/', punchController.createPunch);

// List punches
router.get('/', punchController.listPunches);

// Get punch summary
router.get('/summary', punchController.getPunchesSummary);

// Get single punch
router.get('/:id', punchController.getPunch);

// Update punch
router.put('/:id', punchController.updatePunch);

// Delete punch (soft delete)
router.delete('/:id', punchController.deletePunch);

export default router;
