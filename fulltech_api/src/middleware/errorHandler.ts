import type { NextFunction, Request, Response } from 'express';

export class ApiError extends Error {
  public statusCode: number;
  public details?: unknown;
  public code?: string;

  constructor(statusCode: number, message: string, details?: unknown, code?: string) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
    this.code = code;
  }
}

export function notFoundHandler(req: Request, _res: Response, next: NextFunction) {
  next(new ApiError(404, `Not Found: ${req.method} ${req.path}`));
}

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({
      // Backward compatible key
      error: err.message,
      // Preferred keys
      message: err.message,
      code: err.code ?? 'API_ERROR',
      details: err.details ?? null,
    });
  }

  // Prisma errors and others can be refined later
  const message = err instanceof Error ? err.message : 'Unexpected error';

  // Do not leak internal details in production.
  const safeMessage = process.env.NODE_ENV === 'production' ? 'Unexpected error' : message;

  return res.status(500).json({
    error: safeMessage,
    message: safeMessage,
    code: 'INTERNAL_ERROR',
    details: null,
  });
}
