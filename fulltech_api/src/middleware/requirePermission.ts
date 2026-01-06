import { Request, Response, NextFunction } from 'express';

import { hasPermission } from '../services/permissions';
import { getUserEffectivePermissions } from '../services/permissions';
import { prisma } from '../config/prisma';

export function requirePermission(code: string) {
  return async function (req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) {
        return res.status(401).json({ error: 'unauthorized' });
      }

      if (!req.permissions) {
        const u = await prisma.usuario.findUnique({
          where: { id: req.user.userId },
          select: { rol: true },
        });

        const permsSet = await getUserEffectivePermissions({
          empresaId: req.user.empresaId,
          userId: req.user.userId,
          legacyRole: u?.rol ?? req.user.role,
        });
        req.permissions = Array.from(permsSet);
      }

      const perms = new Set(req.permissions ?? []);
      if (hasPermission(perms, code)) return next();

      return res.status(403).json({
        error: 'forbidden',
        message: `Missing permission: ${code}`,
      });
    } catch (e) {
      next(e);
    }
  };
}
