import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import {
  postUploadSalesEvidence,
  postUploadOperationsMedia,
  postUploadProductImage,
  postUploadUserDocs,
  uploadSalesEvidence,
  uploadOperationsMedia,
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

// Subida de evidencias de ventas
// multipart/form-data: field "file"
uploadsRouter.post(
  '/sales',
  requireRole(['admin', 'administrador', 'vendedor']),
  uploadSalesEvidence,
  expressAsyncHandler(postUploadSalesEvidence),
);

// Subida de media para Operaciones (levantamientos/instalaciones)
// multipart/form-data: field "file"
uploadsRouter.post(
  '/operations',
  requireRole(['admin', 'administrador', 'tecnico']),
  uploadOperationsMedia,
  expressAsyncHandler(postUploadOperationsMedia),
);
