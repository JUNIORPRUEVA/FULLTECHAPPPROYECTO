import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  name: z.string().min(2),
  empresaNombre: z.string().min(2).optional(),
  role: z
    .enum([
      'admin',
      'administrador',
      'vendedor',
      'tecnico',
      'tecnico_fijo',
      'contratista',
      'asistente_administrativo',
    ])
    .optional(),
});

export const loginSchema = z.object({
  // UI supports "Email o usuario". Keep key name for backward compatibility.
  email: z.string().min(1),
  password: z.string().min(1),
});

export const refreshSchema = z.object({
  refresh_token: z.string().min(20).max(1000),
});
