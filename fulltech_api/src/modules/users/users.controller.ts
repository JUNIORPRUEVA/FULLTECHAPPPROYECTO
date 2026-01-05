import type { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { hashPassword } from '../../services/password';
import {
  computeAgeFromBirthDate,
  createUserSchema,
  listUsersQuerySchema,
  updateUserSchema,
} from './users.schema';
import { buildUserContractPdf, buildUserProfilePdf } from './users.pdf';
import { aiIdentityService } from '../../services/aiIdentityService';

function isAdminRole(role: string | undefined): boolean {
  // Maintain backward compatibility with legacy 'admin'
  return role === 'admin' || role === 'administrador';
}

function sanitizeUser(u: any) {
  // Never return password hash.
  // Keep payload shape stable for frontend.
  const { password_hash: _ph, ...rest } = u;
  const meta = (rest.metadata ?? {}) as any;
  // Add spec-friendly aliases (keep legacy DB field names too).
  return {
    ...rest,
    cedula_frontal_url: rest.cedula_foto_frontal_url ?? null,
    cedula_posterior_url: rest.cedula_foto_posterior_url ?? null,
    licencia_conducir_url: rest.licencia_conducir_foto_url ?? null,
    carta_trabajo_url: rest.carta_ultimo_trabajo_url ?? null,
    otros_documentos: rest.otros_documentos_url ?? [],
    tiene_casa: rest.tiene_casa_propia ?? false,
    placa: rest.placa_vehiculo ?? null,

    // Contratista fields may be stored in metadata (DB may not have columns)
    areas_trabajo: meta.areas_trabajo ?? [],
    horario_disponible: meta.horario_disponible ?? null,
  };
}

function normalizeUserDocsPayload(payload: any) {
  return {
    foto_perfil_url: payload.foto_perfil_url,
    cedula_foto_frontal_url: payload.cedula_frontal_url ?? payload.cedula_foto_frontal_url,
    cedula_foto_posterior_url: payload.cedula_posterior_url ?? payload.cedula_foto_posterior_url,
    licencia_conducir_foto_url: payload.licencia_conducir_url ?? payload.licencia_conducir_foto_url,
    carta_ultimo_trabajo_url: payload.carta_trabajo_url ?? payload.carta_ultimo_trabajo_url,
    otros_documentos_url: payload.otros_documentos ?? payload.otros_documentos_url,
  };
}

async function assertCanViewUser(req: Request, targetUserId: string) {
  const actor = req.user!;
  if (isAdminRole(actor.role)) return;
  if (actor.userId !== targetUserId) {
    throw new ApiError(403, 'Forbidden');
  }
}

async function assertCanEditUser(req: Request, targetUserId: string) {
  const actor = req.user!;
  if (isAdminRole(actor.role)) return;
  if (actor.userId !== targetUserId) {
    throw new ApiError(403, 'Forbidden');
  }
}

export async function listUsers(req: Request, res: Response) {
  const actor = req.user!;
  if (!isAdminRole(actor.role)) {
    throw new ApiError(403, 'Only administrador can list users');
  }

  const parsed = listUsersQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid query', parsed.error.flatten());
  }

  const { page, page_size, q, rol, estado } = parsed.data;

  const where: any = {
    empresa_id: actor.empresaId,
    ...(rol ? { rol: rol as any } : {}),
    ...(estado ? { estado } : {}),
    ...(q && q.trim().length > 0
      ? {
          OR: [
            { nombre_completo: { contains: q.trim(), mode: 'insensitive' } },
            { email: { contains: q.trim(), mode: 'insensitive' } },
            { telefono: { contains: q.trim(), mode: 'insensitive' } },
            { cedula_numero: { contains: q.trim(), mode: 'insensitive' } },
          ],
        }
      : {}),
  };

  const [total, items] = await Promise.all([
    prisma.usuario.count({ where }),
    prisma.usuario.findMany({
      where,
      orderBy: [{ updated_at: 'desc' }],
      skip: (page - 1) * page_size,
      take: page_size,
      select: {
        id: true,
        empresa_id: true,
        nombre_completo: true,
        email: true,
        rol: true,
        posicion: true,
        telefono: true,
        estado: true,
        foto_perfil_url: true,
        created_at: true,
        updated_at: true,
      },
    }),
  ]);

  res.json({
    page,
    page_size,
    total,
    items,
  });
}

