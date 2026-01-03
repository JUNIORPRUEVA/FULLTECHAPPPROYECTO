import type { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { comparePassword, hashPassword } from '../../services/password';
import { signToken } from '../../services/jwt';
import { loginSchema, registerSchema } from './auth.schema';
import { env } from '../../config/env';

export async function register(req: Request, res: Response) {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid register payload', parsed.error.flatten());
  }

  const { email, password, name, empresaNombre, role } = parsed.data;

  const existing = await prisma.usuario.findUnique({ where: { email } });
  if (existing) {
    throw new ApiError(409, 'Email already registered');
  }

  // Single-tenant default: reuse an existing Empresa instead of creating a new one.
  // If DEFAULT_EMPRESA_ID is set, we attach all new users to that Empresa.
  // Otherwise we attach to the oldest Empresa in the DB; if none exists, create one.
  let empresa = env.DEFAULT_EMPRESA_ID
    ? await prisma.empresa.findUnique({ where: { id: env.DEFAULT_EMPRESA_ID } })
    : await prisma.empresa.findFirst({ orderBy: { created_at: 'asc' } });

  if (!empresa) {
    empresa = await prisma.empresa.create({
      data: {
        nombre: empresaNombre ?? 'FULLTECH',
      },
    });
  }

  const user = await prisma.usuario.create({
    data: {
      empresa_id: empresa.id,
      email,
      nombre_completo: name,
      password_hash: await hashPassword(password),
      rol: (role as any) ?? 'admin',
      posicion: (role as any) ?? 'admin',
    },
    select: {
      id: true,
      empresa_id: true,
      email: true,
      nombre_completo: true,
      rol: true,
      token_version: true,
      created_at: true,
      updated_at: true,
    },
  });

  const token = signToken({
    userId: user.id,
    empresaId: user.empresa_id,
    role: user.rol as any,
    tokenVersion: user.token_version,
  });

  res.status(201).json({ token, user });
}

export async function login(req: Request, res: Response) {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid login payload', parsed.error.flatten());
  }

  const { email, password } = parsed.data;

  const user = await prisma.usuario.findUnique({
    where: { email },
  });

  if (!user) {
    throw new ApiError(401, 'Invalid credentials');
  }

  const ok = await comparePassword(password, user.password_hash);
  if (!ok) {
    throw new ApiError(401, 'Invalid credentials');
  }

  // Check if user is active
  if (user.estado !== 'activo') {
    throw new ApiError(403, 'User access revoked');
  }

  const token = signToken({
    userId: user.id,
    empresaId: user.empresa_id,
    role: user.rol as any,
    tokenVersion: user.token_version,
  });

  res.json({
    token,
    user: {
      id: user.id,
      empresa_id: user.empresa_id,
      email: user.email,
      name: user.nombre_completo,
      role: user.rol,
    },
  });
}
