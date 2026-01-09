import type { Request, Response } from 'express';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import {
  createJobSchema,
  listJobsQuerySchema,
  patchJobSchema,
  completeJobSchema,
  submitSurveySchema,
  scheduleJobSchema,
  startInstallationSchema,
  completeInstallationSchema,
  createWarrantyTicketSchema,
  patchWarrantyTicketSchema,
} from './operations.schema';

function actorEmpresaId(req: Request): string {
  const actor = req.user;
  if (!actor?.empresaId) throw new ApiError(401, 'Unauthorized');
  return actor.empresaId;
}

function actorUserId(req: Request): string {
  const actor = req.user;
  if (!actor?.userId) throw new ApiError(401, 'Unauthorized');
  return actor.userId;
}

function parseDateOnly(value: string): Date {
  // value: YYYY-MM-DD
  const [y, m, d] = value.split('-').map((v) => Number(v));
  if (!y || !m || !d) throw new ApiError(400, 'Invalid scheduled_date');
  return new Date(Date.UTC(y, m - 1, d, 0, 0, 0));
}

function parseDate(value: unknown): Date | null {
  if (typeof value !== 'string' || value.trim().length === 0) return null;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return d;
}

export async function createJob(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);
  const created_by_user_id = actorUserId(req);

  const parsed = createJobSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const body = parsed.data;

  // Load customer to cache fields
  const customer = await prisma.customer.findFirst({
    where: { id: body.crm_customer_id, empresa_id, deleted_at: null },
  });
  if (!customer) throw new ApiError(404, 'Customer not found');

  const data: Prisma.OperationsJobCreateInput = {
    id: body.id,
    empresa: { connect: { id: empresa_id } },
    created_by: { connect: { id: created_by_user_id } },
    assigned_tech: body.assigned_tech_id
      ? { connect: { id: body.assigned_tech_id } }
      : undefined,
    assigned_team_ids: body.assigned_team_ids ?? [],
    crm_customer: { connect: { id: customer.id } },
    customer_name: customer.nombre,
    customer_phone: customer.telefono,
    customer_address: customer.direccion ?? customer.ubicacion_mapa ?? null,
    service_type: body.service_type,
    priority: body.priority ?? 'normal',
    status: body.initial_status,
    notes: body.notes ?? null,
  };

  // Idempotent create (offline-first retries): if id exists, return it.
  if (body.id) {
    const existing = await prisma.operationsJob.findFirst({
      where: { id: body.id, empresa_id, deleted_at: null },
      include: { survey: true, schedule: true, warranty_tickets: true },
    });
    if (existing) {
      res.status(200).json(existing);
      return;
    }
  }

  const created = await prisma.operationsJob.create({
    data,
    include: { survey: true, schedule: true, warranty_tickets: true },
  });
  res.status(201).json(created);
}