export async function getUser(req: Request, res: Response) {
  const { id } = req.params;
  await assertCanViewUser(req, id);

  const actor = req.user!;
  const user = await prisma.usuario.findFirst({
    where: { id, empresa_id: actor.empresaId },
  });
  if (!user) throw new ApiError(404, 'User not found');

  res.json({ item: sanitizeUser(user) });
}

export async function createUser(req: Request, res: Response) {
  const actor = req.user!;
  if (!isAdminRole(actor.role)) {
    throw new ApiError(403, 'Only administrador can create users');
  }

  const parsed = createUserSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid user payload', parsed.error.flatten());
  }

  const payload = parsed.data;

  const isContratista = payload.rol === 'contratista';

  // Ensure DB-required credentials even if contractor doesn't login.
  const email = payload.email ?? (isContratista ? `contratista+${crypto.randomUUID()}@fulltech.local` : undefined);
  if (!email) {
    throw new ApiError(400, 'email requerido');
  }

  const existing = await prisma.usuario.findUnique({ where: { email } });
  if (existing) {
    throw new ApiError(409, 'Email already registered');
  }

  const rawPassword = payload.password ?? (isContratista ? crypto.randomUUID() : undefined);
  if (!rawPassword) {
    throw new ApiError(400, 'password requerido');
  }

  const edad = payload.fecha_nacimiento ? computeAgeFromBirthDate(payload.fecha_nacimiento) : null;

  const docs = normalizeUserDocsPayload(payload);

  const tieneCasa = payload.tiene_casa ?? payload.tiene_casa_propia;
  const placa = payload.placa ?? payload.placa_vehiculo;

  const beneficiosString =
    payload.beneficios === undefined || payload.beneficios === null
      ? undefined
      : typeof payload.beneficios === 'string'
        ? payload.beneficios
        : JSON.stringify(payload.beneficios);

  const mergedMetadata: any = {
    ...(payload.metadata ?? {}),
  };
  if ((payload as any).meta_ventas !== undefined) {
    mergedMetadata.meta_ventas = (payload as any).meta_ventas;
  }
  if (isContratista) {
    mergedMetadata.areas_trabajo = (payload as any).areas_trabajo ?? [];
    mergedMetadata.horario_disponible = (payload as any).horario_disponible ?? null;
    if (payload.beneficios !== undefined) mergedMetadata.beneficios = payload.beneficios;
  }

  const created = await prisma.usuario.create({
    data: {
      empresa_id: actor.empresaId,
      email,
      password_hash: await hashPassword(rawPassword),

      nombre_completo: payload.nombre_completo,
      rol: payload.rol as any,
      posicion: payload.posicion ?? payload.rol,

      telefono: payload.telefono,
      direccion: payload.direccion,
      ubicacion_mapa: payload.ubicacion_mapa,

      fecha_nacimiento: payload.fecha_nacimiento,
      edad: edad ?? undefined,
      lugar_nacimiento: payload.lugar_nacimiento,
      cedula_numero: payload.cedula_numero,

      tiene_casa_propia: tieneCasa ?? false,
      tiene_vehiculo: payload.tiene_vehiculo ?? false,
      tipo_vehiculo: payload.tipo_vehiculo,
      placa_vehiculo: placa,
      es_casado: payload.es_casado ?? false,
      cantidad_hijos: payload.cantidad_hijos ?? 0,

      ultimo_trabajo: payload.ultimo_trabajo,
      motivo_salida_ultimo_trabajo: payload.motivo_salida_ultimo_trabajo,

      fecha_ingreso_empresa: payload.fecha_ingreso_empresa,
      salario_mensual: payload.salario_mensual,
      beneficios: beneficiosString,

      es_tecnico_con_licencia: payload.es_tecnico_con_licencia ?? false,
      numero_licencia_tecnica: payload.numero_licencia_tecnica,
      licencia_conducir_numero: payload.licencia_conducir_numero,
      licencia_conducir_fecha_vencimiento: payload.licencia_conducir_fecha_vencimiento,

      foto_perfil_url: docs.foto_perfil_url,
      cedula_foto_frontal_url: docs.cedula_foto_frontal_url,
      cedula_foto_posterior_url: docs.cedula_foto_posterior_url,
      licencia_conducir_foto_url: docs.licencia_conducir_foto_url,
      carta_ultimo_trabajo_url: docs.carta_ultimo_trabajo_url,
      otros_documentos_url: docs.otros_documentos_url,

      estado: 'activo',
      metadata: mergedMetadata,
    },
  });

  res.status(201).json({ item: sanitizeUser(created) });
}

