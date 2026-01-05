import { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import {
  createPayrollMovementSchema,
  createPayrollRunSchema,
  ensureCurrentPeriodsSchema,
  listPayrollMovementsQuerySchema,
  listPayrollRunsQuerySchema,
  updatePayrollMovementSchema,
} from './payroll.schema';
import { computeQuincenaRange, parseDateOnly, toMoney } from './payroll.utils';
import { logAudit } from './payroll.audit';
import { buildPayrollPayslipPdf, savePayslipPdfToUploads } from './payroll.pdf';

function isRunEditable(status: string) {
  return status === 'DRAFT' || status === 'REVIEW';
}

async function getActiveStatutoryConfig(empresaId: string, year: number) {
  return prisma.statutoryConfig.findFirst({
    where: {
      empresa_id: empresaId,
      year,
      active: true,
    },
    orderBy: { updated_at: 'desc' },
  });
}

function readRate(cfg: any, key: string): number {
  const raw = cfg?.[key];
  const n = typeof raw === 'number' ? raw : Number(raw);
  return isFinite(n) ? n : 0;
}

export async function ensureCurrentPeriods(req: Request, res: Response) {
  try {
    const body = ensureCurrentPeriodsSchema.parse(req.body ?? {});
    const empresaId = req.user!.empresaId;

    const now = new Date();
    const year = body.year ?? now.getUTCFullYear();
    const month = body.month ?? now.getUTCMonth() + 1;

    const halves: Array<'FIRST' | 'SECOND'> = ['FIRST', 'SECOND'];
    const created: any[] = [];

    for (const half of halves) {
      const { dateFrom, dateTo } = computeQuincenaRange(year, month, half);
      const period = await prisma.payrollPeriod.upsert({
        where: {
          payroll_period_company_year_month_half: {
            empresa_id: empresaId,
            year,
            month,
            half,
          },
        },
        update: {
          date_from: dateFrom,
          date_to: dateTo,
        },
        create: {
          empresa_id: empresaId,
          year,
          month,
          half,
          date_from: dateFrom,
          date_to: dateTo,
          status: 'OPEN',
        },
      });
      created.push(period);
    }

    await logAudit({
      empresaId,
      actorUserId: req.user!.userId,
      action: 'PAYROLL_PERIODS_ENSURE',
      entity: 'payroll_periods',
      entityId: `${year}-${month}`,
      meta: { year, month },
    });

    res.json({ year, month, periods: created });
  } catch (error: any) {
    console.error('[PAYROLL] ensure-current error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al asegurar períodos de nómina' });
  }
}

export async function createPayrollRun(req: Request, res: Response) {
  try {
    const body = createPayrollRunSchema.parse(req.body);
    const empresaId = req.user!.empresaId;
    const actorUserId = req.user!.userId;

    const period = body.periodId
      ? await prisma.payrollPeriod.findFirst({
          where: { id: body.periodId, empresa_id: empresaId },
        })
      : await prisma.payrollPeriod.findFirst({
          where: {
            empresa_id: empresaId,
            year: body.year!,
            month: body.month!,
            half: body.half!,
          },
        });

    if (!period) {
      return res.status(404).json({ error: 'Período no encontrado' });
    }

    const existing = await prisma.payrollRun.findFirst({
      where: { empresa_id: empresaId, period_id: period.id },
    });
    if (existing) {
      return res.status(409).json({ error: 'Ya existe una corrida para este período', runId: existing.id });
    }

    const employees = await prisma.usuario.findMany({
      where: {
        empresa_id: empresaId,
        estado: 'activo',
      },
      select: {
        id: true,
        nombre_completo: true,
        email: true,
        rol: true,
        salario_mensual: true,
        foto_perfil_url: true,
      },
      orderBy: { nombre_completo: 'asc' },
    });

    const run = await prisma.$transaction(async (tx) => {
      const createdRun = await tx.payrollRun.create({
        data: {
          empresa_id: empresaId,
          period_id: period.id,
          created_by_user_id: actorUserId,
          status: 'DRAFT',
          notes: body.notes,
        },
      });

      for (const e of employees) {
        const monthly = e.salario_mensual ? Number(e.salario_mensual) : 0;
        const base = monthly > 0 ? monthly / 2 : 0;
        const needsReview = monthly <= 0;

        await tx.payrollEmployeeSummary.create({
          data: {
            run_id: createdRun.id,
            employee_user_id: e.id,
            base_salary_amount: base,
            commissions_amount: 0,
            other_earnings_amount: 0,
            gross_amount: base,
            statutory_deductions_amount: 0,
            other_deductions_amount: 0,
            net_amount: base,
            currency: 'DOP',
            status: needsReview ? 'NEEDS_REVIEW' : 'READY',
          },
        });
      }

      return createdRun;
    });

    await logAudit({
      empresaId,
      actorUserId,
      action: 'PAYROLL_RUN_CREATE',
      entity: 'payroll_runs',
      entityId: run.id,
      meta: { periodId: period.id, employeeCount: employees.length },
    });

    res.status(201).json({ runId: run.id, period, employeeCount: employees.length });
  } catch (error: any) {
    console.error('[PAYROLL] create run error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al crear corrida de nómina' });
  }
}

