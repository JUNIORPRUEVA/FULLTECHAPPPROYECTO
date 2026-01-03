import path from 'path';
import crypto from 'crypto';
import fs from 'fs';
import multer from 'multer';
import { env } from '../../config/env';
import { ApiError } from '../../middleware/errorHandler';

function monthFolder(d: Date) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

export function crmUploadsRoot(): string {
  return path.resolve(process.cwd(), env.UPLOADS_DIR || 'uploads');
}

export function crmUploadsDir(): string {
  const dir = path.join(crmUploadsRoot(), 'crm', monthFolder(new Date()));
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function maxUploadBytes(): number {
  const mb = Number(env.MAX_UPLOAD_MB ?? 25);
  return Math.max(1, mb) * 1024 * 1024;
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    try {
      cb(null, crmUploadsDir());
    } catch (e) {
      cb(e as any, '');
    }
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const id = crypto.randomUUID();
    cb(null, `${id}${ext || ''}`);
  },
});

export const uploadCrmFile = multer({
  storage,
  limits: {
    fileSize: maxUploadBytes(),
  },
  fileFilter: (_req, file, cb) => {
    // Allow common WhatsApp media types.
    const allowedPrefixes = ['image/', 'video/', 'audio/'];
    const allowedExact = new Set([
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain',
    ]);

    const ok =
      allowedPrefixes.some((p) => file.mimetype.startsWith(p)) ||
      allowedExact.has(file.mimetype);

    if (!ok) {
      cb(new ApiError(400, 'Unsupported file type', { mimetype: file.mimetype }) as any, false);
      return;
    }

    cb(null, true);
  },
}).single('file');

export function toPublicUrlFromAbsoluteFile(absPath: string): string {
  const root = crmUploadsRoot();
  const rel = path.relative(root, absPath).split(path.sep).join('/');
  // Always return absolute URL to be fetchable by Evolution.
  return `${env.PUBLIC_BASE_URL.replace(/\/$/, '')}/uploads/${rel}`;
}

export function detectMediaType(mime: string): 'image' | 'video' | 'audio' | 'document' {
  if (mime.startsWith('image/')) return 'image';
  if (mime.startsWith('video/')) return 'video';
  if (mime.startsWith('audio/')) return 'audio';
  return 'document';
}
