import fs from 'fs';
import path from 'path';
import axios from 'axios';
import PDFDocument from 'pdfkit';

import { env } from '../../config/env';

export type CartaCompanyPdf = {
  nombre: string;
  rnc?: string | null;
  telefono?: string | null;
  direccion?: string | null;
  email?: string | null;
  sitio_web?: string | null;
  instagram_url?: string | null;
  facebook_url?: string | null;
  logo_url?: string | null;
};

export type CartaAiPdf = {
  greeting: string;
  bodyParagraphs: string[];
  closing: string;
  signatureSuggestion: string;
};

export type CartaQuotationSummary = {
  numero?: string | null;
  total?: number | null;
  items?: Array<{ nombre: string; cantidad: number; unit_price: number; line_total: number }>;
};

export type CartaPdfInput = {
  company: CartaCompanyPdf;
  dateLabel: string;
  letterTypeLabel: string;
  subject: string;
  customerName: string;
  customerPhone?: string | null;
  ai: CartaAiPdf;
  quotation?: CartaQuotationSummary | null;
};

const accent = '#B91C1C'; // match cotización PDF accent (red-700-ish)
const textMuted = '#475569';
const textStrong = '#0F172A';
const cardBorder = '#E2E8F0';
const cardBg = '#F8FAFC';
const pageBorder = '#CBD5E1';

