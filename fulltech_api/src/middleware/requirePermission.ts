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

      // SUPERUSER BYPASS: admin always allowed.
      // This must never depend on DB permission rows.
      if (req.user.role === 'admin' || (req.user as any).isSuperAdmin === true) {
        if (process.env.NODE_ENV === 'development') {
          // eslint-disable-next-line no-console
          console.log(
            `[RBAC] allow(superuser) role=${req.user.role} perm=${code} ${req.method} ${req.originalUrl}`,
          );
        }
        return next();
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
      if (hasPermission(perms, code)) {
        if (process.env.NODE_ENV === 'development') {
          // eslint-disable-next-line no-console
          console.log(
            `[RBAC] allow role=${req.user.role} perm=${code} ${req.method} ${req.originalUrl}`,
          );
        }
        return next();
      }

      if (process.env.NODE_ENV === 'development') {
        // eslint-disable-next-line no-console
        console.log(
          `[RBAC] deny role=${req.user.role} perm=${code} ${req.method} ${req.originalUrl}`,
        );
      }

      return res.status(403).json({
        error: 'forbidden',
        message: `Missing permission: ${code}`,
      });
    } catch (e) {
      next(e);
    }
  };
}
