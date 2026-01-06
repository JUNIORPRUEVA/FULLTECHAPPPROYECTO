import { Request, Response } from 'express';

import { prisma } from '../../../config/prisma';

export async function getPrinterSettings(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const userId = req.user!.userId;

  const rows = await prisma.$queryRaw<
    Array<{
      strategy: string;
      printer_name: string | null;
      paper_width_mm: number;
      copies: number;
    }>
  >`
    SELECT strategy, printer_name, paper_width_mm, copies
    FROM printer_settings
    WHERE empresa_id = ${empresaId}::uuid
      AND user_id = ${userId}::uuid
    LIMIT 1;
  `;

  const item =
    rows[0] ??
    ({
      strategy: 'PDF_FALLBACK',
      printer_name: null,
      paper_width_mm: 80,
      copies: 1,
    } as const);

  res.json({ item });
}

export async function updatePrinterSettings(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const userId = req.user!.userId;

  const body = req.body as {
    strategy?: 'PDF_FALLBACK' | 'RAW_ESCPOS' | 'WINDOWS_PRINTER';
    printerName?: string | null;
    paperWidthMm?: number;
    copies?: number;
  };

  const strategy = body.strategy ?? 'PDF_FALLBACK';
  const printerName =
    body.printerName === undefined ? null : (body.printerName ?? null);
  const paperWidthMm =
    typeof body.paperWidthMm === 'number' ? body.paperWidthMm : 80;
  const copies = typeof body.copies === 'number' ? body.copies : 1;

  await prisma.$executeRaw`
    INSERT INTO printer_settings(empresa_id, user_id, strategy, printer_name, paper_width_mm, copies)
    VALUES (${empresaId}::uuid, ${userId}::uuid, ${strategy}::text, ${printerName}::text, ${paperWidthMm}::int, ${copies}::int)
    ON CONFLICT (empresa_id, user_id)
    DO UPDATE SET
      strategy = EXCLUDED.strategy,
      printer_name = EXCLUDED.printer_name,
      paper_width_mm = EXCLUDED.paper_width_mm,
      copies = EXCLUDED.copies,
      updated_at = now();
  `;

  res.json({ ok: true });
}
