import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import puppeteer from 'puppeteer';
import path from 'path';

const prisma = new PrismaClient();

export class PdfController {
  /**
   * GET /api/usuarios/:id/profile-pdf
   * Generar PDF de ficha de empleado
   */
  static async generateProfilePDF(req: Request, res: Response) {
    try {
      const { id } = req.params;

      const usuario = await prisma.usuario.findUnique({
        where: { id },
      });

      if (!usuario) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const company = await prisma.companySettings.findFirst();

      // HTML del PDF
      const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <style>
            body {
              font-family: Arial, sans-serif;
              margin: 0;
              padding: 20px;
              background: #f5f5f5;
            }
            .container {
              max-width: 800px;
              margin: 0 auto;
              background: white;
              padding: 30px;
              border-radius: 8px;
            }
            .header {
              display: flex;
              justify-content: space-between;
              align-items: center;
              border-bottom: 3px solid #0066cc;
              padding-bottom: 20px;
              margin-bottom: 20px;
            }
            .company-info h1 {
              margin: 0;
              color: #0066cc;
              font-size: 24px;
            }
            .company-info p {
              margin: 5px 0;
              font-size: 12px;
              color: #666;
            }
            .photo {
              width: 120px;
              height: 120px;
              border-radius: 8px;
              background: #e0e0e0;
              display: flex;
              align-items: center;
              justify-content: center;
              color: #999;
            }
            .section {
              margin-bottom: 25px;
            }
            .section-title {
              background: #0066cc;
              color: white;
              padding: 10px 15px;
              margin-bottom: 15px;
              border-radius: 4px;
              font-weight: bold;
            }
            .field-row {
              display: flex;
              margin-bottom: 12px;
              border-bottom: 1px solid #eee;
              padding-bottom: 8px;
            }
            .field-label {
              font-weight: bold;
              width: 200px;
              color: #0066cc;
            }
            .field-value {
              flex: 1;
              color: #333;
            }
            .two-columns {
              display: flex;
              gap: 30px;
            }
            .column {
              flex: 1;
            }
            .badge {
              display: inline-block;
              padding: 5px 12px;
              border-radius: 20px;
              font-size: 12px;
              margin-right: 5px;
            }
            .badge-active {
              background: #d4edda;
              color: #155724;
            }
            .badge-blocked {
              background: #f8d7da;
              color: #721c24;
            }
            .footer {
              text-align: center;
              margin-top: 40px;
              padding-top: 20px;
              border-top: 1px solid #ddd;
              font-size: 12px;
              color: #999;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <div class="company-info">
                <h1>FICHA DE EMPLEADO</h1>
                <p><strong>${company?.nombre_empresa || 'Fulltech'}</strong></p>
                <p>RNC: ${company?.rnc || 'N/A'}</p>
              </div>
              <div class="photo">
                ${usuario.foto_perfil_url ? `<img src="${usuario.foto_perfil_url}" style="width: 100%; height: 100%; border-radius: 8px; object-fit: cover;">` : 'SIN FOTO'}
              </div>
            </div>

            <!-- DATOS PERSONALES -->
            <div class="section">
              <div class="section-title">DATOS PERSONALES</div>
              <div class="field-row">
                <div class="field-label">Nombre Completo:</div>
                <div class="field-value">${usuario.nombre_completo}</div>
              </div>
              <div class="field-row">
                <div class="field-label">Cédula:</div>
                <div class="field-value">${usuario.cedula_numero}</div>
              </div>
              <div class="field-row">
                <div class="field-label">Fecha Nacimiento:</div>
                <div class="field-value">${usuario.fecha_nacimiento ? new Date(usuario.fecha_nacimiento).toLocaleDateString('es-DO') : 'N/A'}</div>
              </div>
              <div class="field-row">
                <div class="field-label">Edad:</div>
                <div class="field-value">${usuario.edad || 'N/A'} años</div>
              </div>
              <div class="field-row">
                <div class="field-label">Lugar Nacimiento:</div>
                <div class="field-value">${usuario.lugar_nacimiento || 'N/A'}</div>
              </div>
            </div>

            <!-- DATOS DE CONTACTO -->
            <div class="section">
              <div class="section-title">DATOS DE CONTACTO</div>
              <div class="field-row">
                <div class="field-label">Email:</div>
                <div class="field-value">${usuario.email}</div>
              </div>
              <div class="field-row">
                <div class="field-label">Teléfono:</div>
                <div class="field-value">${usuario.telefono}</div>
              </div>
              <div class="field-row">
                <div class="field-label">Dirección:</div>
                <div class="field-value">${usuario.direccion}</div>
              </div>
            </div>

            <!-- DATOS FAMILIARES -->
            <div class="section">
              <div class="section-title">DATOS FAMILIARES Y PATRIMONIALES</div>
              <div class="two-columns">
                <div class="column">
                  <div class="field-row">
                    <div class="field-label">Estado Civil:</div>
                    <div class="field-value">${usuario.es_casado ? 'Casado(a)' : 'Soltero(a)'}</div>
                  </div>
                  <div class="field-row">
                    <div class="field-label">Cantidad Hijos:</div>
                    <div class="field-value">${usuario.cantidad_hijos}</div>
                  </div>
                </div>
                <div class="column">
                  <div class="field-row">
                    <div class="field-label">Casa Propia:</div>
                    <div class="field-value">${usuario.tiene_casa_propia ? 'Sí' : 'No'}</div>
                  </div>
                  <div class="field-row">
                    <div class="field-label">Vehículo:</div>
                    <div class="field-value">${usuario.tiene_vehiculo ? `Sí (${usuario.tipo_vehiculo || 'N/A'})` : 'No'}</div>
                  </div>
                </div>
              </div>
            </div>

            <!-- DATOS LABORALES -->
            <div class="section">
              <div class="section-title">DATOS LABORALES</div>
              <div class="field-row">
                <div class="field-label">Rol:</div>
                <div class="field-value">
                  <span class="badge badge-active">${usuario.rol}</span>
                </div>
              </div>
              <div class="field-row">
                <div class="field-label">Posición:</div>
                <div class="field-value">${usuario.posicion}</div>
              </div>
              <div class="field-row">
                <div class="field-label">Fecha Ingreso:</div>
                <div class="field-value">${usuario.fecha_ingreso_empresa ? new Date(usuario.fecha_ingreso_empresa).toLocaleDateString('es-DO') : 'N/A'}</div>
              </div>
              <div class="field-row">
                <div class="field-label">Salario Mensual:</div>
                <div class="field-value">RD$ ${usuario.salario_mensual ? parseFloat(usuario.salario_mensual.toString()).toLocaleString('es-DO', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '0.00'}</div>
              </div>
              <div class="field-row">
                <div class="field-label">Beneficios:</div>
                <div class="field-value">${usuario.beneficios || 'N/A'}</div>
              </div>
              <div class="field-row">
                <div class="field-label">Último Trabajo:</div>
                <div class="field-value">${usuario.ultimo_trabajo || 'N/A'}</div>
              </div>
              ${usuario.es_tecnico_con_licencia ? `
              <div class="field-row">
                <div class="field-label">Licencia Técnica:</div>
                <div class="field-value">${usuario.numero_licencia || 'N/A'}</div>
              </div>
              ` : ''}
            </div>

            <!-- ESTADO -->
            <div class="section">
              <div class="field-row">
                <div class="field-label">Estado:</div>
                <div class="field-value">
                  <span class="badge ${usuario.estado === 'activo' ? 'badge-active' : 'badge-blocked'}">
                    ${usuario.estado.toUpperCase()}
                  </span>
                </div>
              </div>
            </div>

            <div class="footer">
              <p>Documento generado el ${new Date().toLocaleDateString('es-DO')} a las ${new Date().toLocaleTimeString('es-DO')}</p>
              <p>Fulltech CRM &amp; Operaciones</p>
            </div>
          </div>
        </body>
        </html>
      `;

      // Generar PDF con puppeteer
      const browser = await puppeteer.launch({
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
      });
      const page = await browser.newPage();
      await page.setContent(htmlContent);
      const pdfBuffer = await page.pdf({
        format: 'A4',
        margin: { top: '20px', bottom: '20px', left: '20px', right: '20px' },
      });
      await browser.close();

      res.set({
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="ficha_${usuario.id}.pdf"`,
      });
      res.send(pdfBuffer);
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }

  /**
   * GET /api/usuarios/:id/contract-pdf
   * Generar contrato laboral
   */
  static async generateContractPDF(req: Request, res: Response) {
    try {
      const { id } = req.params;

      const usuario = await prisma.usuario.findUnique({
        where: { id },
      });

      if (!usuario) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const company = await prisma.companySettings.findFirst();

      const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <style>
            body {
              font-family: 'Times New Roman', serif;
              margin: 0;
              padding: 40px;
              line-height: 1.6;
            }
            .container {
              max-width: 800px;
              margin: 0 auto;
            }
            .header {
              text-align: center;
              margin-bottom: 40px;
            }
            .header h1 {
              font-size: 18px;
              margin: 10px 0;
              text-transform: uppercase;
            }
            .header p {
              margin: 5px 0;
              font-size: 12px;
            }
            .title {
              text-align: center;
              font-size: 16px;
              font-weight: bold;
              margin: 30px 0 20px 0;
              text-transform: uppercase;
            }
            .section {
              margin-bottom: 20px;
            }
            .section p {
              margin: 8px 0;
              text-align: justify;
            }
            .signature-section {
              margin-top: 50px;
              display: flex;
              justify-content: space-between;
            }
            .signature-box {
              text-align: center;
              width: 35%;
            }
            .signature-line {
              border-top: 1px solid #000;
              margin-top: 40px;
              padding-top: 10px;
            }
            .footer {
              text-align: center;
              margin-top: 40px;
              font-size: 12px;
              color: #666;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>${company?.nombre_empresa || 'Fulltech'}</h1>
              <p>RNC: ${company?.rnc || 'N/A'}</p>
              <p>${company?.direccion || ''}</p>
              <p>Teléfono: ${company?.telefono || ''} | Email: ${company?.email || ''}</p>
            </div>

            <div class="title">Contrato Laboral Individual</div>

            <div class="section">
              <p><strong>CONTRATANTE:</strong></p>
              <p>
                La empresa <strong>${company?.nombre_empresa || 'Fulltech'}</strong>, registrada con
                RNC <strong>${company?.rnc || 'N/A'}</strong>, con domicilio en
                <strong>${company?.direccion || 'N/A'}</strong>, representada por sus apoderados debidamente
                facultados, en lo adelante denominada EL EMPLEADOR.
              </p>
            </div>

            <div class="section">
              <p><strong>CONTRATADO:</strong></p>
              <p>
                <strong>${usuario.nombre_completo}</strong>, cédula de identidad No.
                <strong>${usuario.cedula_numero}</strong>, domiciliado en
                <strong>${usuario.direccion || 'N/A'}</strong>, teléfono
                <strong>${usuario.telefono}</strong>, en lo adelante denominado EL EMPLEADO.
              </p>
            </div>

            <div class="section">
              <p><strong>EXPONEN Y ACUERDAN:</strong></p>
              <p>
                Primero: EL EMPLEADOR necesita los servicios de EL EMPLEADO y éste acepta laborar para
                el referido empleador, por lo que celebran el presente contrato bajo los términos y condiciones
                siguientes:
              </p>
            </div>

            <div class="section">
              <p><strong>1. DESCRIPCIÓN DEL PUESTO:</strong></p>
              <p>
                EL EMPLEADO se compromete a desempeñar las funciones de <strong>${usuario.posicion}</strong>,
                bajo la dirección y supervisión de los representantes de EL EMPLEADOR.
              </p>
            </div>

            <div class="section">
              <p><strong>2. PERÍODO DE PRUEBA:</strong></p>
              <p>
                Se acuerda un período de prueba de treinta (30) días a partir de la fecha de inicio de labores,
                durante el cual cualquiera de las partes podrá dar por terminado el contrato sin responsabilidad alguna.
              </p>
            </div>

            <div class="section">
              <p><strong>3. SALARIO Y FORMA DE PAGO:</strong></p>
              <p>
                EL EMPLEADOR pagará a EL EMPLEADO una remuneración mensual de <strong>RD$ ${usuario.salario_mensual ? parseFloat(usuario.salario_mensual.toString()).toLocaleString('es-DO', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '0.00'}</strong>,
                pagadera mediante depósito bancario, quincenal o mensualmente, según lo acordado.
              </p>
            </div>

            <div class="section">
              <p><strong>4. JORNADA DE TRABAJO:</strong></p>
              <p>
                La jornada de trabajo será de conformidad con lo establecido en el Código de Trabajo de la República
                Dominicana, siendo de ocho (8) horas diarias, de lunes a viernes.
              </p>
            </div>

            <div class="section">
              <p><strong>5. BENEFICIOS:</strong></p>
              <p>
                EL EMPLEADO gozará de los siguientes beneficios: ${usuario.beneficios || 'Según lo establecido en la ley'}
              </p>
            </div>

            <div class="section">
              <p><strong>6. CAUSAS DE TERMINACIÓN:</strong></p>
              <p>
                Este contrato podrá terminarse por:
              </p>
              <p style="margin-left: 20px;">
                a) Acuerdo mutuo de las partes<br>
                b) Vencimiento del plazo si hubiere<br>
                c) Muerte del empleado<br>
                d) Renuncia del empleado<br>
                e) Despido justificado
              </p>
            </div>

