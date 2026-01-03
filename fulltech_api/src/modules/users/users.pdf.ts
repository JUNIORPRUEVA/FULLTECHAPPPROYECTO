import PDFDocument from 'pdfkit';
import type PDFKit from 'pdfkit';

export type CompanySettingsPdf = {
  nombre_empresa: string;
  rnc: string;
  telefono: string;
  direccion: string;
};

export type UserForPdf = {
  nombre_completo: string;
  email: string;
  rol: string;
  posicion: string | null;
  telefono: string | null;
  direccion: string | null;
  ubicacion_mapa: string | null;
  fecha_nacimiento: Date | null;
  edad: number | null;
  lugar_nacimiento: string | null;
  cedula_numero: string | null;
  tiene_casa_propia: boolean;
  tiene_vehiculo: boolean;
  tipo_vehiculo: string | null;
  es_casado: boolean;
  cantidad_hijos: number;
  ultimo_trabajo: string | null;
  motivo_salida_ultimo_trabajo: string | null;
  fecha_ingreso_empresa: Date | null;
  salario_mensual: string | number | null;
  beneficios: string | null;
  es_tecnico_con_licencia: boolean;
  numero_licencia_tecnica: string | null;
  licencia_conducir_numero: string | null;
  licencia_conducir_fecha_vencimiento: Date | null;
};

function fmtDate(d: Date | null | undefined): string {
  if (!d) return '—';
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function sectionTitle(doc: PDFKit.PDFDocument, title: string) {
  doc.moveDown(0.6);
  doc.fontSize(12).fillColor('#0B1B2B').font('Helvetica-Bold').text(title);
  doc.moveDown(0.2);
  doc.moveTo(doc.page.margins.left, doc.y)
    .lineTo(doc.page.width - doc.page.margins.right, doc.y)
    .lineWidth(1)
    .strokeColor('#D6DEE8')
    .stroke();
  doc.moveDown(0.5);
}

function kv(doc: PDFKit.PDFDocument, label: string, value: string) {
  doc.font('Helvetica-Bold').fillColor('#243447').text(`${label}: `, { continued: true });
  doc.font('Helvetica').fillColor('#243447').text(value);
}

function fmtMoney(v: string | number | null | undefined): string {
  if (v == null) return '—';
  const n = typeof v === 'number' ? v : Number(v);
  if (!Number.isFinite(n)) return String(v);
  return `RD$ ${n.toFixed(2)}`;
}

function collectPdfBuffer(doc: PDFKit.PDFDocument): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    doc.on('data', (c: Buffer) => chunks.push(c));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', (e) => reject(e));
  });
}

export async function buildUserProfilePdf(company: CompanySettingsPdf, user: UserForPdf): Promise<Buffer> {
  const doc = new PDFDocument({ size: 'A4', margin: 48, compress: false });
  const bufferPromise = collectPdfBuffer(doc);

  // Header
  doc.fontSize(16).fillColor('#0B1B2B').font('Helvetica-Bold').text(company.nombre_empresa);
  doc.fontSize(10).fillColor('#243447').font('Helvetica').text(`RNC: ${company.rnc}   Tel: ${company.telefono}`);
  doc.fontSize(10).text(company.direccion);
  doc.moveDown(0.6);
  doc.fontSize(14).fillColor('#0B1B2B').font('Helvetica-Bold').text('Ficha de Empleado', { align: 'center' });

  sectionTitle(doc, 'Datos personales');
  kv(doc, 'Nombre', user.nombre_completo || '—');
  kv(doc, 'Edad', user.edad != null ? String(user.edad) : '—');
  kv(doc, 'Fecha de nacimiento', fmtDate(user.fecha_nacimiento));
  kv(doc, 'Lugar de nacimiento', user.lugar_nacimiento || '—');
  kv(doc, 'Cédula', user.cedula_numero || '—');

  sectionTitle(doc, 'Datos de contacto');
  kv(doc, 'Email', user.email || '—');
  kv(doc, 'Teléfono', user.telefono || '—');
  kv(doc, 'Dirección', user.direccion || '—');
  kv(doc, 'Ubicación (mapa)', user.ubicacion_mapa || '—');

  sectionTitle(doc, 'Datos familiares');
  kv(doc, 'Casado', user.es_casado ? 'Sí' : 'No');
  kv(doc, 'Cantidad de hijos', String(user.cantidad_hijos ?? 0));
  kv(doc, 'Casa propia', user.tiene_casa_propia ? 'Sí' : 'No');
  kv(doc, 'Vehículo', user.tiene_vehiculo ? 'Sí' : 'No');
  kv(doc, 'Tipo vehículo', user.tipo_vehiculo || '—');

  sectionTitle(doc, 'Información laboral');
  kv(doc, 'Rol', user.rol || '—');
  kv(doc, 'Posición', user.posicion || '—');
  kv(doc, 'Fecha ingreso', fmtDate(user.fecha_ingreso_empresa));
  kv(doc, 'Salario mensual', user.salario_mensual != null ? String(user.salario_mensual) : '—');
  kv(doc, 'Beneficios', user.beneficios || '—');
  kv(doc, 'Técnico con licencia', user.es_tecnico_con_licencia ? 'Sí' : 'No');
  kv(doc, 'Número licencia técnica', user.numero_licencia_tecnica || '—');
  kv(doc, 'Licencia conducir', user.licencia_conducir_numero || '—');
  kv(doc, 'Vence licencia conducir', fmtDate(user.licencia_conducir_fecha_vencimiento));

  sectionTitle(doc, 'IA (placeholder)');
  doc.font('Helvetica').fillColor('#243447').fontSize(10).text(
    'Espacio reservado para autocompletar campos con IA a partir de la cédula (pendiente de integración).',
  );

  doc.end();
  return bufferPromise;
}

