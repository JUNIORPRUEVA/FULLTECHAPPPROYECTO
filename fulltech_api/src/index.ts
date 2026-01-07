import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import fs from 'fs';
import { spawn } from 'child_process';
import ffmpegPath from 'ffmpeg-static';

import { env } from './config/env';
import { httpLogger } from './middleware/logger';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { apiRouter } from './routes';
import { webhooksRouter } from './modules/webhooks/webhooks.routes';
import { runSqlMigrations } from './scripts/runSqlMigrations';
import { bootstrapAdmin } from './scripts/bootstrap_admin';

function truthy(value: string | undefined): boolean {
  return ['1', 'true', 'yes', 'on'].includes(String(value ?? '').trim().toLowerCase());
}

const app = express();

// Ensure uploads directories exist
const uploadsRoot = path.resolve(process.cwd(), env.UPLOADS_DIR || 'uploads');
fs.mkdirSync(path.join(uploadsRoot, 'products'), { recursive: true });
fs.mkdirSync(path.join(uploadsRoot, 'users'), { recursive: true });
fs.mkdirSync(path.join(uploadsRoot, 'company'), { recursive: true });
fs.mkdirSync(path.join(uploadsRoot, 'crm'), { recursive: true });
fs.mkdirSync(path.join(uploadsRoot, 'sales'), { recursive: true });
fs.mkdirSync(path.join(uploadsRoot, 'operations'), { recursive: true });

app.use(helmet());
app.use(
  cors({
    origin: env.CORS_ORIGIN,
    credentials: true,
  }),
);
app.use(express.json({ limit: '2mb' }));
app.use(httpLogger);

function tryTranscodeOggToMp3(inputAbs: string, outputAbs: string): Promise<boolean> {
  const ffmpeg = ffmpegPath;
  if (!ffmpeg) return Promise.resolve(false);

  return new Promise((resolve) => {
    const args = ['-y', '-i', inputAbs, '-vn', '-c:a', 'libmp3lame', '-q:a', '4', outputAbs];
    const proc = spawn(ffmpeg, args, { stdio: 'ignore', windowsHide: true });
    proc.on('error', () => resolve(false));
    proc.on('exit', (code) => resolve(code === 0 && fs.existsSync(outputAbs)));
  });
}

// On-demand transcode for WhatsApp PTTs stored as .ogg/.opus (Windows playback compatibility).
app.get('/uploads/crm/:ym/:file', (req, res, next) => {
  void (async () => {
    const file = String(req.params.file || '');
    if (!/\.(ogg|opus)$/i.test(file)) return next();

    const ym = String(req.params.ym || '');
    const abs = path.join(uploadsRoot, 'crm', ym, file);
    if (!fs.existsSync(abs)) return next();

    const mp3Abs = abs.replace(/\.(ogg|opus)$/i, '.mp3');
    if (!fs.existsSync(mp3Abs)) {
      await tryTranscodeOggToMp3(abs, mp3Abs);
    }

    if (fs.existsSync(mp3Abs)) {
      const rel = path.relative(uploadsRoot, mp3Abs).split(path.sep).join('/');
      res.redirect(302, `/uploads/${rel}`);
      return;
    }

    // If we couldn't transcode, fall through to serve the original file.
    next();
  })().catch(next);
});

// Public static files (e.g. product images)
app.use('/uploads', express.static(uploadsRoot));

// Public webhooks (Evolution)
app.use('/webhooks', webhooksRouter);

app.use('/api', apiRouter);

app.use(notFoundHandler);
app.use(errorHandler);

void (async () => {
  await runSqlMigrations();

  if (truthy(process.env.BOOTSTRAP_ADMIN)) {
    // eslint-disable-next-line no-console
    console.log('[BOOT] BOOTSTRAP_ADMIN enabled: ensuring admin user exists');
    await bootstrapAdmin();
  }

  app.listen(env.PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`FULLTECH API listening on http://localhost:${env.PORT}`);
    // eslint-disable-next-line no-console
    console.log(`[ENV] PUBLIC_BASE_URL=${env.PUBLIC_BASE_URL}`);
  });
})().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('[BOOT] Fatal error:', error);
  process.exit(1);
});
