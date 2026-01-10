import type { Request, Response } from 'express';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { ApiError } from '../../middleware/errorHandler';
import { emitCrmEvent } from '../crm/crm_stream';
import {
  createJobSchema,
  listJobsQuerySchema,
  patchJobSchema,
  patchTaskStatusSchema,
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

function actorRole(req: Request): string {
  const role = req.user?.role;
  if (!role) throw new ApiError(401, 'Unauthorized');
  return role;
}

function isAdminRole(role: string): boolean {
  return role === 'admin' || role === 'administrador' || (role as any) === 'administrador';
}

function isTechnicianRole(role: string): boolean {
  return role === 'tecnico' || role === 'tecnico_fijo' || role === 'contratista';
}

export async function listTechnicians(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);

  const q = typeof req.query.q === 'string' ? req.query.q.trim() : '';

  // IMPORTANT: Must match the actual UserRole enum stored in DB.
  // Using unknown values in an enum column will error in Postgres.
  const roles = ['tecnico', 'tecnico_fijo', 'contratista'];

  const where: any = {
    empresa_id,
    estado: 'activo',
    rol: { in: roles as any },
  };

  if (q) {
    where.OR = [
      { nombre_completo: { contains: q, mode: 'insensitive' } },
      { telefono: { contains: q, mode: 'insensitive' } },
      { email: { contains: q, mode: 'insensitive' } },
    ];
  }

  const items = await prisma.usuario.findMany({
    where,
    orderBy: [{ nombre_completo: 'asc' }],
    take: 200,
    select: {
      id: true,
      empresa_id: true,
      email: true,
      nombre_completo: true,
      rol: true,
      posicion: true,
      telefono: true,
      estado: true,
      foto_perfil_url: true,
      updated_at: true,
    },
  });

  res.json({ items });
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

let crmChatMetaExistsCache: boolean | null = null;
let crmChatMetaExistsAtMs = 0;
async function crmChatMetaExists(): Promise<boolean> {
  const now = Date.now();
  if (crmChatMetaExistsCache != null && now - crmChatMetaExistsAtMs < 60_000) {
    return crmChatMetaExistsCache;
  }
  try {
    const rows = await prisma.$queryRawUnsafe<{ regclass: string | null }[]>(
      'SELECT to_regclass($1) as regclass',
      'public.crm_chat_meta',
    );
    const exists = Boolean(rows?.[0]?.regclass);
    crmChatMetaExistsCache = exists;
    crmChatMetaExistsAtMs = now;
    return exists;
  } catch {
    crmChatMetaExistsCache = false;
    crmChatMetaExistsAtMs = now;
    return false;
  }
}

async function appendCrmInternalNote(params: {
  chatId: string;
  note: string;
}): Promise<void> {
  if (!params.note.trim()) return;
  if (!(await crmChatMetaExists())) return;

  // Upsert + append to internal_note
  await prisma.$executeRawUnsafe(
    `
    INSERT INTO crm_chat_meta (chat_id, internal_note, updated_at)
    VALUES ($1::uuid, $2::text, now())
    ON CONFLICT (chat_id) DO UPDATE SET
      internal_note = CASE
        WHEN crm_chat_meta.internal_note IS NULL OR crm_chat_meta.internal_note = '' THEN EXCLUDED.internal_note
        ELSE crm_chat_meta.internal_note || E'\\n' || EXCLUDED.internal_note
      END,
      updated_at = now()
    `,
    params.chatId,
    params.note.trim(),
  );
}

async function recordJobHistory(params: {
  tx: Prisma.TransactionClient;
  jobId: string;
  actionType: string;
  oldStatus: string | null;
  newStatus: string | null;
  note?: string | null;
  createdByUserId?: string | null;
}): Promise<void> {
  await params.tx.operationsJobHistory.create({
    data: {
      job_id: params.jobId,
      action_type: params.actionType,
      old_status: params.oldStatus ?? null,
      new_status: params.newStatus ?? null,
      note: params.note ?? null,
      created_by_user_id: params.createdByUserId ?? null,
    },
  });
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

  const q = parsed.data.q?.trim();
  const type = parsed.data.type;
  const status = parsed.data.status;
  const assigned_tech_id = parsed.data.assigned_tech_id;
  const from = parseDate(parsed.data.from);
  const to = parseDate(parsed.data.to);

  const where: Prisma.OperationsJobWhereInput = {
    empresa_id,
    deleted_at: null,
    ...(type ? { crm_task_type: type as any } : {}),
    ...(status ? { status } : {}),
    ...(assigned_tech_id ? { assigned_tech_id } : {}),
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
            { id: { equals: q } },
          ],
        }
      : {}),
  };

  const [total, items] = await Promise.all([
    prisma.operationsJob.count({ where }),
    prisma.operationsJob.findMany({
      where,
      orderBy: [{ created_at: 'desc' }],
      take: parsed.data.limit,
      skip: parsed.data.offset,
      include: {
        survey: true,
        schedule: true,
        warranty_tickets: {
          where: { status: { in: ['pending', 'in_progress'] } },
          orderBy: { reported_at: 'desc' },
        },
        assigned_tech: { select: { id: true, nombre_completo: true, rol: true } },
        crm_chat: { select: { id: true, status: true, display_name: true, phone: true } },
      },
    }),
  ]);

  const serviceIds = Array.from(
    new Set(items.map((i: any) => i.service_id).filter((v: any): v is string => Boolean(v))),
  );
  const services = serviceIds.length
    ? await prisma.service.findMany({
        where: { empresa_id, id: { in: serviceIds } },
        select: { id: true, name: true, is_active: true },
      })
    : [];
  const serviceById = new Map<string, { id: string; name: string; is_active: boolean }>();
  for (const s of services) serviceById.set(s.id, s);

  const enriched = items.map((job: any) => ({
    ...job,
    service: job.service_id ? serviceById.get(job.service_id) ?? null : null,
  }));

  res.json({
    items: enriched,
    total,
    limit: parsed.data.limit,
    offset: parsed.data.offset,
  });
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
  const role = actorRole(req);
  const user_id = actorUserId(req);
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

  // Role rules:
  // - Technicians can update status via /status endpoint (not via generic patch).
  // - Sellers/admin can update assignment/priority/notes.
  if (body.status && !isAdminRole(role)) {
    throw new ApiError(403, 'Forbidden: status updates require technician/admin via /status');
  }
  if (body.assigned_tech_id !== undefined && isTechnicianRole(role) && !isAdminRole(role)) {
    throw new ApiError(403, 'Forbidden: technicians cannot reassign jobs');
  }

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
      last_update_by_user_id: user_id,
    },
  });

  res.json(updated);
}