export async function updateUser(req: Request, res: Response) {
  const actor = req.user!;
  const { id } = req.params;

  await assertCanEditUser(req, id);

  const parsed = updateUserSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid user payload', parsed.error.flatten());
  }

  const existing = await prisma.usuario.findFirst({ where: { id, empresa_id: actor.empresaId } });
  if (!existing) throw new ApiError(404, 'User not found');

  const data: any = {};

  const isAdmin = isAdminRole(actor.role);
  const self = actor.userId === id;

  if (!isAdmin && self) {
    const allowedKeys = new Set(['nombre_completo', 'email', 'foto_perfil_url', 'password']);
    const bodyKeys = Object.keys(req.body ?? {});
    const illegal = bodyKeys.filter((k) => !allowedKeys.has(k));
    if (illegal.length > 0) {
      throw new ApiError(400, `Campos no editables en perfil: ${illegal.join(', ')}`);
    }
  }

  // Admin-only fields
  if (isAdmin) {
    if (parsed.data.email !== undefined) data.email = parsed.data.email;
    if (parsed.data.rol !== undefined) {
      data.rol = parsed.data.rol as any;
      data.posicion = parsed.data.posicion ?? parsed.data.rol;
    }
    if (parsed.data.posicion !== undefined) data.posicion = parsed.data.posicion;
    if (parsed.data.estado !== undefined) data.estado = parsed.data.estado;
  } else if (self) {
    // Self-edit allowed: ONLY name/email/password/profile photo
    if (parsed.data.nombre_completo !== undefined) data.nombre_completo = parsed.data.nombre_completo;
    if (parsed.data.email !== undefined) data.email = parsed.data.email;
    if (parsed.data.foto_perfil_url !== undefined) data.foto_perfil_url = parsed.data.foto_perfil_url;
    if ((parsed.data as any).password !== undefined) {
      const raw = ((parsed.data as any).password as string).trim();
      data.password_hash = await hashPassword(raw);
      data.token_version = { increment: 1 };
    }
  }

  // Common fields allowed for admin and self
  if (isAdmin) {
    if (parsed.data.nombre_completo !== undefined) data.nombre_completo = parsed.data.nombre_completo;
    if (parsed.data.telefono !== undefined) data.telefono = parsed.data.telefono;
    if (parsed.data.direccion !== undefined) data.direccion = parsed.data.direccion;
    if (parsed.data.ubicacion_mapa !== undefined) data.ubicacion_mapa = parsed.data.ubicacion_mapa;

    if (parsed.data.fecha_nacimiento !== undefined) {
      data.fecha_nacimiento = parsed.data.fecha_nacimiento;
      data.edad = computeAgeFromBirthDate(parsed.data.fecha_nacimiento);
    }
    if (parsed.data.lugar_nacimiento !== undefined) data.lugar_nacimiento = parsed.data.lugar_nacimiento;
    if (parsed.data.cedula_numero !== undefined) data.cedula_numero = parsed.data.cedula_numero;

    if (parsed.data.tiene_casa !== undefined) data.tiene_casa_propia = parsed.data.tiene_casa;
    if (parsed.data.tiene_casa_propia !== undefined) data.tiene_casa_propia = parsed.data.tiene_casa_propia;
    if (parsed.data.tiene_vehiculo !== undefined) data.tiene_vehiculo = parsed.data.tiene_vehiculo;
    if (parsed.data.tipo_vehiculo !== undefined) data.tipo_vehiculo = parsed.data.tipo_vehiculo;
    if (parsed.data.placa !== undefined) data.placa_vehiculo = parsed.data.placa;
    if (parsed.data.placa_vehiculo !== undefined) data.placa_vehiculo = parsed.data.placa_vehiculo;
    if (parsed.data.es_casado !== undefined) data.es_casado = parsed.data.es_casado;
    if (parsed.data.cantidad_hijos !== undefined) data.cantidad_hijos = parsed.data.cantidad_hijos;

    if (parsed.data.ultimo_trabajo !== undefined) data.ultimo_trabajo = parsed.data.ultimo_trabajo;
    if (parsed.data.motivo_salida_ultimo_trabajo !== undefined)
      data.motivo_salida_ultimo_trabajo = parsed.data.motivo_salida_ultimo_trabajo;

    if (parsed.data.fecha_ingreso_empresa !== undefined) data.fecha_ingreso_empresa = parsed.data.fecha_ingreso_empresa;
    if (parsed.data.salario_mensual !== undefined) data.salario_mensual = parsed.data.salario_mensual;
    if (parsed.data.beneficios !== undefined) data.beneficios = parsed.data.beneficios;

    if (parsed.data.es_tecnico_con_licencia !== undefined) data.es_tecnico_con_licencia = parsed.data.es_tecnico_con_licencia;
    if (parsed.data.numero_licencia_tecnica !== undefined) data.numero_licencia_tecnica = parsed.data.numero_licencia_tecnica;
    if (parsed.data.licencia_conducir_numero !== undefined) data.licencia_conducir_numero = parsed.data.licencia_conducir_numero;
    if (parsed.data.licencia_conducir_fecha_vencimiento !== undefined)
      data.licencia_conducir_fecha_vencimiento = parsed.data.licencia_conducir_fecha_vencimiento;

    const docs = normalizeUserDocsPayload(parsed.data);
    if (docs.foto_perfil_url !== undefined) data.foto_perfil_url = docs.foto_perfil_url;
    if (docs.cedula_foto_frontal_url !== undefined) data.cedula_foto_frontal_url = docs.cedula_foto_frontal_url;
    if (docs.cedula_foto_posterior_url !== undefined) data.cedula_foto_posterior_url = docs.cedula_foto_posterior_url;
    if (docs.licencia_conducir_foto_url !== undefined) data.licencia_conducir_foto_url = docs.licencia_conducir_foto_url;
    if (docs.carta_ultimo_trabajo_url !== undefined) data.carta_ultimo_trabajo_url = docs.carta_ultimo_trabajo_url;
    if (docs.otros_documentos_url !== undefined) data.otros_documentos_url = docs.otros_documentos_url;

    if (
      parsed.data.metadata !== undefined ||
      (parsed.data as any).meta_ventas !== undefined ||
      (parsed.data as any).areas_trabajo !== undefined ||
      (parsed.data as any).horario_disponible !== undefined
    ) {
      const merged: any = { ...((existing as any).metadata ?? {}) };
      if (parsed.data.metadata !== undefined) {
        Object.assign(merged, parsed.data.metadata as any);
      }
      if ((parsed.data as any).meta_ventas !== undefined) {
        merged.meta_ventas = (parsed.data as any).meta_ventas;
      }
      if ((parsed.data as any).areas_trabajo !== undefined) {
        merged.areas_trabajo = (parsed.data as any).areas_trabajo;
      }
      if ((parsed.data as any).horario_disponible !== undefined) {
        merged.horario_disponible = (parsed.data as any).horario_disponible;
      }

      data.metadata = merged;
    }
  }

  if (Object.keys(data).length === 0) {
    throw new ApiError(400, 'No editable fields provided');
  }

  const updated = await prisma.usuario.update({
    where: { id },
    data,
  });

  res.json({ item: sanitizeUser(updated) });
}

