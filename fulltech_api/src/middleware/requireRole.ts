import type { NextFunction, Request, Response } from 'express';
import { ApiError } from './errorHandler';

export type AppRole =
  | 'admin'
  | 'administrador'
  | 'vendedor'
  | 'tecnico'
  | 'tecnico_fijo'
  | 'contratista'
  | 'asistente_administrativo';

export function requireRole(roles: AppRole[]) {
  return function (req: Request, _res: Response, next: NextFunction) {
    const role = req.user?.role;
    if (!role) {
      return next(new ApiError(401, 'Not authenticated'));
    }
    const normalized: AppRole = role === 'administrador' ? 'administrador' : (role as AppRole);
    const effectiveRoles = roles.flatMap((r) => (r === 'admin' || r === 'administrador' ? ['admin', 'administrador'] : [r]));
    if (!effectiveRoles.includes(normalized)) {
      return next(new ApiError(403, 'Forbidden: insufficient role'));
    }
    return next();
  };
}
