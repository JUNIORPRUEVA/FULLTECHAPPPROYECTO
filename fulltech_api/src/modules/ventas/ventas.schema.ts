import { z } from 'zod';

export const createVentaSchema = z.object({
  cliente_id: z.string().uuid(),
  numero: z.string().min(1),
  monto: z.number().positive(),
  estado: z.enum(['pendiente', 'en_proceso', 'finalizada']).optional(),
});

export const updateVentaSchema = createVentaSchema.partial();
