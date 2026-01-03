import { z } from 'zod';

export const createClienteSchema = z.object({
  nombre: z.string().min(2),
  telefono: z.string().min(7),
  email: z.string().email().optional(),
  estado: z.enum(['pendiente', 'interesado', 'compro']).optional(),
  ultimo_mensaje: z.string().optional(),
  ultima_interaccion: z.string().datetime().optional(),
});

export const updateClienteSchema = createClienteSchema.partial();
