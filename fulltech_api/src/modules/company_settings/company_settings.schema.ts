import { z } from 'zod';

export const companySettingsSchema = z.object({
  nombre_empresa: z.string().min(2).max(200),
  nombre_comercial: z.string().max(200).optional().nullable(),
  rnc: z.string().min(2).max(50),
  telefono: z.string().min(5).max(50),
  direccion: z.string().min(3).max(300),
  ciudad: z.string().max(120).optional().nullable(),
  provincia: z.string().max(120).optional().nullable(),
  pais: z.string().max(120).optional().nullable(),
  email: z.string().email().max(180).optional().nullable(),
  sitio_web: z.string().max(200).url().optional().nullable(),
  nombre_representante: z.string().max(180).optional().nullable(),
  cargo_representante: z.string().max(180).optional().nullable(),
  otros_detalles: z.string().max(2000).optional().nullable(),
  logo_url: z
    .string()
    .max(500)
    .refine(
      (v) => {
        try {
          // Accept absolute URLs.
          // eslint-disable-next-line no-new
          new URL(v);
          return true;
        } catch {
          // Accept local static paths served by this API.
          return v.startsWith('/uploads/');
        }
      },
      { message: 'Invalid logo_url' },
    )
    .optional()
    .nullable(),
});
