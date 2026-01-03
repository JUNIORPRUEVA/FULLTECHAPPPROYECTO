import puppeteer from 'puppeteer';

export type CompanySettingsPdf = {
  nombre_empresa: string;
  nombre_comercial?: string | null;
  rnc: string;
  telefono: string;
  direccion: string;
  ciudad?: string | null;
  provincia?: string | null;
  pais?: string | null;
  email?: string | null;
  sitio_web?: string | null;
  nombre_representante?: string | null;
  cargo_representante?: string | null;
  logo_url?: string | null;
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
  placa?: string | null;
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

  foto_perfil_url?: string | null;
  cedula_foto_frontal_url?: string | null;
  cedula_foto_posterior_url?: string | null;
  licencia_conducir_foto_url?: string | null;
  carta_ultimo_trabajo_url?: string | null;
  otros_documentos_url?: string[] | null;
};

function fmtDate(d: Date | null | undefined): string {
  if (!d) return '—';
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${day}/${m}/${y}`;
}

function safeText(v: unknown): string {
  if (v == null) return '—';
  const s = String(v).trim();
  return s.length ? s : '—';
}

function resolvePublicUrl(baseUrl: string, url: string | null | undefined): string | null {
  if (!url) return null;
  const trimmed = url.trim();
  if (!trimmed) return null;
  if (/^https?:\/\//i.test(trimmed)) return trimmed;
  if (trimmed.startsWith('/')) return `${baseUrl}${trimmed}`;
  return `${baseUrl}/${trimmed}`;
}

function buildFooterTemplate(company: CompanySettingsPdf) {
  const left = `${safeText(company.nombre_empresa)} • RNC ${safeText(company.rnc)}`;
  // puppeteer footerTemplate requires inline CSS only.
  return `
  <div style="font-size:9px; width:100%; padding:0 18mm; color:#111; display:flex; justify-content:space-between;">
    <div>${left}</div>
    <div>Página <span class="pageNumber"></span> de <span class="totalPages"></span></div>
  </div>`;
}

function buildBaseCss() {
  // “encabezados azul corporativo”, texto negro, márgenes uniformes.
  return `
  :root{ --blue:#0B61D6; --text:#111; --muted:#5B6675; --border:#E6EAF0; }
  *{ box-sizing:border-box; }
  body{ font-family: Arial, Helvetica, sans-serif; color:var(--text); margin:0; }
  .page{ padding:16mm 16mm 18mm 16mm; }
  .header{ display:flex; gap:14px; align-items:center; border-bottom:3px solid var(--blue); padding-bottom:10px; }
  .logo{ width:56px; height:56px; object-fit:contain; }
  .company{ flex:1; }
  .company h1{ margin:0; font-size:18px; color:var(--blue); }
  .company .meta{ margin-top:4px; font-size:10.5px; color:var(--muted); line-height:1.35; }
  .title{ margin:14px 0 10px; font-size:16px; font-weight:700; color:var(--blue); text-align:center; }
  .section{ margin-top:14px; }
  .section h2{ margin:0 0 8px; font-size:12.5px; color:var(--blue); border-left:4px solid var(--blue); padding-left:8px; }
  .grid{ display:grid; grid-template-columns: 1fr 1fr; gap:10px 14px; }
  .row{ display:flex; gap:8px; border-bottom:1px solid var(--border); padding:6px 0; }
  .label{ width:160px; font-weight:700; color:var(--blue); font-size:10.5px; }
  .value{ flex:1; font-size:10.5px; color:var(--text); }
  .note{ font-size:10px; color:var(--muted); line-height:1.35; }
  .badges{ display:flex; flex-wrap:wrap; gap:6px; }
  .badge{ font-size:9.5px; padding:3px 8px; border-radius:999px; border:1px solid var(--border); }
  .badge.ok{ background:#E9F6EC; border-color:#CFEAD6; }
  .badge.warn{ background:#FFF5E5; border-color:#FFE2B5; }
  .signature{ margin-top:26mm; display:flex; gap:18mm; }
  .sig{ flex:1; }
  .sig .line{ border-top:1px solid #111; margin-top:18mm; }
  .sig .who{ margin-top:6px; font-size:10px; color:var(--muted); }
  `;
}

async function renderPdfFromHtml(html: string, footerTemplate: string): Promise<Buffer> {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  try {
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: 'networkidle0' });

    const pdf = await page.pdf({
      format: 'A4',
      printBackground: true,
      displayHeaderFooter: true,
      headerTemplate: '<div></div>',
      footerTemplate,
      margin: {
        top: '14mm',
        right: '12mm',
        bottom: '18mm',
        left: '12mm',
      },
    });

    return Buffer.from(pdf);
  } finally {
    await browser.close();
  }
}

export async function buildUserProfilePdf(
  company: CompanySettingsPdf,
  user: UserForPdf,
  opts: { publicBaseUrl: string },
): Promise<Buffer> {
  const logoSrc = resolvePublicUrl(opts.publicBaseUrl, company.logo_url) || '';

  const docs = [
    { label: 'Foto de perfil', ok: !!user.foto_perfil_url },
    { label: 'Cédula (frontal)', ok: !!user.cedula_foto_frontal_url },
    { label: 'Cédula (posterior)', ok: !!user.cedula_foto_posterior_url },
    { label: 'Licencia de conducir', ok: !!user.licencia_conducir_foto_url },
    { label: 'Carta de trabajo', ok: !!user.carta_ultimo_trabajo_url },
    { label: 'Otros documentos', ok: (user.otros_documentos_url?.length ?? 0) > 0 },
  ];

  const html = `
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <style>${buildBaseCss()}</style>
</head>
<body>
  <div class="page">
    <div class="header">
      ${logoSrc ? `<img class="logo" src="${logoSrc}" />` : `<div class="logo" style="border:1px solid var(--border); border-radius:8px;"></div>`}
      <div class="company">
        <h1>${safeText(company.nombre_comercial || company.nombre_empresa)}</h1>
        <div class="meta">
          <div><strong>${safeText(company.nombre_empresa)}</strong></div>
          <div>RNC: ${safeText(company.rnc)} · Tel: ${safeText(company.telefono)}</div>
          <div>${safeText(company.direccion)}</div>
        </div>
      </div>
    </div>

    <div class="title">Ficha de Empleado</div>

    <div class="section">
      <h2>1. Datos personales</h2>
      <div class="grid">
        <div class="row"><div class="label">Nombre</div><div class="value">${safeText(user.nombre_completo)}</div></div>
        <div class="row"><div class="label">Cédula</div><div class="value">${safeText(user.cedula_numero)}</div></div>
        <div class="row"><div class="label">Fecha nacimiento</div><div class="value">${fmtDate(user.fecha_nacimiento)}</div></div>
        <div class="row"><div class="label">Edad</div><div class="value">${user.edad != null ? String(user.edad) : '—'}</div></div>
        <div class="row"><div class="label">Lugar nacimiento</div><div class="value">${safeText(user.lugar_nacimiento)}</div></div>
      </div>
    </div>

    <div class="section">
      <h2>2. Contacto</h2>
      <div class="grid">
        <div class="row"><div class="label">Email</div><div class="value">${safeText(user.email)}</div></div>
        <div class="row"><div class="label">Teléfono</div><div class="value">${safeText(user.telefono)}</div></div>
        <div class="row"><div class="label">Dirección</div><div class="value">${safeText(user.direccion)}</div></div>
        <div class="row"><div class="label">Ubicación mapa</div><div class="value">${safeText(user.ubicacion_mapa)}</div></div>
      </div>
    </div>

    <div class="section">
      <h2>3. Familiar / Patrimonio</h2>
      <div class="grid">
        <div class="row"><div class="label">Estado civil</div><div class="value">${user.es_casado ? 'Casado/a' : 'Soltero/a'}</div></div>
        <div class="row"><div class="label">Cantidad hijos</div><div class="value">${String(user.cantidad_hijos ?? 0)}</div></div>
        <div class="row"><div class="label">Casa propia</div><div class="value">${user.tiene_casa_propia ? 'Sí' : 'No'}</div></div>
        <div class="row"><div class="label">Vehículo</div><div class="value">${user.tiene_vehiculo ? 'Sí' : 'No'}</div></div>
        <div class="row"><div class="label">Tipo vehículo</div><div class="value">${safeText(user.tipo_vehiculo)}</div></div>
        <div class="row"><div class="label">Placa</div><div class="value">${safeText(user.placa)}</div></div>
      </div>
    </div>

    <div class="section">
      <h2>4. Información laboral</h2>
      <div class="grid">
        <div class="row"><div class="label">Rol</div><div class="value">${safeText(user.rol)}</div></div>
        <div class="row"><div class="label">Posición</div><div class="value">${safeText(user.posicion || user.rol)}</div></div>
        <div class="row"><div class="label">Fecha ingreso</div><div class="value">${fmtDate(user.fecha_ingreso_empresa)}</div></div>
        <div class="row"><div class="label">Salario mensual</div><div class="value">${user.salario_mensual != null ? `RD$ ${safeText(user.salario_mensual)}` : '—'}</div></div>
        <div class="row"><div class="label">Beneficios</div><div class="value">${safeText(user.beneficios)}</div></div>
      </div>
    </div>

    <div class="section">
      <h2>5. Licencias y documentos</h2>
      <div class="grid">
        <div class="row"><div class="label">Técnico con licencia</div><div class="value">${user.es_tecnico_con_licencia ? 'Sí' : 'No'}</div></div>
        <div class="row"><div class="label">Licencia técnica</div><div class="value">${safeText(user.numero_licencia_tecnica)}</div></div>
        <div class="row"><div class="label">Licencia conducir</div><div class="value">${safeText(user.licencia_conducir_numero)}</div></div>
        <div class="row"><div class="label">Vence licencia</div><div class="value">${fmtDate(user.licencia_conducir_fecha_vencimiento)}</div></div>
      </div>

      <div style="margin-top:10px;">
        <div class="badges">
          ${docs
            .map((d) => `<span class="badge ${d.ok ? 'ok' : 'warn'}">${d.label}: ${d.ok ? 'Adjunto' : 'No'}</span>`)
            .join('')}
        </div>
        <div class="note" style="margin-top:8px;">Por seguridad, el PDF no muestra rutas/URLs de archivos. Solo indica si están adjuntos.</div>
      </div>
    </div>

  </div>
</body>
</html>`;

  return renderPdfFromHtml(html, buildFooterTemplate(company));
}

export async function buildUserContractPdf(
  company: CompanySettingsPdf,
  user: UserForPdf,
  opts: { publicBaseUrl: string },
): Promise<Buffer> {
  const logoSrc = resolvePublicUrl(opts.publicBaseUrl, company.logo_url) || '';

  const repName = safeText(company.nombre_representante);
  const repRole = safeText(company.cargo_representante);

  const salario = user.salario_mensual != null ? `RD$ ${safeText(user.salario_mensual)}` : 'RD$ ________';
  const fechaIngreso = user.fecha_ingreso_empresa ? fmtDate(user.fecha_ingreso_empresa) : '____/____/______';

  const html = `
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <style>${buildBaseCss()}</style>
  <style>
    .contract p{ margin: 0 0 10px; font-size: 11px; line-height: 1.45; color: var(--text); text-align: justify; }
    .contract h3{ margin: 14px 0 6px; font-size: 12px; color: var(--blue); }
    .contract .small{ font-size:10px; color:var(--muted); }
  </style>
</head>
<body>
  <div class="page">
    <div class="header">
      ${logoSrc ? `<img class="logo" src="${logoSrc}" />` : `<div class="logo" style="border:1px solid var(--border); border-radius:8px;"></div>`}
      <div class="company">
        <h1>${safeText(company.nombre_comercial || company.nombre_empresa)}</h1>
        <div class="meta">
          <div><strong>${safeText(company.nombre_empresa)}</strong></div>
          <div>RNC: ${safeText(company.rnc)} · Tel: ${safeText(company.telefono)}</div>
          <div>${safeText(company.direccion)}</div>
        </div>
      </div>
    </div>

    <div class="title">Contrato Laboral</div>

    <div class="contract">
      <p>
        Entre <strong>${safeText(company.nombre_empresa)}</strong>, RNC <strong>${safeText(company.rnc)}</strong>,
        con domicilio en <strong>${safeText(company.direccion)}</strong> (en adelante, “LA EMPRESA”),
        y <strong>${safeText(user.nombre_completo)}</strong>, portador(a) de la cédula No. <strong>${safeText(user.cedula_numero)}</strong>
        (en adelante, “EL EMPLEADO”), se conviene el presente contrato laboral conforme a las leyes aplicables de la República Dominicana.
      </p>

      <h3>1. Funciones y puesto</h3>
      <p>
        EL EMPLEADO desempeñará el puesto de <strong>${safeText(user.posicion || user.rol)}</strong> y realizará las funciones propias del cargo,
        además de aquellas razonablemente asignadas por LA EMPRESA relacionadas con sus operaciones.
      </p>

      <h3>2. Horario</h3>
      <p>
        El horario ordinario de trabajo será el establecido por LA EMPRESA según su reglamento interno, respetando los límites legales.
        Cualquier modificación será comunicada oportunamente.
      </p>

      <h3>3. Salario</h3>
      <p>
        LA EMPRESA pagará a EL EMPLEADO un salario mensual de <strong>${salario}</strong>, sujeto a las deducciones legales.
      </p>

      <h3>4. Fecha de ingreso</h3>
      <p>La fecha de ingreso del EMPLEADO será <strong>${fechaIngreso}</strong>.</p>

      <h3>5. Confidencialidad</h3>
      <p>
        EL EMPLEADO se obliga a mantener confidencialidad sobre la información técnica, comercial y operativa de LA EMPRESA,
        tanto durante la vigencia del contrato como después de su terminación.
      </p>

      <p class="small">
        Este documento constituye un contrato laboral básico. Para condiciones especiales, anexos o políticas internas,
        se podrán adjuntar documentos complementarios.
      </p>

      <div class="signature">
        <div class="sig">
          <div class="line"></div>
          <div class="who">LA EMPRESA<br/>${repName !== '—' ? repName : ''} ${repRole !== '—' ? `· ${repRole}` : ''}</div>
        </div>
        <div class="sig">
          <div class="line"></div>
          <div class="who">EL EMPLEADO<br/>${safeText(user.nombre_completo)}</div>
        </div>
      </div>
    </div>

  </div>
</body>
</html>`;

  return renderPdfFromHtml(html, buildFooterTemplate(company));
}
