import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import multer from 'multer';
import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import {
  blockUser,
  createUser,
  deleteUser,
  getUserContractPdf,
  getUserProfilePdf,
  getUser,
  iaExtractDesdeCedula,
  iaExtractDesdeLicencia,
  listUsers,
  unblockUser,
  updateUser,
} from './users.controller';

export const usersRouter = Router();

usersRouter.use(authMiddleware);

const uploadCedulaForIa = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok = typeof file.mimetype === 'string' && file.mimetype.startsWith('image/');
    if (!ok) return cb(new Error('Solo se permiten imágenes'));
    cb(null, true);
  },
});

usersRouter.get('/', requireRole(['admin', 'administrador']), expressAsyncHandler(listUsers));
usersRouter.post('/', requireRole(['admin', 'administrador']), expressAsyncHandler(createUser));

usersRouter.get('/:id', expressAsyncHandler(getUser));
usersRouter.get('/:id/profile-pdf', expressAsyncHandler(getUserProfilePdf));
usersRouter.get('/:id/contract-pdf', expressAsyncHandler(getUserContractPdf));
usersRouter.put('/:id', expressAsyncHandler(updateUser));

usersRouter.delete('/:id', requireRole(['admin', 'administrador']), expressAsyncHandler(deleteUser));

usersRouter.patch('/:id/block', requireRole(['admin', 'administrador']), expressAsyncHandler(blockUser));
usersRouter.patch('/:id/unblock', requireRole(['admin', 'administrador']), expressAsyncHandler(unblockUser));

// IA endpoints
usersRouter.post(
  '/ia/extraer-desde-cedula',
  requireRole(['admin', 'administrador']),
  uploadCedulaForIa.single('cedula_frontal'),
  expressAsyncHandler(iaExtractDesdeCedula),
);

usersRouter.post(
  '/ia/extraer-desde-licencia',
  requireRole(['admin', 'administrador']),
  uploadCedulaForIa.single('licencia_frontal'),
  expressAsyncHandler(iaExtractDesdeLicencia),
);
