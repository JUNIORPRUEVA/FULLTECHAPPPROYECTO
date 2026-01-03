import type { NextFunction, Request, Response } from 'express';
import { ApiError } from './errorHandler';
import { verifyToken } from '../services/jwt';
import { prisma } from '../config/prisma';

export async function authMiddleware(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return next(new ApiError(401, 'Missing Authorization Bearer token'));
  }

  const token = header.slice('Bearer '.length).trim();
  try {
    const payload = verifyToken(token) as any;

    // Backward compatibility: older tokens may not include tokenVersion.
    const tokenVersion = typeof payload.tokenVersion === 'number' ? payload.tokenVersion : 0;
    
    // Validate token_version against database
    const user = await prisma.usuario.findUnique({
      where: { id: payload.userId },
      select: { id: true, estado: true, token_version: true }
    });
    
    if (!user) {
      return next(new ApiError(401, 'User not found'));
    }
    
    // Check if user is active
    if (user.estado !== 'activo') {
      return next(new ApiError(403, 'User access revoked'));
    }
    
    // Check if token_version matches (invalidate token if it doesn't)
    if (user.token_version !== tokenVersion) {
      return next(new ApiError(401, 'Token invalidated'));
    }
    
    req.user = { ...payload, tokenVersion };
    return next();
  } catch {
    return next(new ApiError(401, 'Invalid or expired token'));
  }
}