export async function listJobs(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);

  const parsed = listJobsQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid query', parsed.error.flatten());
  }

  const q = (parsed.data.search ?? parsed.data.q)?.trim();
  const status = parsed.data.status;
  const assigned_tech_id = parsed.data.assigned_tech_id;
  const from = parseDate(parsed.data.from);
  const to = parseDate(parsed.data.to);

  const limit = parsed.data.limit;
  const offset =
    typeof parsed.data.offset === 'number'
      ? parsed.data.offset
      : (parsed.data.page - 1) * parsed.data.limit;

  const where: Prisma.OperationsJobWhereInput = {
    empresa_id,
    deleted_at: null,
    ...(status ? { status } : {}),
    ...(assigned_tech_id
      ? {
          OR: [
            { assigned_tech_id },
            { technician_user_id: assigned_tech_id },
          ],
        }
      : {}),
    ...(from || to
      ? {
          created_at: {
            ...(from ? { gte: from } : {}),
            ...(to ? { lte: to } : {}),
          },
        }
      : {}),
    ...(q
      ? {
          OR: [
            { customer_name: { contains: q, mode: 'insensitive' } },
            { customer_phone: { contains: q, mode: 'insensitive' } },
            { customer_address: { contains: q, mode: 'insensitive' } },
            { address_text: { contains: q, mode: 'insensitive' } },
            { id: { equals: q } },
          ],
        }
      : {}),
  };

  try {
    const [total, items] = await Promise.all([
      prisma.operationsJob.count({ where }),
      prisma.operationsJob.findMany({
        where,
        orderBy: [{ created_at: 'desc' }],
        take: limit,
        skip: offset,
        include: {
          service: true,
          product: true,
          technician: true,
          vendedor: true,
        },
      }),
    ]);

    res.json({ items, total, limit, offset });
  } catch (e: any) {
    // Avoid hard 500 loops if migrations haven't been applied yet.
    const code = e?.code ?? e?.meta?.code;
    const msg = e?.message ?? String(e);
    console.error('[Operations] listJobs failed', { code, msg });

    // Prisma: P2021 = table does not exist, P2022 = column does not exist
    if (code === 'P2021' || code === 'P2022') {
      res.json({ items: [], total: 0, limit, offset });
      return;
    }

    // PrismaClientValidationError often means the runtime Prisma Client is out of date
    // (e.g. deployed without running prisma generate). Fall back to a minimal query.
    const name = String(e?.name ?? '');
    const looksLikeValidation =
      name.includes('PrismaClientValidationError') ||
      msg.includes('Unknown arg') ||
      msg.includes('Unknown field') ||
      msg.includes('include');

    if (looksLikeValidation) {
      try {
        const [total, items] = await Promise.all([
          prisma.operationsJob.count({ where }),
          prisma.operationsJob.findMany({
            where,
            orderBy: [{ created_at: 'desc' }],
            take: limit,
            skip: offset,
          }),
        ]);

        res.json({ items, total, limit, offset });
        return;
      } catch (fallbackErr: any) {
        const fCode = fallbackErr?.code ?? fallbackErr?.meta?.code;
        const fMsg = fallbackErr?.message ?? String(fallbackErr);
        console.error('[Operations] listJobs fallback failed', { fCode, fMsg });
        res.json({ items: [], total: 0, limit, offset });
        return;
      }
    }

    throw e;
  }
}

export async function completeJob(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);
  const id = req.params.id;

  const parsed = completeJobSchema.safeParse(req.body ?? {});
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const existing = await prisma.operationsJob.findFirst({
    where: { id, empresa_id, deleted_at: null },
  });
  if (!existing) throw new ApiError(404, 'Job not found');

  const completedAt = parseDate(parsed.data.completed_at) ?? new Date();

  const updated = await prisma.operationsJob.update({
    where: { id },
    data: {
      status: 'INSTALACION_FINALIZADA',
      completed_at: completedAt,
    },
  });

  res.json(updated);
}

export async function getJob(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);
  const id = req.params.id;

  const job = await prisma.operationsJob.findFirst({
    where: { id, empresa_id, deleted_at: null },
    include: {
      survey: { include: { media: true } },
      schedule: true,
      installation_reports: { orderBy: { created_at: 'desc' } },
      warranty_tickets: { orderBy: { reported_at: 'desc' } },
    },
  });
  if (!job) throw new ApiError(404, 'Job not found');
  res.json(job);
}

export async function patchJob(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);
  const id = req.params.id;

  const parsed = patchJobSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const body = parsed.data;

  const existing = await prisma.operationsJob.findFirst({
    where: { id, empresa_id, deleted_at: null },
  });
  if (!existing) throw new ApiError(404, 'Job not found');

  const updated = await prisma.operationsJob.update({
    where: { id },
    data: {
      status: body.status ?? undefined,
      priority: body.priority ?? undefined,
      notes: body.notes ?? undefined,
      assigned_team_ids: body.assigned_team_ids ?? undefined,
      assigned_tech_id:
        body.assigned_tech_id === undefined
          ? undefined
          : body.assigned_tech_id,
    },
  });

  res.json(updated);
}

