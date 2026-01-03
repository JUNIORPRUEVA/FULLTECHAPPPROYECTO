import { z } from 'zod';

export const userRoleSchema = z.enum([
  'vendedor',
  'tecnico_fijo',
  'contratista',
  'administrador',
  'asistente_administrativo',
]);

// Backward compatible roles that may exist in older DB/JWT.
export const userRoleCompatSchema = z.enum([
  'admin',
  'tecnico',
  'vendedor',
  'tecnico_fijo',
  'contratista',
  'administrador',
  'asistente_administrativo',
]);

export const userEstadoSchema = z.enum(['activo', 'bloqueado', 'eliminado']);

const uuidSchema = z.string().uuid();

function parseDateOnlyOptional(value: unknown): Date | undefined {
  if (value === undefined || value === null) return undefined;
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? undefined : value;
  }
  if (typeof value === 'string') {
    // Expect ISO date like 2026-01-01
    const trimmed = value.trim();
    if (!trimmed) return undefined;
    const d = new Date(trimmed);
    return Number.isNaN(d.getTime()) ? undefined : d;
  }
  return undefined;
}

function requireIf(condition: boolean, ctx: z.RefinementCtx, message: string, path: (string | number)[]) {
  if (!condition) return;
  ctx.addIssue({ code: z.ZodIssueCode.custom, message, path });
}

export const createUserSchema = z
  .object({
    nombre_completo: z.string().min(2).max(180),
    email: z.string().email().max(180).optional(),
    password: z.string().min(6).max(200).optional(),
    rol: userRoleSchema,
    posicion: z.string().min(2).max(120).optional(),

    telefono: z.string().min(5).max(50),
    direccion: z.string().min(3).max(300),
    ubicacion_mapa: z.string().max(500).optional(),

    fecha_nacimiento: z.preprocess((v) => parseDateOnlyOptional(v), z.date().optional()),
    lugar_nacimiento: z.string().max(180).optional(),
    cedula_numero: z.string().min(5).max(50),

    tiene_casa_propia: z.boolean().optional(),
    // Alias per spec (tiene_casa)
    tiene_casa: z.boolean().optional(),
    tiene_vehiculo: z.boolean().optional(),
    tipo_vehiculo: z.string().max(80).optional(),
    placa_vehiculo: z.string().max(40).optional(),
    // Alias per spec (placa)
    placa: z.string().max(40).optional(),
    es_casado: z.boolean().optional(),
    cantidad_hijos: z.number().int().min(0).max(50).optional(),

    ultimo_trabajo: z.string().max(400).optional(),
    motivo_salida_ultimo_trabajo: z.string().max(400).optional(),

    fecha_ingreso_empresa: z.preprocess((v) => parseDateOnlyOptional(v), z.date().optional()),
    salario_mensual: z.number().positive().optional(),
    beneficios: z.any().optional(),
    meta_ventas: z.number().positive().optional(),

    // Contratista-specific
    areas_trabajo: z.array(z.string().min(1).max(120)).optional(),
    horario_disponible: z.string().max(300).optional(),

    // Tecnico fijo-specific
    area_maneja: z.string().max(300).optional(),
    especialidades: z.array(z.string().min(1).max(120)).optional(),

    es_tecnico_con_licencia: z.boolean().optional(),
    numero_licencia_tecnica: z.string().max(80).optional(),
    licencia_conducir_numero: z.string().max(80).optional(),
    licencia_conducir_fecha_vencimiento: z.preprocess((v) => parseDateOnlyOptional(v), z.date().optional()),

    foto_perfil_url: z.string().max(500).optional(),
    // DB legacy names
    cedula_foto_frontal_url: z.string().max(500).optional(),
    cedula_foto_posterior_url: z.string().max(500).optional(),
    licencia_conducir_foto_url: z.string().max(500).optional(),
    carta_ultimo_trabajo_url: z.string().max(500).optional(),
    otros_documentos_url: z.array(z.string().max(500)).optional(),
    // Spec names
    cedula_frontal_url: z.string().max(500).optional(),
    cedula_posterior_url: z.string().max(500).optional(),
    licencia_conducir_url: z.string().max(500).optional(),
    carta_trabajo_url: z.string().max(500).optional(),
    otros_documentos: z.array(z.string().max(500)).optional(),

    metadata: z.record(z.any()).optional(),
  })
  .superRefine((v, ctx) => {
    const isContratista = v.rol === 'contratista';

    // Required fields for non-contratista (login + HR)
    requireIf(!isContratista && !v.email, ctx, 'email requerido', ['email']);
    requireIf(!isContratista && !v.password, ctx, 'password requerido', ['password']);
    requireIf(!isContratista && !v.fecha_nacimiento, ctx, 'fecha_nacimiento requerido', ['fecha_nacimiento']);
    requireIf(!isContratista && !v.fecha_ingreso_empresa, ctx, 'fecha_ingreso_empresa requerido', ['fecha_ingreso_empresa']);
    requireIf(!isContratista && v.salario_mensual === undefined, ctx, 'salario_mensual requerido', ['salario_mensual']);

    // Contratista requirements
    if (isContratista) {
      if (!v.areas_trabajo || v.areas_trabajo.length === 0) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'areas_trabajo requerido', path: ['areas_trabajo'] });
      }
      if (!v.horario_disponible || v.horario_disponible.trim().length === 0) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'horario_disponible requerido', path: ['horario_disponible'] });
      }
    }

    if (v.salario_mensual !== undefined && v.salario_mensual <= 0) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'salario_mensual must be > 0', path: ['salario_mensual'] });
    }

    // Basic age sanity check (>16) when fecha_nacimiento exists
    if (v.fecha_nacimiento) {
      const age = computeAgeFromBirthDate(v.fecha_nacimiento);
      if (age < 16) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'Edad mínima es 16', path: ['fecha_nacimiento'] });
      }
    }

    if (v.tiene_vehiculo === true && (!v.tipo_vehiculo || v.tipo_vehiculo.trim().length === 0)) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'tipo_vehiculo requerido si tiene_vehiculo=true', path: ['tipo_vehiculo'] });
    }

    if (v.es_tecnico_con_licencia === true && (!v.numero_licencia_tecnica || v.numero_licencia_tecnica.trim().length === 0)) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'numero_licencia_tecnica requerido', path: ['numero_licencia_tecnica'] });
    }
  });

