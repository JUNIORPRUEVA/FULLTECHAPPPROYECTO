import path from 'path';
import { env } from '../config/env';

export function resolveUploadsRoot(): string {
  // Always resolve relative to process.cwd() to match Docker WORKDIR (/app)
  // and keep consistent with express static mount.
  return path.resolve(process.cwd(), env.UPLOADS_DIR || './uploads');
}
