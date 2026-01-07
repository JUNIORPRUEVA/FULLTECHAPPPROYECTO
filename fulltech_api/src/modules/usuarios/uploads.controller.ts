import { Request, Response } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';

import { resolveUploadsRoot } from '../../services/uploadsRoot';

// Configurar multer
const uploadsDir = path.join(resolveUploadsRoot(), 'users');

// Crear directorio si no existe
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueName = `${crypto.randomUUID()}_${Date.now()}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  },
});

const fileFilter = (
  req: Express.Request,
  file: Express.Multer.File,
  cb: multer.FileFilterCallback,
) => {
  // Solo permitir imágenes
  const allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Solo se permiten imágenes (JPEG, PNG, WebP)'));
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

export const uploadUserDocuments = upload.fields([
  { name: 'foto_perfil', maxCount: 1 },
  { name: 'cedula_foto', maxCount: 1 },
  { name: 'carta_ultimo_trabajo', maxCount: 1 },
]);

export class UploadsController {
  /**
   * POST /api/uploads/users
   * Subir documentos del usuario
   */
  static async uploadUserFiles(req: Request, res: Response) {
    try {
      const files = req.files as Express.Multer.File[] | undefined;
      if (!files) {
        return res.status(400).json({ error: 'No files uploaded' });
      }

      const response: Record<string, string> = {};

      // Procesar foto_perfil
      if (Array.isArray(files) && files.length > 0) {
        files.forEach((file) => {
          if (file.fieldname === 'foto_perfil') {
            response.fotoPerfilUrl = `/uploads/users/${file.filename}`;
          } else if (file.fieldname === 'cedula_foto') {
            response.cedulaFotoUrl = `/uploads/users/${file.filename}`;
          } else if (file.fieldname === 'carta_ultimo_trabajo') {
            response.cartaUltimoTrabajoUrl = `/uploads/users/${file.filename}`;
          }
        });
      }

      res.json({
        success: true,
        urls: response,
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: error.message,
      });
    }
  }

  /**
   * Middleware para manejar errores de multer
   */
  static handleUploadError(error: any, req: Request, res: Response) {
    if (error instanceof multer.MulterError) {
      if (error.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ error: 'Archivo muy grande (máx 5MB)' });
      } else if (error.code === 'LIMIT_FILE_COUNT') {
        return res.status(400).json({ error: 'Demasiados archivos' });
      }
    }
    res.status(400).json({ error: error.message });
  }
}