export async function iaExtractDesdeCedula(req: Request, res: Response) {
  const file = (req as any).file as Express.Multer.File | undefined;
  if (!file) {
    throw new ApiError(400, 'Debe subir la imagen en el campo "cedula_frontal"');
  }

  const extracted = await aiIdentityService.extractDataFromCedula(file.buffer);

  const normalized = {
    nombre_completo: typeof extracted.nombre_completo === 'string' ? extracted.nombre_completo.trim() : null,
    cedula_numero: typeof extracted.cedula_numero === 'string' ? extracted.cedula_numero.trim() : null,
    lugar_nacimiento: typeof extracted.lugar_nacimiento === 'string' ? extracted.lugar_nacimiento.trim() : null,
    fecha_nacimiento: typeof extracted.fecha_nacimiento === 'string' ? extracted.fecha_nacimiento.trim() : null,
  };

  let edad: number | null = null;
  if (normalized.fecha_nacimiento) {
    const d = new Date(normalized.fecha_nacimiento);
    if (!Number.isNaN(d.getTime())) edad = computeAgeFromBirthDate(d);
  }

  res.json({ extracted: normalized, suggested: { edad } });
}

export async function iaExtractDesdeLicencia(req: Request, res: Response) {
  const file = (req as any).file as Express.Multer.File | undefined;
  if (!file) {
    throw new ApiError(400, 'Debe subir la imagen en el campo "licencia_frontal"');
  }

  const extracted = await aiIdentityService.extractDataFromLicencia(file.buffer);

  const normalized = {
    numero_licencia: typeof extracted.numero_licencia === 'string' ? extracted.numero_licencia.trim() : null,
    fecha_vencimiento: typeof extracted.fecha_vencimiento === 'string' ? extracted.fecha_vencimiento.trim() : null,
    nombre_completo: typeof extracted.nombre_completo === 'string' ? extracted.nombre_completo.trim() : null,
    fecha_nacimiento: typeof extracted.fecha_nacimiento === 'string' ? extracted.fecha_nacimiento.trim() : null,
  };

  res.json({ extracted: normalized });
}

