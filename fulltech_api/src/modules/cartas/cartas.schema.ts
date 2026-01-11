import { z } from 'zod';

export const cartaTypeSchema = z.enum([
  'GARANTIA',
  'AGRADECIMIENTO',
  'SEGUIMIENTO',
  'COTIZACION_FORMAL',
  'DISCULPA_INCIDENCIA',
  'CONFIRMACION_SERVICIO',
]);

export const cartaIdParamsSchema = z.object({
  id: z.string().uuid(),
});

export const cartasListQuerySchema = z.object({
  presupuestoId: z.string().uuid().optional(),
  clienteId: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});

export const generateCartaSchema = z.object({
  // Must be sent by the client to group letters under a Presupuesto.
  presupuestoId: z.string().uuid(),

  // Attach quotation (cotización)
  attachQuotation: z.boolean().default(false),
  cotizacionId: z.string().uuid().optional().nullable(),

  // Customer info (required when no quotation is attached and not derivable)
  clienteId: z.string().uuid().optional().nullable(),
  customerName: z.string().max(200).optional().nullable(),
  customerPhone: z.string().max(50).optional().nullable(),

  letterType: cartaTypeSchema,
  subject: z.string().min(1).max(400),
  userInstructions: z.string().min(1).max(8000),
});

export const sendCartaWhatsappSchema = z.object({
  // Optional override; normally the carta stores customer_phone.
  toPhone: z.string().max(50).optional().nullable(),
});
