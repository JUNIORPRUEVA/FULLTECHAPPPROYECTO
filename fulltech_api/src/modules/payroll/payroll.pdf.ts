import fs from 'fs/promises';
import path from 'path';
import PDFDocument from 'pdfkit';
import type PDFKit from 'pdfkit';

import { env } from '../../config/env';

function sectionTitle(doc: PDFKit.PDFDocument, title: string) {
  doc.moveDown(0.8);
  doc.fontSize(12).font('Helvetica-Bold').text(title);
  doc.moveDown(0.4);
  doc.fontSize(10).font('Helvetica');
}

function kv(doc: PDFKit.PDFDocument, label: string, value: string) {
  doc.font('Helvetica-Bold').text(label + ': ', { continued: true });
  doc.font('Helvetica').text(value);
}

function formatMoney(amount: any) {
  const n = typeof amount === 'number' ? amount : Number(amount);
  const safe = isFinite(n) ? n : 0;
  return new Intl.NumberFormat('es-DO', { style: 'currency', currency: 'DOP' }).format(safe);
}

async function collectPdfBuffer(doc: PDFKit.PDFDocument): Promise<Buffer> {
  const chunks: Buffer[] = [];
  return new Promise((resolve, reject) => {
    doc.on('data', (c) => chunks.push(Buffer.isBuffer(c) ? c : Buffer.from(c)));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
  });
}

export async function buildPayrollPayslipPdf({
  company,
  employee,
  period,
  summary,
  lineItems,
}: {
  company: {
    nombre_empresa: string;
    rnc?: string | null;
    direccion?: string | null;
    telefono?: string | null;
    logo_url?: string | null;
  };
  employee: {
    nombre_completo: string;
    email: string;
    rol: string;
  };
  period: {
    year: number;
    month: number;
    half: 'FIRST' | 'SECOND';
    date_from: string;
    date_to: string;
  };
  summary: {
    base_salary_amount: any;
    commissions_amount: any;
    other_earnings_amount: any;
    gross_amount: any;
    statutory_deductions_amount: any;
    other_deductions_amount: any;
    net_amount: any;
    currency?: string;
  };
  lineItems: Array<{
    type: 'EARNING' | 'DEDUCTION';
    concept_code: string;
    concept_name: string;
    amount: any;
  }>;
}): Promise<Buffer> {
  const doc = new PDFDocument({ size: 'A4', margin: 48, compress: false });
  const bufferPromise = collectPdfBuffer(doc);

  doc.fontSize(16).font('Helvetica-Bold').text(company.nombre_empresa || 'Empresa');
  doc.moveDown(0.2);
  doc.fontSize(10).font('Helvetica').text('Recibo de Nómina (Quincenal)');

  sectionTitle(doc, 'Empleado');
  kv(doc, 'Nombre', employee.nombre_completo);
  kv(doc, 'Email', employee.email);
  kv(doc, 'Rol', employee.rol);

  sectionTitle(doc, 'Período');
  kv(doc, 'Año/Mes', `${period.year}-${String(period.month).padStart(2, '0')}`);
  kv(doc, 'Quincena', period.half === 'FIRST' ? '1–15' : '16–Fin');
  kv(doc, 'Desde', period.date_from);
  kv(doc, 'Hasta', period.date_to);

  sectionTitle(doc, 'Resumen');
  kv(doc, 'Sueldo base', formatMoney(summary.base_salary_amount));
  kv(doc, 'Comisiones', formatMoney(summary.commissions_amount));
  kv(doc, 'Otros ingresos', formatMoney(summary.other_earnings_amount));
  kv(doc, 'Bruto', formatMoney(summary.gross_amount));
  kv(doc, 'Deducciones legales', formatMoney(summary.statutory_deductions_amount));
  kv(doc, 'Otras deducciones', formatMoney(summary.other_deductions_amount));
  doc.moveDown(0.2);
  doc.font('Helvetica-Bold').fontSize(12).text(`Neto a pagar: ${formatMoney(summary.net_amount)}`);
  doc.font('Helvetica').fontSize(10);

  sectionTitle(doc, 'Detalle');
  for (const li of lineItems) {
    const sign = li.type === 'DEDUCTION' ? '-' : '+';
    doc.text(`${sign} ${li.concept_name} (${li.concept_code}): ${formatMoney(li.amount)}`);
  }

  doc.moveDown(1);
  doc.fontSize(9).fillColor('#666').text('Este recibo es un snapshot del cálculo al momento del pago.', { align: 'left' });
  doc.end();

  return bufferPromise;
}

export async function savePayslipPdfToUploads({
  runId,
  employeeUserId,
  pdf,
}: {
  runId: string;
  employeeUserId: string;
  pdf: Buffer;
}) {
  const uploadsRoot = path.resolve(process.cwd(), 'uploads');
  const relDir = path.join('payroll', 'payslips', runId);
  const dir = path.join(uploadsRoot, relDir);
  await fs.mkdir(dir, { recursive: true });

  const fileName = `${employeeUserId}.pdf`;
  const abs = path.join(dir, fileName);
  await fs.writeFile(abs, pdf);

  const rel = path.posix.join('payroll', 'payslips', runId, fileName).replace(/\\/g, '/');
  const base = env.PUBLIC_BASE_URL?.replace(/\/$/, '') ?? '';
  const url = base ? `${base}/uploads/${rel}` : `/uploads/${rel}`;
  return { absPath: abs, url };
}
