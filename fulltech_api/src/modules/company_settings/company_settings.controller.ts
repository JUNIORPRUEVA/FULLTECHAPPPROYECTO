import type { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { companySettingsSchema } from './company_settings.schema';

function isAdminRole(role: string | undefined): boolean {
  return role === 'admin' || role === 'administrador';
}

export async function getCompanySettings(req: Request, res: Response) {
  const actor = req.user!;
  if (!isAdminRole(actor.role)) throw new ApiError(403, 'Only administrador can access company settings');

  const item = await prisma.companySettings.findUnique({
    where: { empresa_id: actor.empresaId },
  });

  res.json({ item });
}

export async function upsertCompanySettings(req: Request, res: Response) {
  const actor = req.user!;
  if (!isAdminRole(actor.role)) throw new ApiError(403, 'Only administrador can edit company settings');

  const parsed = companySettingsSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid company settings payload', parsed.error.flatten());
  }

  const item = await prisma.companySettings.upsert({
    where: { empresa_id: actor.empresaId },
    create: {
      empresa_id: actor.empresaId,
      ...parsed.data,
    },
    update: {
      ...parsed.data,
    },
  });

  res.json({ item });
}

export async function uploadCompanyLogo(req: Request, res: Response) {
  const actor = req.user!;
  if (!isAdminRole(actor.role)) throw new ApiError(403, 'Only administrador can edit company settings');

  const file = req.file;
  if (!file) {
    throw new ApiError(400, 'Missing file field "file"');
  }

  const logoUrl = `/uploads/company/${file.filename}`;

  const existing = await prisma.companySettings.findUnique({
    where: { empresa_id: actor.empresaId },
  });
  if (!existing) {
    throw new ApiError(400, 'Debe guardar los datos de la empresa antes de subir el logo');
  }

  const item = await prisma.companySettings.update({
    where: { empresa_id: actor.empresaId },
    data: { logo_url: logoUrl },
  });

  res.status(201).json({ logo_url: logoUrl, item });
}