export async function listJobHistory(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);
  const id = req.params.id;

  const job = await prisma.operationsJob.findFirst({
    where: { id, empresa_id, deleted_at: null },
    select: { id: true },
  });
  if (!job) throw new ApiError(404, 'Job not found');

  const items = await prisma.operationsJobHistory.findMany({
    where: { job_id: id },
    orderBy: { created_at: 'desc' },
    include: {
      created_by: { select: { id: true, nombre_completo: true } },
    },
    take: 200,
  });

  res.json({ items });
}

function mapSimpleStatusToJobStatus(params: {
  simple: 'PENDIENTE' | 'EN_PROCESO' | 'TERMINADO' | 'CANCELADO';
  crmTaskType: string | null;
  currentJobStatus: string;
}): string {
  const t = (params.crmTaskType ?? '').toUpperCase();

  if (params.simple === 'CANCELADO') return 'cancelled';

  if (params.simple === 'TERMINADO') {
    if (t === 'GARANTIA') return 'closed';
    return 'completed';
  }

  if (params.simple === 'EN_PROCESO') {
    if (t === 'LEVANTAMIENTO') return 'survey_in_progress';
    if (t === 'GARANTIA') return 'warranty_in_progress';
    return 'installation_in_progress';
  }

  // PENDIENTE
  if (t === 'LEVANTAMIENTO') return 'pending_survey';
  if (t === 'GARANTIA') return 'warranty_pending';
  if (t === 'SERVICIO_RESERVADO' || t === 'INSTALACION') return 'scheduled';
  // Fallback: keep current
  return params.currentJobStatus;
}

