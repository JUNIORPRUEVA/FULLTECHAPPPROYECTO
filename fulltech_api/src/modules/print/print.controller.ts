import { Request, Response } from 'express';
import fs from 'fs/promises';
import os from 'os';
import path from 'path';
import { spawn } from 'child_process';

import { prisma } from '../../config/prisma';

function run(cmd: string, args: string[]): Promise<{ code: number }> {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { windowsHide: true });
    p.on('error', reject);
    p.on('close', (code) => resolve({ code: code ?? 0 }));
  });
}

async function writeTempFile(ext: string, bytes: Buffer): Promise<string> {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'fulltech-print-'));
  const filePath = path.join(dir, `job.${ext}`);
  await fs.writeFile(filePath, bytes);
  return filePath;
}

// Minimal placeholder PDF generation: reuses existing quotation pdf tooling client-side.
// For invoices/tickets we currently return a JSON hint.
export async function printTest(req: Request, res: Response) {
  res.json({ ok: true, message: 'Print service reachable' });
}

export async function printInvoice(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const userId = req.user!.userId;
  const { saleId } = req.params;

  // Load settings
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

  const cfg =
    rows[0] ??
    ({
      strategy: 'PDF_FALLBACK',
      printer_name: null,
      paper_width_mm: 80,
      copies: 1,
    } as const);

  // NOTE: The system currently does not have a backend invoice PDF generator.
  // We return a clear error until a server-side template is defined.
  // This keeps the endpoint stable for the Flutter side.
  const saleExists = await prisma.sale.findFirst({
    where: { id: saleId, empresa_id: empresaId },
    select: { id: true },
  });
  if (!saleExists) return res.status(404).json({ error: 'not_found' });

  if (cfg.strategy === 'PDF_FALLBACK') {
    return res.status(501).json({
      error: 'not_implemented',
      message:
        'Server-side invoice PDF not implemented yet; use client PDF preview/printing.',
    });
  }

  return res.status(501).json({
    error: 'not_implemented',
    message: `Printing strategy ${cfg.strategy} is not implemented for invoices yet.`,
  });
}

// Utility endpoint for printing an arbitrary PDF sent by client.
export async function printPdf(req: Request, res: Response) {
  const empresaId = req.user!.empresaId;
  const userId = req.user!.userId;

  const bytes = req.body as any;
  if (!Buffer.isBuffer(bytes)) {
    return res.status(400).json({ error: 'expected_pdf_bytes' });
  }

  const settingsRows = await prisma.$queryRaw<
    Array<{ strategy: string; printer_name: string | null; copies: number }>
  >`
    SELECT strategy, printer_name, copies
    FROM printer_settings
    WHERE empresa_id = ${empresaId}::uuid
      AND user_id = ${userId}::uuid
    LIMIT 1;
  `;

  const cfg =
    settingsRows[0] ??
    ({ strategy: 'PDF_FALLBACK', printer_name: null, copies: 1 } as const);

  const filePath = await writeTempFile('pdf', bytes);

  if (cfg.strategy === 'WINDOWS_PRINTER') {
    // Best-effort Windows printing (uses default printer).
    // Printer selection is OS-dependent; we rely on default or user-set default.
    // This is intentionally conservative (no extra native deps).
    const r = await run('powershell', [
      '-NoProfile',
      '-Command',
      `Start-Process -FilePath \"${filePath}\" -Verb Print`,
    ]);

    if (r.code !== 0) {
      return res.status(500).json({ error: 'print_failed', code: r.code });
    }

    return res.json({ ok: true });
  }

  if (cfg.strategy === 'RAW_ESCPOS') {
    if (!cfg.printer_name || cfg.printer_name.trim().length === 0) {
      return res.status(400).json({ error: 'missing_printer_name' });
    }

    // RAW send to a printer share/port (e.g. \\localhost\EPSON or LPT1)
    const dest = cfg.printer_name.trim();
    const r = await run('cmd', ['/c', 'copy', '/b', filePath, dest]);
    if (r.code !== 0) {
      return res.status(500).json({ error: 'raw_print_failed', code: r.code });
    }

    return res.json({ ok: true });
  }

  // PDF_FALLBACK: just return the PDF so the client can preview/print
  res.setHeader('Content-Type', 'application/pdf');
  res.send(bytes);
}
