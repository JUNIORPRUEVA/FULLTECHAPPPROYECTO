import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import {
  createUserSchema,
  updateUserSchema,
  listUsersQuerySchema,
  CreateUserInput,
  UpdateUserInput,
} from './usuarios.schema';
import { aiIdentityService } from '../../services/aiIdentityService';

const prisma = new PrismaClient();

export class UsuariosController {
  /**
   * GET /api/usuarios
   * Lista usuarios con filtros y búsqueda
   */
  static async listUsuarios(req: Request, res: Response) {
    try {
      const query = listUsersQuerySchema.parse(req.query);
      const { page, limit, rol, estado, search } = query;
      const skip = (page - 1) * limit;

      // Construir filtros
      const where: any = {
        estado: estado || { in: ['activo', 'bloqueado'] }, // Excluye eliminados por defecto
      };

      if (rol) {
        where.rol = rol;
      }

      if (search) {
        where.OR = [
          { nombre_completo: { contains: search, mode: 'insensitive' } },
          { email: { contains: search, mode: 'insensitive' } },
          { telefono: { contains: search, mode: 'insensitive' } },
          { cedula_numero: { contains: search, mode: 'insensitive' } },
        ];
      }

      const [usuarios, total] = await Promise.all([
        prisma.usuario.findMany({
          where,
          skip,
          take: limit,
          select: {
            id: true,
            nombre_completo: true,
            email: true,
            rol: true,
            posicion: true,
            telefono: true,
            estado: true,
            foto_perfil_url: true,
            fecha_ingreso_empresa: true,
            cedula_numero: true,
          },
          orderBy: { created_at: 'desc' },
        }),
        prisma.usuario.count({ where }),
      ]);

      res.json({
        data: usuarios,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit),
        },
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }

  /**
   * GET /api/usuarios/:id
   * Obtener usuario completo por ID
   */
  static async getUsuario(req: Request, res: Response) {
    try {
      const { id } = req.params;

      const usuario = await prisma.usuario.findUnique({
        where: { id },
      });

      if (!usuario) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      // Calcular edad a partir de fecha_nacimiento
      const edad = usuario.fecha_nacimiento
        ? aiIdentityService.calculateAge(usuario.fecha_nacimiento.toISOString().split('T')[0])
        : null;

      res.json({
        ...usuario,
        edad, // Devolver edad calculada
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }

  /**
   * POST /api/usuarios
   * Crear nuevo usuario
   */
  static async createUsuario(req: Request, res: Response) {
    try {
      const data = createUserSchema.parse(req.body);
      const empresaId = req.user?.empresa_id || (await prisma.empresa.findFirst())?.id;

      if (!empresaId) {
        return res.status(400).json({ error: 'Empresa no configurada' });
      }

      // Para roles que requieren email, verificar email único
      if (data.email) {
        const existingUser = await prisma.usuario.findUnique({
          where: { email: data.email },
        });

        if (existingUser) {
          return res.status(400).json({ error: 'Email ya registrado' });
        }
      }

      // Hash password solo si se proporciona
      let passwordHash = undefined;
      if (data.password) {
        passwordHash = await bcrypt.hash(data.password, 10);
      }

      // Parsear fechas solo si se proporcionan
      let fechaNacimiento: Date | undefined;
      let fechaIngreso: Date | undefined;
      let edad: number | null = null;

      if (data.fecha_nacimiento) {
        fechaNacimiento = new Date(data.fecha_nacimiento);
        edad = aiIdentityService.calculateAge(
          fechaNacimiento.toISOString().split('T')[0],
        );
      }

      if (data.fecha_ingreso_empresa) {
        fechaIngreso = new Date(data.fecha_ingreso_empresa);
      }

      // Preparar datos de creación
      const createData: any = {
        empresa_id: empresaId,
        nombre_completo: data.nombre_completo,
        rol: data.rol,
        posicion: data.rol, // posicion = rol por defecto
        cedula_numero: data.cedula_numero,
        telefono: data.telefono,
        direccion: data.direccion,
        estado: 'activo',
      };

      // Agregar campos opcionales solo si existen
      if (data.email) createData.email = data.email;
      if (passwordHash) createData.password_hash = passwordHash;
      if (fechaNacimiento) createData.fecha_nacimiento = fechaNacimiento;
      if (edad !== null) createData.edad = edad;
      if (data.lugar_nacimiento) createData.lugar_nacimiento = data.lugar_nacimiento;
      if (data.ubicacion_mapa) createData.ubicacion_mapa = data.ubicacion_mapa;
      if (data.tiene_casa_propia !== undefined) createData.tiene_casa_propia = data.tiene_casa_propia;
      if (data.tiene_vehiculo !== undefined) createData.tiene_vehiculo = data.tiene_vehiculo;
      if (data.tipo_vehiculo) createData.tipo_vehiculo = data.tipo_vehiculo;
      if (data.placa) createData.placa = data.placa;
      if (data.es_casado !== undefined) createData.es_casado = data.es_casado;
      if (data.cantidad_hijos !== undefined) createData.cantidad_hijos = data.cantidad_hijos;
      if (data.ultimo_trabajo) createData.ultimo_trabajo = data.ultimo_trabajo;
      if (data.motivo_salida_ultimo_trabajo) createData.motivo_salida_ultimo_trabajo = data.motivo_salida_ultimo_trabajo;
      if (fechaIngreso) createData.fecha_ingreso_empresa = fechaIngreso;
      if (data.salario_mensual) createData.salario_mensual = data.salario_mensual;
      if (data.beneficios) createData.beneficios = data.beneficios;
      if (data.es_tecnico_con_licencia !== undefined) createData.es_tecnico_con_licencia = data.es_tecnico_con_licencia;
      if (data.numero_licencia) createData.numero_licencia = data.numero_licencia;
      if (data.area_maneja) createData.area_maneja = data.area_maneja;
      if (data.especialidades) createData.especialidades = data.especialidades;
      if (data.areas_trabajo) createData.areas_trabajo = data.areas_trabajo;
      if (data.horario_disponible) createData.horario_disponible = data.horario_disponible;
      if (data.foto_perfil_url) createData.foto_perfil_url = data.foto_perfil_url;
      if (data.cedula_foto_url) createData.cedula_foto_url = data.cedula_foto_url;
      if (data.cedula_frontal_url) createData.cedula_frontal_url = data.cedula_frontal_url;
      if (data.cedula_posterior_url) createData.cedula_posterior_url = data.cedula_posterior_url;
      if (data.licencia_conducir_url) createData.licencia_conducir_url = data.licencia_conducir_url;
      if (data.carta_trabajo_url) createData.carta_trabajo_url = data.carta_trabajo_url;
      if (data.curriculum_vitae_url) createData.curriculum_vitae_url = data.curriculum_vitae_url;
      if (data.carta_ultimo_trabajo_url) createData.carta_ultimo_trabajo_url = data.carta_ultimo_trabajo_url;

      // Crear usuario
      const usuario = await prisma.usuario.create({
        data: createData,
      });

      // No devolver password
      const { password_hash, ...usuarioSinPassword } = usuario;

      res.status(201).json(usuarioSinPassword);
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }

  /**
   * PUT /api/usuarios/:id
   * Actualizar usuario
   */
  static async updateUsuario(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const data = updateUserSchema.parse(req.body);

      const usuarioExistente = await prisma.usuario.findUnique({
        where: { id },
      });

      if (!usuarioExistente) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      // Preparar datos de actualización
      const updateData: any = {
        email: data.email,
        nombre_completo: data.nombre_completo,
        rol: data.rol,
        posicion: data.posicion || data.rol, // Si no hay posicion, usar rol
        telefono: data.telefono,
        direccion: data.direccion,
        ubicacion_mapa: data.ubicacion_mapa,
        lugar_nacimiento: data.lugar_nacimiento,
        cedula_numero: data.cedula_numero,
        tiene_casa_propia: data.tiene_casa_propia,
        tiene_vehiculo: data.tiene_vehiculo,
        tipo_vehiculo: data.tipo_vehiculo,
        es_casado: data.es_casado,
        cantidad_hijos: data.cantidad_hijos,
        ultimo_trabajo: data.ultimo_trabajo,
        motivo_salida_ultimo_trabajo: data.motivo_salida_ultimo_trabajo,
        salario_mensual: data.salario_mensual,
        beneficios: data.beneficios,
        es_tecnico_con_licencia: data.es_tecnico_con_licencia,
        numero_licencia: data.numero_licencia,
        foto_perfil_url: data.foto_perfil_url,
        cedula_foto_url: data.cedula_foto_url,
        carta_ultimo_trabajo_url: data.carta_ultimo_trabajo_url,
      };

      // Si cambia fecha_nacimiento, recalcular edad
      if (data.fecha_nacimiento) {
        const fechaNacimiento = new Date(data.fecha_nacimiento);
        updateData.fecha_nacimiento = fechaNacimiento;
        updateData.edad = aiIdentityService.calculateAge(
          fechaNacimiento.toISOString().split('T')[0],
        );
      }

      if (data.fecha_ingreso_empresa) {
        updateData.fecha_ingreso_empresa = new Date(data.fecha_ingreso_empresa);
      }

      // Filtrar null/undefined
      Object.keys(updateData).forEach(
        (key) => updateData[key] === undefined && delete updateData[key],
      );

      const usuarioActualizado = await prisma.usuario.update({
        where: { id },
        data: updateData,
      });

      const { password_hash, ...usuarioSinPassword } = usuarioActualizado;
      res.json(usuarioSinPassword);
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }

  /**
   * PATCH /api/usuarios/:id/block
   * Bloquear/desbloquear usuario
   */
  static async blockUsuario(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { bloqueado } = req.body;

      const usuario = await prisma.usuario.update({
        where: { id },
        data: {
          estado: bloqueado ? 'bloqueado' : 'activo',
        },
      });

      res.json({
        id: usuario.id,
        nombre_completo: usuario.nombre_completo,
        estado: usuario.estado,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }

  /**
   * DELETE /api/usuarios/:id
   * Soft delete: marcar como eliminado
   */
  static async deleteUsuario(req: Request, res: Response) {
    try {
      const { id } = req.params;

      await prisma.usuario.update({
        where: { id },
        data: { estado: 'eliminado' },
      });

      res.json({ message: 'Usuario eliminado' });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }

  /**
   * POST /api/usuarios/ia/cedula
   * Extraer datos de cédula usando IA
   */
  static async extractCedulaData(req: Request, res: Response) {
    try {
      const { imagenUrl } = req.body;

      if (!imagenUrl) {
        return res.status(400).json({ error: 'imagenUrl es requerida' });
      }

      // Llamar al servicio de IA
      const datosExtraidos = await aiIdentityService.extractDataFromCedula(imagenUrl);

      res.json({
        success: !datosExtraidos.error,
        data: datosExtraidos,
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: error.message,
      });
    }
  }
}
