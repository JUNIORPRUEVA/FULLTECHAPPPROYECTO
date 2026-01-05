import { Request, Response } from 'express';
import { prisma } from '../../config/prisma';

/**
 * GET /api/my/payroll
 * Employee payroll history (paid)
 */
export async function myPayrollHistory(req: Request, res: Response) {
  try {
    const empresaId = req.user!.empresaId;
    const userId = req.user!.userId;

    const summaries = await prisma.payrollEmployeeSummary.findMany({
      where: {
        employee_user_id: userId,
        run: {
          empresa_id: empresaId,
          status: { in: ['PAID', 'CLOSED'] },
        },
      },
      include: {
        run: {
          include: { period: true },
        },
      },
      orderBy: { updated_at: 'desc' },
      take: 200,
    });

    const items = summaries.map((s) => ({
      runId: s.run_id,
      status: s.run.status,
      paid_at: s.run.paid_at,
      period: s.run.period,
      net_amount: s.net_amount,
      gross_amount: s.gross_amount,
      currency: s.currency,
    }));

    res.json({ items });
  } catch (error: any) {
    console.error('[PAYROLL] my history error:', error);
    res.status(500).json({ error: 'Error al cargar historial de nóminas' });
  }
}

/**
 * GET /api/my/payroll/:runId
 * Employee payroll detail (payslip snapshot)
 */
export async function myPayrollDetail(req: Request, res: Response) {
  try {
    const empresaId = req.user!.empresaId;
    const userId = req.user!.userId;
    const runId = req.params.runId;

    const run = await prisma.payrollRun.findFirst({
      where: {
        id: runId,
        empresa_id: empresaId,
        status: { in: ['PAID', 'CLOSED'] },
      },
      include: { period: true },
    });

    if (!run) return res.status(404).json({ error: 'Nómina no encontrada' });

    const payslip = await prisma.payrollPayslip.findFirst({
      where: {
        run_id: runId,
        employee_user_id: userId,
      },
    });

    if (!payslip) return res.status(403).json({ error: 'No autorizado para ver esta nómina' });

    res.json({ run: { id: run.id, status: run.status, paid_at: run.paid_at, period: run.period }, payslip });
  } catch (error: any) {
    console.error('[PAYROLL] my detail error:', error);
    res.status(500).json({ error: 'Error al cargar detalle de nómina' });
  }
}

/**
 * GET /api/my/payroll/notifications
 * Lightweight in-app notifications based on AuditLog entries.
 */
export async function myPayrollNotifications(req: Request, res: Response) {
  try {
    const empresaId = req.user!.empresaId;
    const userId = req.user!.userId;

    const logs = await prisma.auditLog.findMany({
      where: {
        empresa_id: empresaId,
        action: 'PAYROLL_EMPLOYEE_PAID_NOTIFY',
        meta: {
          path: ['employeeUserId'],
          equals: userId,
        },
      },
      orderBy: { created_at: 'desc' },
      take: 50,
    });

    const items = logs.map((l) => {
      const meta: any = l.meta;
      return {
        id: l.id,
        created_at: l.created_at,
        runId: meta?.runId ?? null,
        pdfUrl: meta?.pdfUrl ?? null,
        message: 'Tu nómina fue marcada como PAGADA',
      };
    });

    res.json({ items });
  } catch (error: any) {
    console.error('[PAYROLL] my notifications error:', error);
    res.status(500).json({ error: 'Error al cargar notificaciones de nómina' });
  }
}