export async function patchJobStatus(req: Request, res: Response): Promise<void> {
  const empresa_id = actorEmpresaId(req);
  const role = actorRole(req);
  const user_id = actorUserId(req);
  const id = req.params.id;

  if (!isAdminRole(role) && !isTechnicianRole(role)) {
    throw new ApiError(403, 'Forbidden: only technicians/admin can update operational status');
  }

  const parsed = patchTaskStatusSchema.safeParse(req.body);
  if (!parsed.success) {
    throw new ApiError(400, 'Invalid payload', parsed.error.flatten());
  }

  const body = parsed.data;
  const technicianNotes =
    typeof body.technicianNotes !== 'undefined'
      ? body.technicianNotes
      : typeof body.technician_notes !== 'undefined'
        ? body.technician_notes
        : null;
  const cancelReason =
    typeof body.cancelReason !== 'undefined'
      ? body.cancelReason
      : typeof body.cancel_reason !== 'undefined'
        ? body.cancel_reason
        : null;

  if (body.status === 'TERMINADO' && (!technicianNotes || !technicianNotes.trim())) {
    throw new ApiError(400, 'technicianNotes is required for TERMINADO');
  }
  if (body.status === 'CANCELADO' && (!cancelReason || !cancelReason.trim())) {
    throw new ApiError(400, 'cancelReason is required for CANCELADO');
  }

  const existing = await prisma.operationsJob.findFirst({
    where: { id, empresa_id, deleted_at: null },
  });
  if (!existing) throw new ApiError(404, 'Job not found');

  const oldStatus = String(existing.status);
  const newStatus = mapSimpleStatusToJobStatus({
    simple: body.status,
    crmTaskType: (existing as any).crm_task_type ?? null,
    currentJobStatus: oldStatus,
  });

  const updated = await prisma.$transaction(async (tx) => {
    const job = await tx.operationsJob.update({
      where: { id },
      data: {
        status: newStatus as any,
        technician_notes:
          body.status === 'EN_PROCESO' || body.status === 'TERMINADO'
            ? (technicianNotes ?? undefined)
            : undefined,
        cancel_reason: body.status === 'CANCELADO' ? (cancelReason ?? undefined) : undefined,
        last_update_by_user_id: user_id,
      } as any,
    });

    await recordJobHistory({
      tx,
      jobId: job.id,
      actionType: 'status_update',
      oldStatus,
      newStatus: String(job.status),
      note:
        body.status === 'CANCELADO'
          ? `Cancelado: ${(cancelReason ?? '').trim()}`
          : (technicianNotes ?? null),
      createdByUserId: user_id,
    });

    // If warranty finished, resolve open ticket (best effort)
    if (newStatus === 'closed') {
      const ticket = await tx.operationsWarrantyTicket.findFirst({
        where: { job_id: job.id, status: { in: ['pending', 'in_progress'] as any } },
        orderBy: { reported_at: 'desc' },
      });
      if (ticket) {
        await tx.operationsWarrantyTicket.update({
          where: { id: ticket.id },
          data: {
            status: 'resolved',
            resolution_notes: (technicianNotes ?? '').trim() || undefined,
            resolved_at: new Date(),
          } as any,
        });
      }
    }

    return job;
  });

  // Sync back to CRM on terminal transitions (no loops: direct update + SSE)
  const chatId = (updated as any).crm_chat_id as string | null | undefined;
  if (chatId && (newStatus === 'completed' || newStatus === 'closed' || newStatus === 'cancelled')) {
    const crmStatus = newStatus === 'cancelled' ? 'cancelado' : 'servicio_finalizado';
    await prisma.crmChat.update({ where: { id: chatId }, data: { status: crmStatus } });

    const stamp = new Date().toISOString();
    const syncNote =
      newStatus === 'cancelled'
        ? `[OPS ${stamp}] Cancelado: ${(cancelReason ?? '').trim()}`
        : `[OPS ${stamp}] Terminado: ${(technicianNotes ?? '').trim()}`;
    await appendCrmInternalNote({ chatId, note: syncNote });
    emitCrmEvent({ type: 'chat.updated', chatId });
  }

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
        assigned_tech: body.assigned_tech_id
          ? { connect: { id: body.assigned_tech_id } }
          : undefined,
        additional_tech_ids: body.additional_tech_ids ?? [],
        customer_availability_notes: body.customer_availability_notes ?? null,
      },
      update: {
        scheduled_date,
        preferred_time: body.preferred_time ?? null,
        assigned_tech:
          body.assigned_tech_id === undefined
            ? undefined
            : body.assigned_tech_id
              ? { connect: { id: body.assigned_tech_id } }
              : { disconnect: true },
        additional_tech_ids: body.additional_tech_ids ?? [],
        customer_availability_notes: body.customer_availability_notes ?? null,
      },
    });

    await tx.operationsJob.update({
      where: { id: body.job_id },
      data: {
        status: 'scheduled',
        assigned_tech_id: body.assigned_tech_id ?? null,
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