export async function submitSurvey(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);
  const tech_id = actorUserId(req);

  const parsed = submitSurveySchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const body = parsed.data;

  const job = await prisma.operationsJob.findFirst({
    where: { id: body.job_id, empresa_id, deleted_at: null },
  });
  if (!job) throw new ApiError(404, 'Job not found');

  if (body.mode === 'physical') {
    if (typeof body.gps_lat !== 'number' || typeof body.gps_lng !== 'number') {
      throw new ApiError(400, 'gps_lat and gps_lng are required for physical surveys');
    }
  }

  const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    const survey = await tx.operationsSurvey.upsert({
      where: { job_id: body.job_id },
      create: {
        id: body.id,
        job: { connect: { id: body.job_id } },
        mode: body.mode,
        gps_lat: body.gps_lat ?? null,
        gps_lng: body.gps_lng ?? null,
        address_confirmed: body.address_confirmed ?? null,
        complexity: body.complexity ?? 'basic',
        site_notes: body.site_notes ?? null,
        tools_needed: body.tools_needed ?? null,
        materials_needed: body.materials_needed ?? null,
        products_to_use: body.products_to_use ?? null,
        future_opportunities: body.future_opportunities ?? null,
        created_by: { connect: { id: tech_id } },
      },
      update: {
        mode: body.mode,
        gps_lat: body.gps_lat ?? null,
        gps_lng: body.gps_lng ?? null,
        address_confirmed: body.address_confirmed ?? null,
        complexity: body.complexity ?? 'basic',
        site_notes: body.site_notes ?? null,
        tools_needed: body.tools_needed ?? null,
        materials_needed: body.materials_needed ?? null,
        products_to_use: body.products_to_use ?? null,
        future_opportunities: body.future_opportunities ?? null,
      },
      include: { media: true },
    });

    if (body.media && body.media.length > 0) {
      await tx.operationsSurveyMedia.deleteMany({ where: { survey_id: survey.id } });
      await tx.operationsSurveyMedia.createMany({
        data: body.media.map((m) => ({
          id: m.id,
          survey_id: survey.id,
          type: m.type,
          url_or_path: m.url_or_path,
          caption: m.caption ?? null,
        })),
      });
    }

    await tx.operationsJob.update({
      where: { id: body.job_id },
      data: {
        status: 'pending_scheduling',
        updated_at: new Date(),
      },
    });

    const full = await tx.operationsSurvey.findUnique({
      where: { id: survey.id },
      include: { media: true },
    });

    return full;
  });

  res.status(201).json(result);
}

export async function scheduleJob(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);

  const parsed = scheduleJobSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const body = parsed.data;

  const job = await prisma.operationsJob.findFirst({
    where: { id: body.job_id, empresa_id, deleted_at: null },
  });
  if (!job) throw new ApiError(404, 'Job not found');

  const scheduled_date = parseDateOnly(body.scheduled_date);

  const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    const schedule = await tx.operationsSchedule.upsert({
      where: { job_id: body.job_id },
      create: {
        id: body.id,
        job: { connect: { id: body.job_id } },
        scheduled_date,
        preferred_time: body.preferred_time ?? null,
        assigned_tech: { connect: { id: body.assigned_tech_id } },
        additional_tech_ids: body.additional_tech_ids ?? [],
        customer_availability_notes: body.customer_availability_notes ?? null,
      },
      update: {
        scheduled_date,
        preferred_time: body.preferred_time ?? null,
        assigned_tech: { connect: { id: body.assigned_tech_id } },
        additional_tech_ids: body.additional_tech_ids ?? [],
        customer_availability_notes: body.customer_availability_notes ?? null,
      },
    });

    await tx.operationsJob.update({
      where: { id: body.job_id },
      data: {
        status: 'scheduled',
        assigned_tech_id: body.assigned_tech_id,
      },
    });

    return schedule;
  });

  res.status(201).json(result);
}

