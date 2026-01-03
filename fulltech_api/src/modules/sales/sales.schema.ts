import { z } from 'zod';

export const createSaleSchema = z.object({
  thread_id: z.string().uuid().optional().nullable(),
  customer_id: z.string().uuid().optional().nullable(),
  total: z.number().nonnegative(),
  detalles: z.any().optional().nullable(),
});