export async function getUserProfilePdf(req: Request, res: Response) {
  const { id } = req.params;
  await assertCanViewUser(req, id);

  const actor = req.user!;

  const [company, empresa, user] = await Promise.all([
    prisma.companySettings.findUnique({ where: { empresa_id: actor.empresaId } }),
    prisma.empresa.findUnique({ where: { id: actor.empresaId } }),
    prisma.usuario.findFirst({ where: { id, empresa_id: actor.empresaId } }),
  ]);

  if (!user) throw new ApiError(404, 'User not found');

  const companyForPdf = {
    nombre_empresa: company?.nombre_empresa ?? empresa?.nombre ?? 'FULLTECH',
    rnc: company?.rnc ?? 'N/A',
    telefono: company?.telefono ?? 'N/A',
    direccion: company?.direccion ?? 'N/A',
  };

  const pdf = await buildUserProfilePdf(
    companyForPdf,
    {
      nombre_completo: user.nombre_completo,
      email: user.email,
      rol: String(user.rol),
      posicion: user.posicion,
      telefono: user.telefono,
      direccion: user.direccion,
      ubicacion_mapa: user.ubicacion_mapa,
      fecha_nacimiento: user.fecha_nacimiento,
      edad: user.edad,
      lugar_nacimiento: user.lugar_nacimiento,
      cedula_numero: user.cedula_numero,
      tiene_casa_propia: user.tiene_casa_propia,
      tiene_vehiculo: user.tiene_vehiculo,
      tipo_vehiculo: user.tipo_vehiculo,
      es_casado: user.es_casado,
      cantidad_hijos: user.cantidad_hijos,
      ultimo_trabajo: user.ultimo_trabajo,
      motivo_salida_ultimo_trabajo: user.motivo_salida_ultimo_trabajo,
      fecha_ingreso_empresa: user.fecha_ingreso_empresa,
      salario_mensual: user.salario_mensual ? user.salario_mensual.toString() : null,
      beneficios: user.beneficios,
      es_tecnico_con_licencia: user.es_tecnico_con_licencia,
      numero_licencia_tecnica: user.numero_licencia_tecnica,
      licencia_conducir_numero: user.licencia_conducir_numero,
      licencia_conducir_fecha_vencimiento: user.licencia_conducir_fecha_vencimiento,
    },
  );

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `inline; filename="user_${id}_profile.pdf"`);
  res.status(200).send(pdf);
}

