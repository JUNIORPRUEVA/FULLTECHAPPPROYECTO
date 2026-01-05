import type { Request, Response } from 'express';
import path from 'path';
import crypto from 'crypto';
import multer from 'multer';
import { ApiError } from '../../middleware/errorHandler';

const uploadsRoot = path.resolve(process.cwd(), 'uploads');
const productsDir = path.join(uploadsRoot, 'products');
const usersDir = path.join(uploadsRoot, 'users');
const salesDir = path.join(uploadsRoot, 'sales');
const operationsDir = path.join(uploadsRoot, 'operations');

function ensureSafeImage(file: Express.Multer.File) {
  const allowed = new Set(['image/jpeg', 'image/png', 'image/webp']);
  if (!allowed.has(file.mimetype)) {
    throw new ApiError(400, 'Only image/jpeg, image/png, image/webp are allowed');
  }
}

function ensureSafeUserDoc(file: Express.Multer.File) {
  const allowed = new Set(['image/jpeg', 'image/png', 'image/webp', 'application/pdf']);
  if (!allowed.has(file.mimetype)) {
    throw new ApiError(400, 'Only images (jpg/png/webp) or PDF are allowed');
  }
}

function ensureSafeSalesEvidence(file: Express.Multer.File) {
  const allowed = new Set(['image/jpeg', 'image/png', 'image/webp', 'application/pdf']);
  if (!allowed.has(file.mimetype)) {
    throw new ApiError(400, 'Only images (jpg/png/webp) or PDF are allowed');
  }
}

function ensureSafeOperationsMedia(file: Express.Multer.File) {
  const allowed = new Set([
    'image/jpeg',
    'image/png',
    'image/webp',
    'video/mp4',
  ]);
  if (!allowed.has(file.mimetype)) {
    throw new ApiError(400, 'Only images (jpg/png/webp) or video/mp4 are allowed');
  }
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, productsDir);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const id = crypto.randomBytes(16).toString('hex');
    cb(null, `${id}${ext || ''}`);
  },
});

export const uploadProductImage = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (_req, file, cb) => {
    try {
      ensureSafeImage(file);
      cb(null, true);
    } catch (err) {
      cb(err as any, false);
    }
  },
}).single('file');

export async function postUploadProductImage(req: Request, res: Response) {
  // multer places the file in req.file
  const file = req.file;
  if (!file) {
    throw new ApiError(400, 'Missing file field "file"');
  }

  // Public URL served by express static (/uploads)
  const urlPath = `/uploads/products/${file.filename}`;

  res.status(201).json({ url: urlPath });
}

// --- Users docs upload ---

const usersStorage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, usersDir);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const id = crypto.randomBytes(16).toString('hex');
    cb(null, `${id}${ext || ''}`);
  },
});

export const uploadUserDocs = multer({
  storage: usersStorage,
  limits: {
    fileSize: 8 * 1024 * 1024, // 8MB
  },
  fileFilter: (_req, file, cb) => {
    try {
      ensureSafeUserDoc(file);
      cb(null, true);
    } catch (err) {
      cb(err as any, false);
    }
  },
}).fields([
  { name: 'foto_perfil', maxCount: 1 },
  { name: 'cedula_frontal', maxCount: 1 },
  { name: 'cedula_posterior', maxCount: 1 },
  { name: 'licencia_conducir', maxCount: 1 },
  { name: 'carta_trabajo', maxCount: 1 },
  { name: 'otros_documentos', maxCount: 10 },
]);

export async function postUploadUserDocs(req: Request, res: Response) {
  const files = req.files as
    | {
        [fieldname: string]: Express.Multer.File[];
      }
    | undefined;

  const foto = files?.foto_perfil?.[0];
  const cedulaFrontal = files?.cedula_frontal?.[0];
  const cedulaPosterior = files?.cedula_posterior?.[0];
  const licencia = files?.licencia_conducir?.[0];
  const carta = files?.carta_trabajo?.[0];
  const otros = files?.otros_documentos ?? [];

  if (!foto && !cedulaFrontal && !cedulaPosterior && !licencia && !carta && otros.length === 0) {
    throw new ApiError(400, 'No files provided');
  }

  res.status(201).json({
    fotoPerfilUrl: foto ? `/uploads/users/${foto.filename}` : null,
    cedulaFrontalUrl: cedulaFrontal ? `/uploads/users/${cedulaFrontal.filename}` : null,
    cedulaPosteriorUrl: cedulaPosterior ? `/uploads/users/${cedulaPosterior.filename}` : null,
    licenciaConducirUrl: licencia ? `/uploads/users/${licencia.filename}` : null,
    cartaTrabajoUrl: carta ? `/uploads/users/${carta.filename}` : null,
    // Backward compat
    cartaUltimoTrabajoUrl: carta ? `/uploads/users/${carta.filename}` : null,
    otrosDocumentos: otros.map((f) => `/uploads/users/${f.filename}`),
  });
}

// --- Sales evidence upload ---

const salesStorage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, salesDir);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const id = crypto.randomBytes(16).toString('hex');
    cb(null, `${id}${ext || ''}`);
  },
});

export const uploadSalesEvidence = multer({
  storage: salesStorage,
  limits: {
    fileSize: 8 * 1024 * 1024, // 8MB
  },
  fileFilter: (_req, file, cb) => {
    try {
      ensureSafeSalesEvidence(file);
      cb(null, true);
    } catch (err) {
      cb(err as any, false);
    }
  },
}).single('file');

export async function postUploadSalesEvidence(req: Request, res: Response) {
  const file = req.file;
  if (!file) {
    throw new ApiError(400, 'Missing file field "file"');
  }

  const urlPath = `/uploads/sales/${file.filename}`;
  res.status(201).json({ url: urlPath, mimeType: file.mimetype });
}

// --- Operations media upload ---

const operationsStorage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, operationsDir);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const id = crypto.randomBytes(16).toString('hex');
    cb(null, `${id}${ext || ''}`);
  },
});

export const uploadOperationsMedia = multer({
  storage: operationsStorage,
  limits: {
    fileSize: 25 * 1024 * 1024, // 25MB
  },
  fileFilter: (_req, file, cb) => {
    try {
      ensureSafeOperationsMedia(file);
      cb(null, true);
    } catch (err) {
      cb(err as any, false);
    }
  },
}).single('file');

export async function postUploadOperationsMedia(req: Request, res: Response) {
  const file = req.file;
  if (!file) {
    throw new ApiError(400, 'Missing file field "file"');
  }

  const urlPath = `/uploads/operations/${file.filename}`;
  res.status(201).json({ url: urlPath, mimeType: file.mimetype });
}