            <div class="section">
              <p><strong>7. CONFIDENCIALIDAD:</strong></p>
              <p>
                EL EMPLEADO se compromete a mantener confidencialidad sobre toda información, datos y procedimientos
                de la empresa durante y después de su relación laboral.
              </p>
            </div>

            <div class="signature-section">
              <div class="signature-box">
                <p><strong>EL EMPLEADOR</strong></p>
                <div class="signature-line">
                  <p style="margin: 0;">_____________________</p>
                </div>
              </div>
              <div class="signature-box">
                <p><strong>EL EMPLEADO</strong></p>
                <div class="signature-line">
                  <p style="margin: 0;">_____________________</p>
                  <p style="margin: 5px 0 0 0; font-size: 11px;">${usuario.nombre_completo}</p>
                </div>
              </div>
            </div>

            <div class="footer">
              <p>Santo Domingo, República Dominicana, ${new Date().toLocaleDateString('es-DO')}</p>
            </div>
          </div>
        </body>
        </html>
      `;

      const browser = await puppeteer.launch({
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
      });
      const page = await browser.newPage();
      await page.setContent(htmlContent);
      const pdfBuffer = await page.pdf({
        format: 'A4',
        margin: { top: '20px', bottom: '20px', left: '20px', right: '20px' },
      });
      await browser.close();

      res.set({
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="contrato_${usuario.id}.pdf"`,
      });
      res.send(pdfBuffer);
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
}
