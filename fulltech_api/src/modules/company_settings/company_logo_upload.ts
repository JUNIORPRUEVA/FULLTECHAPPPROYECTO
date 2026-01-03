import path from 'path';
import crypto from 'crypto';
import multer from 'multer';
import { ApiError } from '../../middleware/errorHandler';

const uploadsRoot = path.resolve(process.cwd(), 'uploads');
const companyDir = path.join(uploadsRoot, 'company');

function ensureSafeImage(file: Express.Multer.File) {
  const allowed = new Set(['image/jpeg', 'image/png', 'image/webp']);
  if (!allowed.has(file.mimetype)) {
    throw new ApiError(400, 'Only image/jpeg, image/png, image/webp are allowed');
  }
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, companyDir);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const id = crypto.randomBytes(16).toString('hex');
    cb(null, `${id}${ext || ''}`);
  },
});

export const uploadCompanyLogo = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    try {
      ensureSafeImage(file);
      cb(null, true);
    } catch (err) {
      cb(err as any, false);
    }
  },
}).single('file');