export async function buildUserContractPdf(company: CompanySettingsPdf, user: UserForPdf): Promise<Buffer> {
  const doc = new PDFDocument({ size: 'A4', margin: 48, compress: false });
  const bufferPromise = collectPdfBuffer(doc);

  doc.fontSize(16).fillColor('#0B1B2B').font('Helvetica-Bold').text(company.nombre_empresa);
  doc.fontSize(10).fillColor('#243447').font('Helvetica').text(`RNC: ${company.rnc}   Tel: ${company.telefono}`);
  doc.fontSize(10).text(company.direccion);
  doc.moveDown(0.8);

  doc.fontSize(14).fillColor('#0B1B2B').font('Helvetica-Bold').text('Contrato Laboral', { align: 'center' });
  doc.moveDown(0.8);

  doc.fontSize(10).fillColor('#243447').font('Helvetica').text(
    `En la fecha ${fmtDate(new Date())}, entre ${company.nombre_empresa} (RNC: ${company.rnc}, Tel: ${company.telefono}, Dirección: ${company.direccion}) (en adelante, “LA EMPRESA”) y ${
      user.nombre_completo || '__________'
    } (en adelante, “EL EMPLEADO”), portador(a) de la cédula No. ${user.cedula_numero || '__________'}, se acuerda el presente contrato laboral bajo las siguientes condiciones:`,
    { align: 'justify' },
  );

  sectionTitle(doc, 'Datos del empleado');
  kv(doc, 'Nombre', user.nombre_completo || '—');
  kv(doc, 'Cédula', user.cedula_numero || '—');
  kv(doc, 'Email', user.email || '—');
  kv(doc, 'Teléfono', user.telefono || '—');
  kv(doc, 'Dirección', user.direccion || '—');
  kv(doc, 'Puesto', user.posicion || user.rol || '—');
  kv(doc, 'Fecha de ingreso', user.fecha_ingreso_empresa ? fmtDate(user.fecha_ingreso_empresa) : '—');
  kv(doc, 'Salario mensual', fmtMoney(user.salario_mensual));
  kv(doc, 'Beneficios', user.beneficios || '—');

  sectionTitle(doc, 'Cláusulas');

  doc.fontSize(10).fillColor('#243447').font('Helvetica-Bold').text('1. Objeto del contrato');
  doc.font('Helvetica').text(
    'EL EMPLEADO prestará servicios personales para LA EMPRESA, bajo dirección y dependencia, cumpliendo las políticas internas y la legislación laboral aplicable.',
    { align: 'justify' },
  );

  doc.moveDown(0.5);
  doc.font('Helvetica-Bold').text('2. Puesto y funciones');
  doc.font('Helvetica').text(
    `EL EMPLEADO desempeñará el puesto de ${user.posicion || user.rol || '__________'} y realizará las funciones propias del cargo, así como otras tareas razonables asignadas por LA EMPRESA, siempre que sean compatibles con su puesto y formación.`,
    { align: 'justify' },
  );

  doc.moveDown(0.5);
  doc.font('Helvetica-Bold').text('3. Jornada y lugar de trabajo');
  doc.font('Helvetica').text(
    'La jornada, horarios, descansos y lugar de prestación de servicios serán establecidos por LA EMPRESA conforme a sus necesidades operativas y la ley. El empleado se compromete a cumplir con el horario asignado y reportar cualquier ausencia o retraso.',
    { align: 'justify' },
  );

  doc.moveDown(0.5);
  doc.font('Helvetica-Bold').text('4. Salario y forma de pago');
  doc.font('Helvetica').text(
    `LA EMPRESA pagará a EL EMPLEADO un salario mensual de ${fmtMoney(user.salario_mensual)}, sujeto a las deducciones legales aplicables. El pago se realizará por los medios habituales de LA EMPRESA (transferencia, cheque o efectivo según corresponda).`,
    { align: 'justify' },
  );

  doc.moveDown(0.5);
  doc.font('Helvetica-Bold').text('5. Beneficios');
  doc.font('Helvetica').text(
    `Además del salario, EL EMPLEADO podrá recibir los beneficios acordados y/o establecidos por la ley. Beneficios registrados: ${user.beneficios || '—'}.`,
    { align: 'justify' },
  );

  doc.moveDown(0.5);
  doc.font('Helvetica-Bold').text('6. Herramientas, equipos y documentos');
  doc.font('Helvetica').text(
    'Las herramientas, equipos, credenciales y documentos proporcionados por LA EMPRESA son para uso exclusivo laboral. EL EMPLEADO se obliga a cuidarlos, reportar daños o pérdidas, y devolverlos al finalizar la relación laboral.',
    { align: 'justify' },
  );

  doc.moveDown(0.5);
  doc.font('Helvetica-Bold').text('7. Confidencialidad y datos');
  doc.font('Helvetica').text(
    'EL EMPLEADO se compromete a guardar confidencialidad sobre información técnica, comercial y operativa de LA EMPRESA y de sus clientes, tanto durante como después de terminada la relación laboral, salvo autorización escrita o requerimiento legal.',
    { align: 'justify' },
  );

  doc.moveDown(0.5);
  doc.font('Helvetica-Bold').text('8. Conducta, políticas y seguridad');
  doc.font('Helvetica').text(
    'EL EMPLEADO se compromete a cumplir normas de seguridad, uso de uniforme/identificación cuando aplique, prevención de riesgos, y políticas internas (incluyendo uso de vehículos, herramientas y protocolos de servicio).',
    { align: 'justify' },
  );

  doc.moveDown(0.5);
  doc.font('Helvetica-Bold').text('9. Licencias (cuando aplique)');
  doc.font('Helvetica').text(
    `Si EL EMPLEADO requiere licencias para el desempeño del cargo, declara: licencia conducir No. ${user.licencia_conducir_numero || '—'} (vence ${fmtDate(
      user.licencia_conducir_fecha_vencimiento,
    )}); licencia técnica: ${user.numero_licencia_tecnica || '—'}.`,
    { align: 'justify' },
  );

  doc.moveDown(0.5);
  doc.font('Helvetica-Bold').text('10. Duración y modificaciones');
  doc.font('Helvetica').text(
    'Este contrato podrá ser por tiempo indefinido o definido según acuerdo interno. Cualquier modificación deberá constar por escrito y estar firmada por ambas partes.',
    { align: 'justify' },
  );

  doc.moveDown(0.5);
  doc.font('Helvetica-Bold').text('11. Terminación');
  doc.font('Helvetica').text(
    'La terminación de la relación laboral se regirá por la legislación vigente y las causales aplicables. Al finalizar, EL EMPLEADO devolverá equipos y documentos, y se realizará el proceso de salida correspondiente.',
    { align: 'justify' },
  );

  doc.moveDown(0.5);
  doc.font('Helvetica-Bold').text('12. Aceptación');
  doc.font('Helvetica').text(
    'Leído el presente contrato, las partes manifiestan estar conformes y lo firman en dos (2) ejemplares de un mismo tenor.',
    { align: 'justify' },
  );

  // Firmas en página separada para evitar cortes del contenido.
  doc.addPage();
  doc.fontSize(12).fillColor('#0B1B2B').font('Helvetica-Bold').text('Firmas', { align: 'center' });
  doc.moveDown(1.5);

  const lineY = doc.y + 40;
  const leftX = doc.page.margins.left;
  const rightX = doc.page.width / 2 + 24;
  const lineWidth = doc.page.width / 2 - 72;

  doc.moveTo(leftX, lineY).lineTo(leftX + lineWidth, lineY).strokeColor('#243447').stroke();
  doc.moveTo(rightX, lineY).lineTo(rightX + lineWidth, lineY).strokeColor('#243447').stroke();

  doc.fontSize(10).fillColor('#243447').font('Helvetica').text('LA EMPRESA', leftX, lineY + 8);
  doc.text('EL EMPLEADO', rightX, lineY + 8);

  doc.moveDown(8);
  doc.fontSize(9).fillColor('#64748B').font('Helvetica').text(
    `Documento generado por el sistema. Empresa: ${company.nombre_empresa}. Empleado: ${user.nombre_completo || '—'}.`,
    { align: 'center' },
  );

  doc.end();
  return bufferPromise;
}