function fmtMoneyRd(v: number): string {
  try {
    return new Intl.NumberFormat('es-DO', {
      style: 'currency',
      currency: 'DOP',
      currencyDisplay: 'symbol',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(v);
  } catch {
    return `RD$ ${v.toFixed(2)}`;
  }
}

async function maybeLoadLogoBuffer(logoUrl: string | null | undefined): Promise<Buffer | null> {
  const raw = String(logoUrl ?? '').trim();
  if (!raw) return null;

  try {
    if (raw.startsWith('/uploads/')) {
      const uploadsRoot = path.resolve(process.cwd(), env.UPLOADS_DIR || 'uploads');
      const abs = path.join(uploadsRoot, raw.replace(/^\/uploads\//, ''));
      if (fs.existsSync(abs)) return fs.readFileSync(abs);
      return null;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      const res = await axios.get(raw, { responseType: 'arraybuffer', timeout: 4500 });
      return Buffer.from(res.data);
    }

    return null;
  } catch {
    return null;
  }
}

function card(doc: PDFKit.PDFDocument, x: number, y: number, w: number, h: number) {
  doc.save();
  doc.roundedRect(x, y, w, h, 10).fillAndStroke(cardBg, cardBorder);
  doc.restore();
}

function kv(doc: PDFKit.PDFDocument, x: number, y: number, label: string, value: string) {
  doc.fillColor(textMuted).fontSize(9).font('Helvetica-Bold').text(label, x, y, { width: 90 });
  doc.fillColor(textStrong).fontSize(9).font('Helvetica').text(value, x + 92, y, { width: 360 });
}

export async function buildCartaPdfBuffer(input: CartaPdfInput): Promise<Buffer> {
  const doc = new PDFDocument({ size: 'A4', margin: 28, autoFirstPage: true });

  const chunks: Buffer[] = [];
  doc.on('data', (c) => chunks.push(c));

  const pageW = doc.page.width;
  const pageH = doc.page.height;

  // Page border
  doc.save();
  doc
    .lineWidth(1.6)
    .strokeColor(pageBorder)
    .roundedRect(16, 16, pageW - 32, pageH - 32, 14)
    .stroke();
  doc.restore();

  const logo = await maybeLoadLogoBuffer(input.company.logo_url);

  // Header
  const headerY = 28;
  const headerX = 28;

  if (logo) {
    try {
      doc.save();
      doc.roundedRect(headerX, headerY, 54, 54, 10).strokeColor(accent).lineWidth(2).stroke();
      doc.image(logo, headerX + 6, headerY + 6, { fit: [42, 42] });
      doc.restore();
    } catch {
      // ignore logo errors
    }
  }

  const companyName = String(input.company.nombre || 'FULLTECH').trim();
  const companyX = logo ? headerX + 66 : headerX;

  doc.fillColor(textStrong).font('Helvetica-Bold').fontSize(18).text(companyName, companyX, headerY + 2, {
    width: pageW - companyX - 28,
  });

  const details: string[] = [];
  if (input.company.rnc) details.push(`RNC: ${input.company.rnc}`);
  if (input.company.telefono) details.push(`Tel: ${input.company.telefono}`);
  if (input.company.email) details.push(String(input.company.email));
  if (input.company.direccion) details.push(String(input.company.direccion));

  doc.fillColor(textMuted).font('Helvetica').fontSize(9).text(details.join('  •  '), companyX, headerY + 28, {
    width: pageW - companyX - 28,
  });

  // Accent line
  doc.save();
  doc.strokeColor(accent).lineWidth(2).moveTo(28, headerY + 66).lineTo(pageW - 28, headerY + 66).stroke();
  doc.restore();

  let y = headerY + 78;

  // Meta card
  card(doc, 28, y, pageW - 56, 74);
  kv(doc, 44, y + 14, 'Fecha', input.dateLabel);
  kv(doc, 44, y + 30, 'Tipo', input.letterTypeLabel);
  kv(doc, 44, y + 46, 'Asunto', input.subject);

  y += 86;

  // Recipient card
  card(doc, 28, y, pageW - 56, 54);
  doc.fillColor(textStrong).font('Helvetica-Bold').fontSize(10).text('Destinatario', 44, y + 12);
  doc.fillColor(textStrong).font('Helvetica').fontSize(10).text(input.customerName, 44, y + 28);
  if (input.customerPhone) {
    doc.fillColor(textMuted).fontSize(9).text(String(input.customerPhone), 44, y + 42);
  }

  y += 70;

  // Body
  const bodyX = 44;
  const bodyW = pageW - 88;

  doc.fillColor(textStrong).font('Helvetica').fontSize(11);

  doc.text(input.ai.greeting.trim(), bodyX, y, { width: bodyW, align: 'left' });
  y = doc.y + 10;

  for (const p of input.ai.bodyParagraphs) {
    doc.text(String(p).trim(), bodyX, y, { width: bodyW, align: 'justify' });
    y = doc.y + 10;
  }

  doc.text(input.ai.closing.trim(), bodyX, y + 4, { width: bodyW, align: 'left' });
  y = doc.y + 8;
  doc.fillColor(textStrong).font('Helvetica-Bold').text(input.ai.signatureSuggestion.trim(), bodyX, y, {
    width: bodyW,
    align: 'left',
  });

  y = doc.y + 16;

  // Quotation summary (optional)
  if (input.quotation && (input.quotation.items?.length ?? 0) > 0) {
    const items = input.quotation.items ?? [];

    const cardH = Math.min(260, 74 + items.length * 16);
    if (y + cardH > pageH - 110) {
      doc.addPage();
      y = 44;
    }

    card(doc, 28, y, pageW - 56, cardH);
    doc.fillColor(textStrong).font('Helvetica-Bold').fontSize(10).text('Resumen de Cotización', 44, y + 12);

    const headerY2 = y + 30;
    doc.fillColor(textMuted).font('Helvetica-Bold').fontSize(8);
    doc.text('Item', 44, headerY2, { width: 250 });
    doc.text('Cant.', 300, headerY2, { width: 50, align: 'right' });
    doc.text('Precio', 354, headerY2, { width: 80, align: 'right' });
    doc.text('Total', 440, headerY2, { width: 80, align: 'right' });

    doc.save();
    doc.strokeColor(cardBorder).lineWidth(1).moveTo(44, headerY2 + 12).lineTo(pageW - 44, headerY2 + 12).stroke();
    doc.restore();

    let rowY = headerY2 + 18;
    doc.font('Helvetica').fillColor(textStrong).fontSize(8.6);

    for (const it of items.slice(0, 10)) {
      doc.text(it.nombre, 44, rowY, { width: 250 });
      doc.text(String(it.cantidad), 300, rowY, { width: 50, align: 'right' });
      doc.text(fmtMoneyRd(it.unit_price), 354, rowY, { width: 80, align: 'right' });
      doc.text(fmtMoneyRd(it.line_total), 440, rowY, { width: 80, align: 'right' });
      rowY += 14;
    }

    if (typeof input.quotation.total === 'number') {
      doc.save();
      doc.strokeColor(accent).lineWidth(1.5).moveTo(44, rowY + 6).lineTo(pageW - 44, rowY + 6).stroke();
      doc.restore();
      doc.font('Helvetica-Bold').fontSize(10).fillColor(textStrong);
      doc.text('TOTAL', 354, rowY + 10, { width: 80, align: 'right' });
      doc.text(fmtMoneyRd(input.quotation.total), 440, rowY + 10, { width: 80, align: 'right' });
    }

    y += cardH + 10;
  }

  // Footer socials
  const footerParts: string[] = [];
  if (input.company.sitio_web) footerParts.push(String(input.company.sitio_web));
  if (input.company.instagram_url) footerParts.push(`Instagram: ${input.company.instagram_url}`);
  if (input.company.facebook_url) footerParts.push(`Facebook: ${input.company.facebook_url}`);

  const footerText = footerParts.length > 0 ? footerParts.join('  •  ') : 'Sitio web • Instagram • Facebook';

  doc.fillColor(textMuted).font('Helvetica').fontSize(8);
  doc.text(footerText, 28, pageH - 46, { width: pageW - 56, align: 'center' });

  await new Promise<void>((resolve, reject) => {
    doc.on('end', () => resolve());
    doc.on('error', reject);
    doc.end();
  });

  return Buffer.concat(chunks);
}
