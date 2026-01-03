import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import fs from 'fs';

import { env } from './config/env';
import { httpLogger } from './middleware/logger';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { apiRouter } from './routes';
import { webhooksRouter } from './modules/webhooks/webhooks.routes';

const app = express();

// Ensure uploads directories exist
const uploadsRoot = path.resolve(process.cwd(), env.UPLOADS_DIR || 'uploads');
fs.mkdirSync(path.join(uploadsRoot, 'products'), { recursive: true });
fs.mkdirSync(path.join(uploadsRoot, 'users'), { recursive: true });
fs.mkdirSync(path.join(uploadsRoot, 'company'), { recursive: true });
fs.mkdirSync(path.join(uploadsRoot, 'crm'), { recursive: true });

app.use(helmet());
app.use(
  cors({
    origin: env.CORS_ORIGIN,
    credentials: true,
  }),
);
app.use(express.json({ limit: '2mb' }));
app.use(httpLogger);

// Public static files (e.g. product images)
app.use('/uploads', express.static(uploadsRoot));

// Public webhooks (Evolution)
app.use('/webhooks', webhooksRouter);

app.use('/api', apiRouter);

app.use(notFoundHandler);
app.use(errorHandler);

app.listen(env.PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`FULLTECH API listening on http://localhost:${env.PORT}`);
});