export async function getUserContractPdf(req: Request, res: Response) {
  const { id } = req.params;
  await assertCanViewUser(req, id);

  const actor = req.user!;

  const [company, empresa, user] = await Promise.all([
    prisma.companySettings.findUnique({ where: { empresa_id: actor.empresaId } }),
    prisma.empresa.findUnique({ where: { id: actor.empresaId } }),
    prisma.usuario.findFirst({ where: { id, empresa_id: actor.empresaId } }),
  ]);

  if (!user) throw new ApiError(404, 'User not found');

  const companyForPdf = {
    nombre_empresa: company?.nombre_empresa ?? empresa?.nombre ?? 'FULLTECH',
    rnc: company?.rnc ?? 'N/A',
    telefono: company?.telefono ?? 'N/A',
    direccion: company?.direccion ?? 'N/A',
  };

  const pdf = await buildUserContractPdf(
    companyForPdf,
    {
      nombre_completo: user.nombre_completo,
      email: user.email,
      rol: String(user.rol),
      posicion: user.posicion,
      telefono: user.telefono,
      direccion: user.direccion,
      ubicacion_mapa: user.ubicacion_mapa,
      fecha_nacimiento: user.fecha_nacimiento,
      edad: user.edad,
      lugar_nacimiento: user.lugar_nacimiento,
      cedula_numero: user.cedula_numero,
      tiene_casa_propia: user.tiene_casa_propia,
      tiene_vehiculo: user.tiene_vehiculo,
      tipo_vehiculo: user.tipo_vehiculo,
      es_casado: user.es_casado,
      cantidad_hijos: user.cantidad_hijos,
      ultimo_trabajo: user.ultimo_trabajo,
      motivo_salida_ultimo_trabajo: user.motivo_salida_ultimo_trabajo,
      fecha_ingreso_empresa: user.fecha_ingreso_empresa,
      salario_mensual: user.salario_mensual ? user.salario_mensual.toString() : null,
      beneficios: user.beneficios,
      es_tecnico_con_licencia: user.es_tecnico_con_licencia,
      numero_licencia_tecnica: user.numero_licencia_tecnica,
      licencia_conducir_numero: user.licencia_conducir_numero,
      licencia_conducir_fecha_vencimiento: user.licencia_conducir_fecha_vencimiento,
    },
  );

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `inline; filename="user_${id}_contract.pdf"`);
  res.status(200).send(pdf);
}

export async function blockUser(req: Request, res: Response) {
  const actor = req.user!;
  if (!isAdminRole(actor.role)) {
    throw new ApiError(403, 'Only administrador can block users');
  }

  const { id } = req.params;

  const user = await prisma.usuario.findUnique({
    where: { id },
  });

  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  // Increment token_version to invalidate all tokens
  const updated = await prisma.usuario.update({
    where: { id },
    data: {
      estado: 'bloqueado',
      token_version: user.token_version + 1,
    },
  });

  res.json({
    message: 'User blocked successfully',
    user: sanitizeUser(updated),
  });
}

export async function unblockUser(req: Request, res: Response) {
  const actor = req.user!;
  if (!isAdminRole(actor.role)) {
    throw new ApiError(403, 'Only administrador can unblock users');
  }

  const { id } = req.params;

  const user = await prisma.usuario.findUnique({
    where: { id },
  });

  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  // Increment token_version to invalidate all tokens
  const updated = await prisma.usuario.update({
    where: { id },
    data: {
      estado: 'activo',
      token_version: user.token_version + 1,
    },
  });

  res.json({
    message: 'User unblocked successfully',
    user: sanitizeUser(updated),
  });
}

export async function deleteUser(req: Request, res: Response) {
  const actor = req.user!;
  if (!isAdminRole(actor.role)) {
    throw new ApiError(403, 'Only administrador can delete users');
  }

  const { id } = req.params;

  const user = await prisma.usuario.findUnique({
    where: { id },
  });

  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  // Soft delete: set estado to 'eliminado' and increment token_version
  const updated = await prisma.usuario.update({
    where: { id },
    data: {
      estado: 'eliminado',
      token_version: user.token_version + 1,
    },
  });

  res.json({
    message: 'User deleted successfully',
    user: sanitizeUser(updated),
  });
}