export async function startInstallation(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);
  const tech_id = actorUserId(req);

  const parsed = startInstallationSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const body = parsed.data;

  const job = await prisma.operationsJob.findFirst({
    where: { id: body.job_id, empresa_id, deleted_at: null },
  });
  if (!job) throw new ApiError(404, 'Job not found');

  const startedAt = parseDate(body.started_at) ?? new Date();

  const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    await tx.operationsJob.update({
      where: { id: body.job_id },
      data: { status: 'installation_in_progress' },
    });

    const report = await tx.operationsInstallationReport.create({
      data: {
        job: { connect: { id: body.job_id } },
        started_at: startedAt,
        created_by: { connect: { id: tech_id } },
      },
    });

    return report;
  });

  res.status(201).json(result);
}

export async function completeInstallation(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);
  const tech_id = actorUserId(req);

  const parsed = completeInstallationSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const body = parsed.data;

  const job = await prisma.operationsJob.findFirst({
    where: { id: body.job_id, empresa_id, deleted_at: null },
  });
  if (!job) throw new ApiError(404, 'Job not found');

  const finishedAt = parseDate(body.finished_at) ?? new Date();

  const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    const report = await tx.operationsInstallationReport.create({
      data: {
        id: body.id,
        job: { connect: { id: body.job_id } },
        finished_at: finishedAt,
        tech_notes: body.tech_notes ?? null,
        work_done_summary: body.work_done_summary ?? null,
        installed_products: body.installed_products ?? null,
        media_urls: body.media_urls ?? [],
        signature_name: body.signature_name ?? null,
        created_by: { connect: { id: tech_id } },
      },
    });

    await tx.operationsJob.update({
      where: { id: body.job_id },
      data: { status: 'completed' },
    });

    return report;
  });

  res.status(201).json(result);
}

export async function createWarrantyTicket(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);

  const parsed = createWarrantyTicketSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const body = parsed.data;

  const job = await prisma.operationsJob.findFirst({
    where: { id: body.job_id, empresa_id, deleted_at: null },
  });
  if (!job) throw new ApiError(404, 'Job not found');

  const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    const ticket = await tx.operationsWarrantyTicket.create({
      data: {
        id: body.id,
        job: { connect: { id: body.job_id } },
        reason: body.reason,
        ...(body.assigned_tech_id
          ? { assigned_tech: { connect: { id: body.assigned_tech_id } } }
          : {}),
      },
    });

    await tx.operationsJob.update({
      where: { id: body.job_id },
      data: { status: 'warranty_pending' },
    });

    return ticket;
  });

  res.status(201).json(result);
}

export async function patchWarrantyTicket(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);
  const id = req.params.id;

  const parsed = patchWarrantyTicketSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const body = parsed.data;

  const existing = await prisma.operationsWarrantyTicket.findFirst({
    where: { id, job: { empresa_id, deleted_at: null } },
    include: { job: true },
  });
  if (!existing) throw new ApiError(404, 'Warranty ticket not found');

  const resolvedAt = body.resolved_at ? parseDate(body.resolved_at) : null;

  const assignedTechPatch:
    | { assigned_tech?: undefined }
    | { assigned_tech: { connect: { id: string } } }
    | { assigned_tech: { disconnect: true } } =
    body.assigned_tech_id === undefined
      ? {}
      : body.assigned_tech_id === null
        ? { assigned_tech: { disconnect: true } }
        : { assigned_tech: { connect: { id: body.assigned_tech_id } } };

  const updated = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    const ticket = await tx.operationsWarrantyTicket.update({
      where: { id },
      data: {
        status: body.status ?? undefined,
        ...assignedTechPatch,
        resolution_notes: body.resolution_notes ?? undefined,
        resolved_at: resolvedAt ?? undefined,
      },
    });

    if (body.status === 'resolved') {
      // If all tickets resolved, close job.
      const remaining = await tx.operationsWarrantyTicket.count({
        where: {
          job_id: existing.job_id,
          status: { in: ['pending', 'in_progress'] },
        },
      });
      if (remaining === 0) {
        await tx.operationsJob.update({
          where: { id: existing.job_id },
          data: { status: 'closed' },
        });
      }
    } else if (body.status === 'in_progress') {
      await tx.operationsJob.update({
        where: { id: existing.job_id },
        data: { status: 'warranty_in_progress' },
      });
    }

    return ticket;
  });

  res.json(updated);
}
