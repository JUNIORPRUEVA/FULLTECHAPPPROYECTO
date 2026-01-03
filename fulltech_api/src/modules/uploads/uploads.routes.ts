import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import {
  postUploadProductImage,
  postUploadUserDocs,
  uploadProductImage,
  uploadUserDocs,
} from './uploads.controller';

export const uploadsRouter = Router();

uploadsRouter.use(authMiddleware);

// Subida de imágenes para productos/servicios
// multipart/form-data: field "file"
uploadsRouter.post(
  '/products',
  requireRole(['admin', 'administrador']),
  uploadProductImage,
  expressAsyncHandler(postUploadProductImage),
);

// Subida de documentos de usuarios/personal
// multipart/form-data: fields foto_perfil, cedula_foto, carta_ultimo_trabajo
uploadsRouter.post(
  '/users',
  requireRole(['admin', 'administrador']),
  uploadUserDocs,
  expressAsyncHandler(postUploadUserDocs),
);