export async function listPayrollRuns(req: Request, res: Response) {
  try {
    const query = listPayrollRunsQuerySchema.parse(req.query);
    const empresaId = req.user!.empresaId;

    const where: any = { empresa_id: empresaId };
    if (query.status) where.status = query.status;

    if (query.year || query.month || query.half) {
      where.period = {
        ...(query.year ? { year: query.year } : {}),
        ...(query.month ? { month: query.month } : {}),
        ...(query.half ? { half: query.half } : {}),
      };
    }

    const runs = await prisma.payrollRun.findMany({
      where,
      include: {
        period: true,
        employee_summaries: {
          select: {
            gross_amount: true,
            statutory_deductions_amount: true,
            other_deductions_amount: true,
            net_amount: true,
          },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    const items = runs.map((r) => {
      const totals = r.employee_summaries.reduce(
        (acc, s) => {
          acc.gross += toMoney(s.gross_amount);
          acc.deductions += toMoney(s.statutory_deductions_amount) + toMoney(s.other_deductions_amount);
          acc.net += toMoney(s.net_amount);
          return acc;
        },
        { gross: 0, deductions: 0, net: 0 },
      );

      return {
        id: r.id,
        status: r.status,
        notes: r.notes,
        paid_at: r.paid_at,
        created_at: r.created_at,
        updated_at: r.updated_at,
        period: r.period,
        totals,
        employeesCount: r.employee_summaries.length,
      };
    });

    res.json({ items });
  } catch (error: any) {
    console.error('[PAYROLL] list runs error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al listar corridas de nómina' });
  }
}

export async function getPayrollRun(req: Request, res: Response) {
  try {
    const empresaId = req.user!.empresaId;
    const runId = req.params.runId;

    const run = await prisma.payrollRun.findFirst({
      where: { id: runId, empresa_id: empresaId },
      include: {
        period: true,
        created_by: { select: { id: true, nombre_completo: true, email: true } },
        approved_by: { select: { id: true, nombre_completo: true, email: true } },
        paid_by: { select: { id: true, nombre_completo: true, email: true } },
        employee_summaries: {
          include: {
            employee: {
              select: {
                id: true,
                nombre_completo: true,
                email: true,
                rol: true,
                foto_perfil_url: true,
                salario_mensual: true,
              },
            },
            line_items: true,
          },
          orderBy: { updated_at: 'desc' },
        },
      },
    });

    if (!run) return res.status(404).json({ error: 'Corrida no encontrada' });

    const totals = run.employee_summaries.reduce(
      (acc, s) => {
        acc.gross += toMoney(s.gross_amount);
        acc.statutory += toMoney(s.statutory_deductions_amount);
        acc.otherDeductions += toMoney(s.other_deductions_amount);
        acc.net += toMoney(s.net_amount);
        acc.negativeNetCount += toMoney(s.net_amount) < 0 ? 1 : 0;
        acc.needsReviewCount += s.status === 'NEEDS_REVIEW' ? 1 : 0;
        return acc;
      },
      { gross: 0, statutory: 0, otherDeductions: 0, net: 0, negativeNetCount: 0, needsReviewCount: 0 },
    );

    res.json({ run, totals });
  } catch (error: any) {
    console.error('[PAYROLL] get run error:', error);
    res.status(500).json({ error: 'Error al obtener corrida de nómina' });
  }
}

export async function importMovements(req: Request, res: Response) {
  try {
    const empresaId = req.user!.empresaId;
    const runId = req.params.runId;

    const run = await prisma.payrollRun.findFirst({
      where: { id: runId, empresa_id: empresaId },
      include: { period: true },
    });

    if (!run) return res.status(404).json({ error: 'Corrida no encontrada' });
    if (!isRunEditable(run.status)) {
      return res.status(400).json({ error: 'La corrida no permite importar movimientos en este estado' });
    }

    const from = run.period.date_from;
    const to = run.period.date_to;

    const result = await prisma.payrollMovement.updateMany({
      where: {
        empresa_id: empresaId,
        status: 'PENDING',
        period_id: null,
        effective_date: {
          gte: from,
          lte: to,
        },
      },
      data: {
        period_id: run.period_id,
      },
    });

    await logAudit({
      empresaId,
      actorUserId: req.user!.userId,
      action: 'PAYROLL_RUN_IMPORT_MOVEMENTS',
      entity: 'payroll_runs',
      entityId: runId,
      meta: { assigned: result.count, periodId: run.period_id },
    });

    res.json({ assigned: result.count });
  } catch (error: any) {
    console.error('[PAYROLL] import movements error:', error);
    res.status(500).json({ error: 'Error al importar movimientos' });
  }
}

export async function recalculateRun(req: Request, res: Response) {
  try {
    const empresaId = req.user!.empresaId;
    const runId = req.params.runId;

    const run = await prisma.payrollRun.findFirst({
      where: { id: runId, empresa_id: empresaId },
      include: { period: true },
    });

    if (!run) return res.status(404).json({ error: 'Corrida no encontrada' });
    if (!isRunEditable(run.status)) {
      return res.status(400).json({ error: 'La corrida no permite recalcular en este estado' });
    }

    const statutory = await getActiveStatutoryConfig(empresaId, run.period.year);
    const cfg = statutory?.config ?? {};

    const tssSfsRate = readRate(cfg, 'tss_sfs_rate');
    const tssAfpRate = readRate(cfg, 'tss_afp_rate');
    const isrRate = readRate(cfg, 'isr_rate');

    const summaries = await prisma.payrollEmployeeSummary.findMany({
      where: { run_id: runId },
      include: { employee: { select: { id: true, salario_mensual: true } } },
    });

    await prisma.$transaction(async (tx) => {
      for (const s of summaries) {
        const movements = await tx.payrollMovement.findMany({
          where: {
            empresa_id: empresaId,
            employee_user_id: s.employee_user_id,
            period_id: run.period_id,
            status: 'PENDING',
          },
          orderBy: { created_at: 'asc' },
        });

        const commissions = movements
          .filter((m) => m.source === 'SALES_COMMISSION' && m.movement_type === 'EARNING')
          .reduce((acc, m) => acc + toMoney(m.amount), 0);

        const otherEarnings = movements
          .filter((m) => !(m.source === 'SALES_COMMISSION' && m.movement_type === 'EARNING') && m.movement_type === 'EARNING')
          .reduce((acc, m) => acc + toMoney(m.amount), 0);

        const otherDeductions = movements
          .filter((m) => m.movement_type === 'DEDUCTION')
          .reduce((acc, m) => acc + toMoney(m.amount), 0);

        // Keep base salary from summary (created from salario_mensual/2), but if salary changes later, admin can recalc manually in future.
        const base = toMoney(s.base_salary_amount);
        const gross = toMoney(base + commissions + otherEarnings);

        const tssSfs = toMoney(gross * tssSfsRate);
        const tssAfp = toMoney(gross * tssAfpRate);
        const isr = toMoney(gross * isrRate);
        const statutoryTotal = toMoney(tssSfs + tssAfp + isr);

        const net = toMoney(gross - statutoryTotal - otherDeductions);
        const needsReview = net < 0 || s.status === 'NEEDS_REVIEW';

        await tx.payrollEmployeeSummary.update({
          where: { id: s.id },
          data: {
            commissions_amount: commissions,
            other_earnings_amount: otherEarnings,
            gross_amount: gross,
            statutory_deductions_amount: statutoryTotal,
            other_deductions_amount: otherDeductions,
            net_amount: net,
            status: needsReview ? 'NEEDS_REVIEW' : 'READY',
          },
        });

        // regenerate line items (idempotent)
        await tx.payrollLineItem.deleteMany({ where: { employee_summary_id: s.id } });

        const lineItems: any[] = [];
        if (base > 0) lineItems.push({ type: 'EARNING', concept_code: 'BASE_SALARY', concept_name: 'Sueldo base', amount: base });
        if (commissions > 0) lineItems.push({ type: 'EARNING', concept_code: 'COMMISSION', concept_name: 'Comisiones', amount: commissions });
        if (otherEarnings > 0) lineItems.push({ type: 'EARNING', concept_code: 'OTHER', concept_name: 'Otros ingresos', amount: otherEarnings });

        if (tssSfsRate > 0 && tssSfs > 0) {
          lineItems.push({ type: 'DEDUCTION', concept_code: 'TSS_SFS', concept_name: 'TSS SFS', amount: tssSfs });
        }
        if (tssAfpRate > 0 && tssAfp > 0) {
          lineItems.push({ type: 'DEDUCTION', concept_code: 'TSS_AFP', concept_name: 'TSS AFP', amount: tssAfp });
        }
        if (isrRate > 0 && isr > 0) {
          lineItems.push({ type: 'DEDUCTION', concept_code: 'ISR', concept_name: 'ISR', amount: isr });
        }

        for (const m of movements) {
          const code = m.concept_code;
          const name = m.concept_name;
          lineItems.push({
            type: m.movement_type,
            concept_code: code,
            concept_name: name,
            amount: toMoney(m.amount),
            meta: { movementId: m.id, source: m.source },
          });
        }

        if (lineItems.length) {
          await tx.payrollLineItem.createMany({
            data: lineItems.map((li) => ({
              employee_summary_id: s.id,
              type: li.type,
              concept_code: li.concept_code,
              concept_name: li.concept_name,
              amount: li.amount,
              meta: li.meta,
            })),
          });
        }
      }

      // move run to REVIEW after recalculation (optional state step)
      await tx.payrollRun.update({ where: { id: runId }, data: { status: 'REVIEW' } });
    });

    await logAudit({
      empresaId,
      actorUserId: req.user!.userId,
      action: 'PAYROLL_RUN_RECALCULATE',
      entity: 'payroll_runs',
      entityId: runId,
      meta: { statutoryConfigId: statutory?.id ?? null },
    });

    res.json({ ok: true });
  } catch (error: any) {
    console.error('[PAYROLL] recalc error:', error);
    res.status(500).json({ error: 'Error al recalcular nómina' });
  }
}

export async function approveRun(req: Request, res: Response) {
  try {
    const empresaId = req.user!.empresaId;
    const actorUserId = req.user!.userId;
    const runId = req.params.runId;

    const run = await prisma.payrollRun.findFirst({
      where: { id: runId, empresa_id: empresaId },
      include: { period: true },
    });

    if (!run) return res.status(404).json({ error: 'Corrida no encontrada' });
    if (!(run.status === 'DRAFT' || run.status === 'REVIEW')) {
      return res.status(400).json({ error: 'Solo se puede aprobar en DRAFT/REVIEW' });
    }

    const company = await prisma.companySettings.findUnique({
      where: { empresa_id: empresaId },
    });

    const summaries = await prisma.payrollEmployeeSummary.findMany({
      where: { run_id: runId },
      include: {
        employee: { select: { id: true, nombre_completo: true, email: true, rol: true } },
        line_items: true,
      },
    });

    await prisma.$transaction(async (tx) => {
      await tx.payrollRun.update({
        where: { id: runId },
        data: { status: 'APPROVED', approved_by_user_id: actorUserId },
      });

      await tx.payrollEmployeeSummary.updateMany({
        where: { run_id: runId },
        data: { status: 'LOCKED' },
      });

      await tx.payrollMovement.updateMany({
        where: { empresa_id: empresaId, period_id: run.period_id, status: 'PENDING' },
        data: { status: 'APPLIED', approved_by_user_id: actorUserId },
      });

      for (const s of summaries) {
        await tx.payrollPayslip.upsert({
          where: {
            payroll_payslip_run_employee: {
              run_id: runId,
              employee_user_id: s.employee_user_id,
            },
          },
          update: {
            snapshot: {
              company: {
                nombre_empresa: company?.nombre_empresa ?? 'Empresa',
                rnc: company?.rnc ?? null,
                direccion: company?.direccion ?? null,
                telefono: company?.telefono ?? null,
                logo_url: company?.logo_url ?? null,
              },
              employee: s.employee,
              period: {
                year: run.period.year,
                month: run.period.month,
                half: run.period.half,
                date_from: run.period.date_from,
                date_to: run.period.date_to,
              },
              summary: {
                base_salary_amount: s.base_salary_amount,
                commissions_amount: s.commissions_amount,
                other_earnings_amount: s.other_earnings_amount,
                gross_amount: s.gross_amount,
                statutory_deductions_amount: s.statutory_deductions_amount,
                other_deductions_amount: s.other_deductions_amount,
                net_amount: s.net_amount,
                currency: s.currency,
              },
              line_items: s.line_items,
              created_at: new Date().toISOString(),
            },
          },
          create: {
            run_id: runId,
            employee_user_id: s.employee_user_id,
            snapshot: {
              company: {
                nombre_empresa: company?.nombre_empresa ?? 'Empresa',
                rnc: company?.rnc ?? null,
                direccion: company?.direccion ?? null,
                telefono: company?.telefono ?? null,
                logo_url: company?.logo_url ?? null,
              },
              employee: s.employee,
              period: {
                year: run.period.year,
                month: run.period.month,
                half: run.period.half,
                date_from: run.period.date_from,
                date_to: run.period.date_to,
              },
              summary: {
                base_salary_amount: s.base_salary_amount,
                commissions_amount: s.commissions_amount,
                other_earnings_amount: s.other_earnings_amount,
                gross_amount: s.gross_amount,
                statutory_deductions_amount: s.statutory_deductions_amount,
                other_deductions_amount: s.other_deductions_amount,
                net_amount: s.net_amount,
                currency: s.currency,
              },
              line_items: s.line_items,
              created_at: new Date().toISOString(),
            },
          },
        });
      }
    });

    await logAudit({
      empresaId,
      actorUserId,
      action: 'PAYROLL_RUN_APPROVE',
      entity: 'payroll_runs',
      entityId: runId,
      meta: { employeeCount: summaries.length },
    });

    res.json({ ok: true });
  } catch (error: any) {
    console.error('[PAYROLL] approve error:', error);
    res.status(500).json({ error: 'Error al aprobar nómina' });
  }
}

export async function markPaid(req: Request, res: Response) {
  try {
    const empresaId = req.user!.empresaId;
    const actorUserId = req.user!.userId;
    const runId = req.params.runId;

    const run = await prisma.payrollRun.findFirst({
      where: { id: runId, empresa_id: empresaId },
      include: { period: true },
    });

    if (!run) return res.status(404).json({ error: 'Corrida no encontrada' });
    if (run.status !== 'APPROVED') {
      return res.status(400).json({ error: 'Solo se puede marcar pagada desde APPROVED' });
    }

    const company = await prisma.companySettings.findUnique({
      where: { empresa_id: empresaId },
    });

    const payslips = await prisma.payrollPayslip.findMany({
      where: { run_id: runId },
    });

    await prisma.payrollRun.update({
      where: { id: runId },
      data: { status: 'PAID', paid_at: new Date(), paid_by_user_id: actorUserId },
    });

    for (const p of payslips) {
      const snap: any = p.snapshot;

      const pdf = await buildPayrollPayslipPdf({
        company: snap.company,
        employee: snap.employee,
        period: {
          year: snap.period.year,
          month: snap.period.month,
          half: snap.period.half,
          date_from: String(snap.period.date_from).slice(0, 10),
          date_to: String(snap.period.date_to).slice(0, 10),
        },
        summary: snap.summary,
        lineItems: (snap.line_items || []).map((li: any) => ({
          type: li.type,
          concept_code: li.concept_code,
          concept_name: li.concept_name,
          amount: li.amount,
        })),
      });

      const saved = await savePayslipPdfToUploads({ runId, employeeUserId: p.employee_user_id, pdf });

      await prisma.payrollPayslip.update({
        where: { id: p.id },
        data: { pdf_url: saved.url },
      });

      await logAudit({
        empresaId,
        actorUserId,
        action: 'PAYROLL_EMPLOYEE_PAID_NOTIFY',
        entity: 'payroll_payslips',
        entityId: p.id,
        meta: { runId, employeeUserId: p.employee_user_id, pdfUrl: saved.url },
      });
    }

    await logAudit({
      empresaId,
      actorUserId,
      action: 'PAYROLL_RUN_MARK_PAID',
      entity: 'payroll_runs',
      entityId: runId,
      meta: { payslips: payslips.length },
    });

    res.json({ ok: true, payslips: payslips.length });
  } catch (error: any) {
    console.error('[PAYROLL] mark-paid error:', error);
    res.status(500).json({ error: 'Error al marcar nómina como pagada' });
  }
}

// Movements CRUD (ADMIN)
export async function createMovement(req: Request, res: Response) {
  try {
    const body = createPayrollMovementSchema.parse(req.body);
    const empresaId = req.user!.empresaId;
    const actorUserId = req.user!.userId;

    const movement = await prisma.payrollMovement.create({
      data: {
        empresa_id: empresaId,
        employee_user_id: body.employee_user_id,
        movement_type: body.movement_type,
        source: body.source,
        concept_code: body.concept_code,
        concept_name: body.concept_name,
        amount: body.amount,
        effective_date: parseDateOnly(body.effective_date),
        status: 'PENDING',
        created_by_user_id: actorUserId,
        note: body.note,
      },
    });

    await logAudit({
      empresaId,
      actorUserId,
      action: 'PAYROLL_MOVEMENT_CREATE',
      entity: 'payroll_movements',
      entityId: movement.id,
      meta: { employeeUserId: body.employee_user_id, source: body.source, amount: body.amount },
    });

    res.status(201).json(movement);
  } catch (error: any) {
    console.error('[PAYROLL] create movement error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al crear movimiento' });
  }
}

export async function listMovements(req: Request, res: Response) {
  try {
    const query = listPayrollMovementsQuerySchema.parse(req.query);
    const empresaId = req.user!.empresaId;

    const where: any = { empresa_id: empresaId };
    if (query.employeeId) where.employee_user_id = query.employeeId;
    if (query.status) where.status = query.status;
    if (query.from || query.to) {
      where.effective_date = {
        ...(query.from ? { gte: parseDateOnly(query.from) } : {}),
        ...(query.to ? { lte: parseDateOnly(query.to) } : {}),
      };
    }

    const items = await prisma.payrollMovement.findMany({
      where,
      include: {
        employee: { select: { id: true, nombre_completo: true, email: true, rol: true } },
      },
      orderBy: { effective_date: 'desc' },
      take: 500,
    });

    res.json({ items });
  } catch (error: any) {
    console.error('[PAYROLL] list movements error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al listar movimientos' });
  }
}

export async function updateMovement(req: Request, res: Response) {
  try {
    const id = req.params.id;
    const patch = updatePayrollMovementSchema.parse(req.body);
    const empresaId = req.user!.empresaId;
    const actorUserId = req.user!.userId;

    const existing = await prisma.payrollMovement.findFirst({
      where: { id, empresa_id: empresaId },
    });

    if (!existing) return res.status(404).json({ error: 'Movimiento no encontrado' });
    if (existing.status !== 'PENDING' || existing.period_id != null) {
      return res.status(400).json({ error: 'Solo se puede editar si está PENDING y no asignado a período' });
    }

    const updated = await prisma.payrollMovement.update({
      where: { id },
      data: {
        ...(patch.movement_type ? { movement_type: patch.movement_type } : {}),
        ...(patch.source ? { source: patch.source } : {}),
        ...(patch.concept_code ? { concept_code: patch.concept_code } : {}),
        ...(patch.concept_name ? { concept_name: patch.concept_name } : {}),
        ...(patch.amount != null ? { amount: patch.amount } : {}),
        ...(patch.effective_date ? { effective_date: parseDateOnly(patch.effective_date) } : {}),
        ...(patch.note !== undefined ? { note: patch.note ?? null } : {}),
      },
    });

    await logAudit({
      empresaId,
      actorUserId,
      action: 'PAYROLL_MOVEMENT_UPDATE',
      entity: 'payroll_movements',
      entityId: id,
      meta: { patch },
    });

    res.json(updated);
  } catch (error: any) {
    console.error('[PAYROLL] update movement error:', error);
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: 'Datos inválidos', details: error.errors });
    }
    res.status(500).json({ error: 'Error al actualizar movimiento' });
  }
}

export async function voidMovement(req: Request, res: Response) {
  try {
    const id = req.params.id;
    const empresaId = req.user!.empresaId;
    const actorUserId = req.user!.userId;

    const existing = await prisma.payrollMovement.findFirst({
      where: { id, empresa_id: empresaId },
    });

    if (!existing) return res.status(404).json({ error: 'Movimiento no encontrado' });
    if (existing.status !== 'PENDING') {
      return res.status(400).json({ error: 'Solo se puede anular si está PENDING' });
    }

    const updated = await prisma.payrollMovement.update({
      where: { id },
      data: { status: 'VOIDED' },
    });

    await logAudit({
      empresaId,
      actorUserId,
      action: 'PAYROLL_MOVEMENT_VOID',
      entity: 'payroll_movements',
      entityId: id,
      meta: { previousStatus: existing.status },
    });

    res.json(updated);
  } catch (error: any) {
    console.error('[PAYROLL] void movement error:', error);
    res.status(500).json({ error: 'Error al anular movimiento' });
  }
}