export const updateUserSchema = z
  .object({
    nombre_completo: z.string().min(2).max(180).optional(),
    email: z.string().email().max(180).optional(),
    password: z.string().min(6).max(200).optional(),
    rol: userRoleCompatSchema.optional(),
    posicion: z.string().min(2).max(120).optional(),

    telefono: z.string().min(5).max(50).optional(),
    direccion: z.string().min(3).max(300).optional(),
    ubicacion_mapa: z.string().max(500).optional(),

    fecha_nacimiento: z.preprocess((v) => parseDateOnlyOptional(v), z.date().optional()),
    lugar_nacimiento: z.string().max(180).optional(),
    cedula_numero: z.string().min(5).max(50).optional(),

    tiene_casa_propia: z.boolean().optional(),
    // Alias per spec (tiene_casa)
    tiene_casa: z.boolean().optional(),
    tiene_vehiculo: z.boolean().optional(),
    tipo_vehiculo: z.string().max(80).optional(),
    placa_vehiculo: z.string().max(40).optional(),
    // Alias per spec (placa)
    placa: z.string().max(40).optional(),
    es_casado: z.boolean().optional(),
    cantidad_hijos: z.number().int().min(0).max(50).optional(),

    ultimo_trabajo: z.string().max(400).optional(),
    motivo_salida_ultimo_trabajo: z.string().max(400).optional(),

    fecha_ingreso_empresa: z.preprocess((v) => parseDateOnlyOptional(v), z.date().optional()),
    salario_mensual: z.number().positive().optional(),
    beneficios: z.string().max(800).optional(),

    es_tecnico_con_licencia: z.boolean().optional(),
    numero_licencia_tecnica: z.string().max(80).optional(),
    licencia_conducir_numero: z.string().max(80).optional(),
    licencia_conducir_fecha_vencimiento: z.preprocess((v) => parseDateOnlyOptional(v), z.date().optional()),

    foto_perfil_url: z.string().max(500).optional(),
    // DB legacy names
    cedula_foto_frontal_url: z.string().max(500).optional(),
    cedula_foto_posterior_url: z.string().max(500).optional(),
    licencia_conducir_foto_url: z.string().max(500).optional(),
    carta_ultimo_trabajo_url: z.string().max(500).optional(),
    otros_documentos_url: z.array(z.string().max(500)).optional(),
    // Spec names
    cedula_frontal_url: z.string().max(500).optional(),
    cedula_posterior_url: z.string().max(500).optional(),
    licencia_conducir_url: z.string().max(500).optional(),
    carta_trabajo_url: z.string().max(500).optional(),
    otros_documentos: z.array(z.string().max(500)).optional(),

    estado: userEstadoSchema.optional(),
    metadata: z.record(z.any()).optional(),
  })
  .superRefine((v, ctx) => {
    if (v.salario_mensual !== undefined && v.salario_mensual <= 0) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'salario_mensual must be > 0', path: ['salario_mensual'] });
    }
    if (v.tiene_vehiculo === true && v.tipo_vehiculo !== undefined && v.tipo_vehiculo.trim().length === 0) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'tipo_vehiculo inválido', path: ['tipo_vehiculo'] });
    }
    if (
      v.es_tecnico_con_licencia === true &&
      v.numero_licencia_tecnica !== undefined &&
      v.numero_licencia_tecnica.trim().length === 0
    ) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'numero_licencia_tecnica inválido', path: ['numero_licencia_tecnica'] });
    }
  });

export const listUsersQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  page_size: z.coerce.number().int().min(1).max(100).default(20),
  q: z.string().optional(),
  rol: userRoleCompatSchema.optional(),
  estado: userEstadoSchema.optional(),
});

export const userIdParamSchema = z.object({
  id: uuidSchema,
});

export const iaExtractSchema = z.object({
  fecha_nacimiento: z.string().optional(),
  lugar_nacimiento: z.string().optional(),
  cedula_numero: z.string().optional(),
  otros: z.record(z.any()).optional(),
});

export function computeAgeFromBirthDate(date: Date, now = new Date()): number {
  let age = now.getFullYear() - date.getFullYear();
  const m = now.getMonth() - date.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < date.getDate())) {
    age--;
  }
  return age;
}
