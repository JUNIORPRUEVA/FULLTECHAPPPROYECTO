import { z } from 'zod';

export const userRoleEnum = z.enum([
  'vendedor',
  'tecnico_fijo',
  'contratista',
  'administrador',
  'asistente_administrativo',
]);

export type UserRole = z.infer<typeof userRoleEnum>;

// Esquema para crear un nuevo usuario
export const createUserSchema = z.object({
  email: z.string().email('Email inválido').optional(),
  nombre_completo: z.string().min(3, 'Nombre debe tener al menos 3 caracteres'),
  password: z.string().min(6, 'Contraseña debe tener al menos 6 caracteres').optional(),
  rol: userRoleEnum,

  // Datos personales (opcionales para contratista)
  fecha_nacimiento: z.string().refine(
    (date) => !isNaN(Date.parse(date)),
    'Fecha de nacimiento inválida',
  ).optional(),
  lugar_nacimiento: z.string().optional(),
  cedula_numero: z.string().min(11, 'Cédula inválida'),
  telefono: z.string().min(10, 'Teléfono inválido'),
  direccion: z.string().min(5, 'Dirección muy corta'),
  ubicacion_mapa: z.string().optional(),

  // Familiar/Patrimonial
  tiene_casa_propia: z.boolean().optional().default(false),
  tiene_vehiculo: z.boolean().optional().default(false),
  tipo_vehiculo: z.string().optional(),
  placa: z.string().optional(),
  es_casado: z.boolean().optional().default(false),
  cantidad_hijos: z.number().int().min(0).optional().default(0),

  // Laboral (opcionales para contratista)
  ultimo_trabajo: z.string().optional(),
  motivo_salida_ultimo_trabajo: z.string().optional(),
  fecha_ingreso_empresa: z.string().refine(
    (date) => !isNaN(Date.parse(date)),
    'Fecha de ingreso inválida',
  ).optional(),
  salario_mensual: z.string().transform((val) => parseFloat(val)).optional(),
  beneficios: z.any().optional(),
  es_tecnico_con_licencia: z.boolean().optional().default(false),
  numero_licencia: z.string().optional(),
  area_maneja: z.string().optional(),
  especialidades: z.array(z.string()).optional(),

  // Campos específicos para contratista
  areas_trabajo: z.array(z.string()).optional(),
  horario_disponible: z.string().optional(),

  // Documentos (URLs)
  foto_perfil_url: z.string().url().optional(),
  cedula_foto_url: z.string().url().optional(),
  cedula_frontal_url: z.string().url().optional(),
  cedula_posterior_url: z.string().url().optional(),
  licencia_conducir_url: z.string().url().optional(),
  carta_trabajo_url: z.string().url().optional(),
  curriculum_vitae_url: z.string().url().optional(),
  carta_ultimo_trabajo_url: z.string().url().optional(),
});

export type CreateUserInput = z.infer<typeof createUserSchema>;

// Esquema para actualizar usuario
export const updateUserSchema = createUserSchema.omit({ password: true }).partial();

export type UpdateUserInput = z.infer<typeof updateUserSchema>;

// Esquema para listar usuarios (filtros)
export const listUsersQuerySchema = z.object({
  page: z.string().transform(Number).optional().default('1'),
  limit: z.string().transform(Number).optional().default('20'),
  rol: userRoleEnum.optional(),
  estado: z.enum(['activo', 'bloqueado', 'eliminado']).optional(),
  search: z.string().optional(), // Busca en nombre, email, teléfono, cédula
});

export type ListUsersQuery = z.infer<typeof listUsersQuerySchema>;

// Esquema para datos de cédula extraídos por IA
export const extractCedulaResponseSchema = z.object({
  fecha_nacimiento: z.string().optional(),
  lugar_nacimiento: z.string().optional(),
  cedula_numero: z.string().optional(),
  nombre_completo: z.string().optional(),
  error: z.string().optional(),
});

export type ExtractCedulaResponse = z.infer<typeof extractCedulaResponseSchema>;
