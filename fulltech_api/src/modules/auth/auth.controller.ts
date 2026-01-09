import type { Request, Response } from 'express';
import { randomBytes, createHash } from 'crypto';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { comparePassword, hashPassword } from '../../services/password';
import { signToken } from '../../services/jwt';
import { loginSchema, refreshSchema, registerSchema } from './auth.schema';
import { env } from '../../config/env';

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value.trim());
}

function sha256Hex(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

async function issueRefreshToken(params: { userId: string }): Promise<string> {
  const raw = randomBytes(48).toString('base64url');
  const token_hash = sha256Hex(raw);

  // 30 days by default
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  await prisma.authRefreshToken.create({
    data: {
      user_id: params.userId,
      token_hash,
      expires_at: expiresAt,
    },
  });

  return raw;
}

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

  const refresh_token = await issueRefreshToken({ userId: user.id });
  res.status(201).json({ token, refresh_token, user });
}

export async function login(req: Request, res: Response) {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid login payload', parsed.error.flatten());
  }

  const { email, password } = parsed.data;
  const identifier = String(email ?? '').trim();

  const orWhere: any[] = [
    {
      email: {
        equals: identifier,
        mode: 'insensitive',
      },
    },
  ];

  // Optional: allow login by phone if user types it.
  if (identifier) {
    orWhere.push({ telefono: { equals: identifier } });
  }

  // Only attempt UUID match when it's actually a UUID.
  if (isUuid(identifier)) {
    orWhere.push({ id: identifier });
  }

  const user = await prisma.usuario.findFirst({
    where: {
      OR: orWhere,
    },
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

  const refresh_token = await issueRefreshToken({ userId: user.id });
  res.json({
    token,
    refresh_token,
    user: {
      id: user.id,
      empresa_id: user.empresa_id,
      email: user.email,
      name: user.nombre_completo,
      role: user.rol,
    },
  });
}

export async function refresh(req: Request, res: Response) {
  const parsed = refreshSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid refresh payload', parsed.error.flatten());
  }

  const raw = parsed.data.refresh_token;
  const token_hash = sha256Hex(raw);

  const existing = await prisma.authRefreshToken.findUnique({
    where: { token_hash },
  });
  if (!existing) throw new ApiError(401, 'Invalid refresh token');
  if (existing.revoked_at) throw new ApiError(401, 'Refresh token revoked');
  if (existing.expires_at.getTime() < Date.now()) throw new ApiError(401, 'Refresh token expired');

  const user = await prisma.usuario.findUnique({
    where: { id: existing.user_id },
  });
  if (!user) throw new ApiError(401, 'User not found');
  if (user.estado !== 'activo') throw new ApiError(403, 'User access revoked');

  // Rotate refresh token (revoke old, issue new).
  await prisma.authRefreshToken.update({
    where: { id: existing.id },
    data: { revoked_at: new Date() },
  });

  const refresh_token = await issueRefreshToken({ userId: user.id });

  const token = signToken({
    userId: user.id,
    empresaId: user.empresa_id,
    role: user.rol as any,
    tokenVersion: user.token_version,
  });

  res.json({
    token,
    refresh_token,
    user: {
      id: user.id,
      empresa_id: user.empresa_id,
      email: user.email,
      name: user.nombre_completo,
      role: user.rol,
    },
  });
}

export async function me(req: Request, res: Response) {
  // authMiddleware guarantees req.user exists and the token is valid.
  const userId = (req.user as any)?.userId as string | undefined;
  if (!userId) {
    throw new ApiError(401, 'Unauthorized');
  }

  const user = await prisma.usuario.findUnique({
    where: { id: userId },
    select: {
      id: true,
      empresa_id: true,
      email: true,
      nombre_completo: true,
      rol: true,
    },
  });

  if (!user) {
    throw new ApiError(401, 'User not found');
  }

  res.json({
    user: {
      id: user.id,
      empresa_id: user.empresa_id,
      email: user.email,
      name: user.nombre_completo,
      role: user.rol,
    },
  });
}
