import jwt, { type SignOptions } from 'jsonwebtoken';
import { env } from '../config/env';

export type JwtPayload = {
  userId: string;
  empresaId: string;
  role:
    | 'admin'
    | 'administrador'
    | 'vendedor'
    | 'tecnico'
    | 'tecnico_fijo'
    | 'contratista'
    | 'asistente_administrativo';
  tokenVersion: number;
};

export function signToken(payload: JwtPayload): string {
  const options: SignOptions = {
    // `@types/jsonwebtoken` restringe `expiresIn` a formatos tipo `"7d"`.
    // Nuestra env es un string genérico, así que casteamos explícitamente.
    expiresIn: env.JWT_EXPIRES_IN as SignOptions['expiresIn'],
  };
  return jwt.sign(payload, env.JWT_SECRET, options);
}

export function verifyToken(token: string): JwtPayload {
  return jwt.verify(token, env.JWT_SECRET) as JwtPayload;
}
