import { Router } from 'express';
import { UsuariosController } from './usuarios.controller';
import { UploadsController, uploadUserDocuments } from './uploads.controller';
import { PdfController } from './pdf.controller';

const router = Router();

// ========== USUARIOS CRUD ==========
router.get('/usuarios', UsuariosController.listUsuarios);
router.get('/usuarios/:id', UsuariosController.getUsuario);
router.post('/usuarios', UsuariosController.createUsuario);
router.put('/usuarios/:id', UsuariosController.updateUsuario);
router.patch('/usuarios/:id/block', UsuariosController.blockUsuario);
router.delete('/usuarios/:id', UsuariosController.deleteUsuario);

// ========== IA - CÉDULA ==========
router.post('/usuarios/ia/cedula', UsuariosController.extractCedulaData);

// ========== UPLOADS ==========
router.post(
  '/uploads/users',
  uploadUserDocuments,
  UploadsController.uploadUserFiles,
);

// ========== PDFs ==========
router.get('/usuarios/:id/profile-pdf', PdfController.generateProfilePDF);
router.get('/usuarios/:id/contract-pdf', PdfController.generateContractPDF);

export default router;
