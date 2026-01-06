import { Request, Response, NextFunction } from 'express';

import { prisma } from '../config/prisma';
import { getUserEffectivePermissions } from '../services/permissions';

export async function attachPermissions(
  req: Request,
  _res: Response,
  next: NextFunction,
) {
  try {
    if (!req.user) {
      req.permissions = [];
      return next();
    }

    const u = await prisma.usuario.findUnique({
      where: { id: req.user.userId },
      select: { rol: true },
    });

    const perms = await getUserEffectivePermissions({
      empresaId: req.user.empresaId,
      userId: req.user.userId,
      legacyRole: u?.rol ?? req.user.role,
    });

    req.permissions = Array.from(perms);
    next();
  } catch (e) {
    next(e);
  }
}
