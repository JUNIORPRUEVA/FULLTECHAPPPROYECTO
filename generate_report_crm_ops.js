#!/usr/bin/env node
/**
 * Generador de Reporte HTML: Prueba CRM → Operaciones
 * 
 * Ejecuta las pruebas y genera un reporte HTML visual
 */

const fs = require('fs');
const path = require('path');

const BASE_URL = process.env.API_URL || 'http://localhost:3000';
const OUTPUT_FILE = 'reporte_crm_operaciones.html';

async function makeRequest(endpoint, options = {}) {
  const url = `${BASE_URL}${endpoint}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });
  
  const text = await response.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  
  return { response, data };
}

async function login(email, password) {
  const { response, data } = await makeRequest('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
  
  if (!response.ok) {
    throw new Error(`Login falló: ${data?.message || response.statusText}`);
  }
  
  return { token: data?.token, user: data.user };
}

async function runTests(token, user) {
  const results = {
    timestamp: new Date().toISOString(),
    user: user.nombre_completo || user.email,
    empresa_id: user.empresaId,
    tests: [],
    summary: { passed: 0, failed: 0, total: 0 },
  };
  
  // Obtener chats
  const { data: chatsData } = await makeRequest('/api/crm/chats?limit=10', {
    headers: { Authorization: `Bearer ${token}` },
  });
  
  const chats = chatsData?.items || [];
  const testChat = chats.find(c => c.status !== 'compro' && c.status !== 'cancelado');
  
  if (!testChat) {
    results.tests.push({
      name: 'Prerequisitos',
      status: 'failed',
      message: 'No hay chats disponibles para prueba',
      duration: 0,
    });
    results.summary.failed++;
    results.summary.total++;
    return results;
  }
  
  // Obtener servicios y técnicos
  const { data: servicesData } = await makeRequest('/api/settings/services', {
    headers: { Authorization: `Bearer ${token}` },
  });
  
  const { data: techniciansData } = await makeRequest('/api/operations/technicians', {
    headers: { Authorization: `Bearer ${token}` },
  });
  
  const services = servicesData?.items || [];
  const technicians = techniciansData?.items || [];
  
  if (services.length === 0 || technicians.length === 0) {
    results.tests.push({
      name: 'Prerequisitos',
      status: 'failed',
      message: 'No hay servicios o técnicos disponibles',
      duration: 0,
    });
    results.summary.failed++;
    results.summary.total++;
    return results;
  }
  
  const service = services[0];
  const technician = technicians[0];
  
  // Test 1: Por Levantamiento
  try {
    const start = Date.now();
    const scheduledAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
    
    await makeRequest(`/api/crm/chats/${testChat.id}/status`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: JSON.stringify({
        status: 'por_levantamiento',
        scheduled_at: scheduledAt.toISOString(),
        location_text: 'Calle Test 123',
        lat: -34.603722,
        lng: -58.381592,
        assigned_technician_id: technician.id,
        service_id: service.id,
        note: 'Prueba automatizada',
      }),
    });
    
    const { data: jobsData } = await makeRequest('/api/operations/jobs', {
      headers: { Authorization: `Bearer ${token}` },
    });
    
    const job = (jobsData?.items || []).find(j => 
      j.crm_chat_id === testChat.id && 
      j.crm_task_type === 'LEVANTAMIENTO'
    );
    
    const duration = Date.now() - start;
    
    if (job) {
      results.tests.push({
        name: 'Prueba 1: Por Levantamiento',
        status: 'passed',
        message: `Job creado correctamente (${job.id})`,
        duration,
        details: {
          chat_id: testChat.id,
          job_id: job.id,
          customer_name: job.customer_name,
          scheduled_at: job.scheduled_at,
        },
      });
      results.summary.passed++;
    } else {
      results.tests.push({
        name: 'Prueba 1: Por Levantamiento',
        status: 'failed',
        message: 'Job no fue creado',
        duration,
      });
      results.summary.failed++;
    }
  } catch (error) {
    results.tests.push({
      name: 'Prueba 1: Por Levantamiento',
      status: 'failed',
      message: error.message,
      duration: 0,
    });
    results.summary.failed++;
  }
  results.summary.total++;
  
  // Test 2: Idempotencia
  try {
    const start = Date.now();
    
    const { data: jobsBefore } = await makeRequest('/api/operations/jobs', {
      headers: { Authorization: `Bearer ${token}` },
    });
    
    const countBefore = (jobsBefore?.items || []).filter(j => 
      j.crm_chat_id === testChat.id && 
      j.crm_task_type === 'LEVANTAMIENTO' &&
      !['cancelled', 'completed', 'closed'].includes(j.status)
    ).length;
    
    // Cambiar estado nuevamente
    await makeRequest(`/api/crm/chats/${testChat.id}/status`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: JSON.stringify({
        status: 'por_levantamiento',
        scheduled_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        location_text: 'Calle Test 123',
        lat: -34.603722,
        lng: -58.381592,
        assigned_technician_id: technician.id,
        service_id: service.id,
        note: 'Prueba idempotencia',
      }),
    });
    
    const { data: jobsAfter } = await makeRequest('/api/operations/jobs', {
      headers: { Authorization: `Bearer ${token}` },
    });
    
    const countAfter = (jobsAfter?.items || []).filter(j => 
      j.crm_chat_id === testChat.id && 
      j.crm_task_type === 'LEVANTAMIENTO' &&
      !['cancelled', 'completed', 'closed'].includes(j.status)
    ).length;
    
    const duration = Date.now() - start;
    
    if (countBefore === countAfter && countAfter === 1) {
      results.tests.push({
        name: 'Prueba 2: Idempotencia',
        status: 'passed',
        message: 'No se crearon duplicados',
        duration,
        details: {
          jobs_before: countBefore,
          jobs_after: countAfter,
        },
      });
      results.summary.passed++;
    } else {
      results.tests.push({
        name: 'Prueba 2: Idempotencia',
        status: 'failed',
        message: `Se encontraron ${countAfter} jobs (debería ser 1)`,
        duration,
      });
      results.summary.failed++;
    }
  } catch (error) {
    results.tests.push({
      name: 'Prueba 2: Idempotencia',
      status: 'failed',
      message: error.message,
      duration: 0,
    });
    results.summary.failed++;
  }
  results.summary.total++;
  
  return results;
}

function generateHTML(results) {
  const successRate = results.summary.total > 0 
    ? Math.round((results.summary.passed / results.summary.total) * 100) 
    : 0;
  
  const statusColor = successRate === 100 ? '#10b981' : successRate >= 50 ? '#f59e0b' : '#ef4444';
  
  return `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reporte: CRM → Operaciones</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 2rem;
      min-height: 100vh;
    }
    
    .container {
      max-width: 1200px;
      margin: 0 auto;
      background: white;
      border-radius: 16px;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
      overflow: hidden;
    }
    
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 2rem;
      text-align: center;
    }
    
    .header h1 {
      font-size: 2rem;
      margin-bottom: 0.5rem;
    }
    
    .header p {
      opacity: 0.9;
      font-size: 0.95rem;
    }
    
    .summary {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1.5rem;
      padding: 2rem;
      background: #f9fafb;
    }
    
    .summary-card {
      background: white;
      border-radius: 12px;
      padding: 1.5rem;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      text-align: center;
    }
    
    .summary-card h3 {
      font-size: 0.875rem;
      color: #6b7280;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 0.5rem;
    }
    
    .summary-card .value {
      font-size: 2.5rem;
      font-weight: bold;
      color: #1f2937;
    }
    
    .summary-card.success .value {
      color: #10b981;
    }
    
    .summary-card.failed .value {
      color: #ef4444;
    }
    
    .progress-bar {
      width: 100%;
      height: 8px;
      background: #e5e7eb;
      border-radius: 4px;
      overflow: hidden;
      margin-top: 0.5rem;
    }
    
    .progress-fill {
      height: 100%;
      background: ${statusColor};
      transition: width 0.3s ease;
    }
    
    .tests {
      padding: 2rem;
    }
    
    .test-item {
      background: white;
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      padding: 1.5rem;
      margin-bottom: 1rem;
      transition: box-shadow 0.2s;
    }
    
    .test-item:hover {
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    }
    
    .test-header {
      display: flex;
      align-items: center;
      gap: 1rem;
      margin-bottom: 0.75rem;
    }
    
    .test-status {
      width: 24px;
      height: 24px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: bold;
      font-size: 0.875rem;
    }
    
    .test-status.passed {
      background: #10b981;
      color: white;
    }
    
    .test-status.failed {
      background: #ef4444;
      color: white;
    }
    
    .test-name {
      font-size: 1.125rem;
      font-weight: 600;
      color: #1f2937;
      flex: 1;
    }
    
    .test-duration {
      font-size: 0.875rem;
      color: #6b7280;
    }
    
    .test-message {
      color: #4b5563;
      margin-bottom: 0.5rem;
    }
    
    .test-details {
      background: #f9fafb;
      border-radius: 6px;
      padding: 1rem;
      margin-top: 1rem;
      font-size: 0.875rem;
      font-family: 'Courier New', monospace;
    }
    
    .test-details pre {
      white-space: pre-wrap;
      word-wrap: break-word;
    }
    
    .footer {
      background: #f9fafb;
      padding: 2rem;
      text-align: center;
      color: #6b7280;
      font-size: 0.875rem;
      border-top: 1px solid #e5e7eb;
    }
    
    .footer a {
      color: #667eea;
      text-decoration: none;
    }
    
    .footer a:hover {
      text-decoration: underline;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔍 Reporte de Verificación</h1>
      <p>Flujo: CRM → Operaciones</p>
      <p style="opacity: 0.8; margin-top: 0.5rem; font-size: 0.875rem;">
        ${new Date(results.timestamp).toLocaleString('es-AR')}
      </p>
    </div>
    
    <div class="summary">
      <div class="summary-card">
        <h3>Total Pruebas</h3>
        <div class="value">${results.summary.total}</div>
      </div>
      
      <div class="summary-card success">
        <h3>Exitosas</h3>
        <div class="value">${results.summary.passed}</div>
      </div>
      
      <div class="summary-card failed">
        <h3>Fallidas</h3>
        <div class="value">${results.summary.failed}</div>
      </div>
      
      <div class="summary-card">
        <h3>Tasa de Éxito</h3>
        <div class="value">${successRate}%</div>
        <div class="progress-bar">
          <div class="progress-fill" style="width: ${successRate}%"></div>
        </div>
      </div>
    </div>
    
    <div class="tests">
      <h2 style="margin-bottom: 1.5rem; color: #1f2937;">Resultados Detallados</h2>
      
      ${results.tests.map(test => `
        <div class="test-item">
          <div class="test-header">
            <div class="test-status ${test.status}">
              ${test.status === 'passed' ? '✓' : '✗'}
            </div>
            <div class="test-name">${test.name}</div>
            <div class="test-duration">${test.duration}ms</div>
          </div>
          
          <div class="test-message">
            ${test.message}
          </div>
          
          ${test.details ? `
            <div class="test-details">
              <pre>${JSON.stringify(test.details, null, 2)}</pre>
            </div>
          ` : ''}
        </div>
      `).join('')}
    </div>
    
    <div class="footer">
      <p><strong>Usuario:</strong> ${results.user}</p>
      <p><strong>Empresa ID:</strong> ${results.empresa_id}</p>
      <p style="margin-top: 1rem;">
        Para más información, consulta: 
        <a href="PRUEBA_CRM_OPERACIONES.md">PRUEBA_CRM_OPERACIONES.md</a>
      </p>
    </div>
  </div>
</body>
</html>
  `.trim();
}

async function main() {
  console.log('\n╔═══════════════════════════════════════════════════════════╗');
  console.log('║  GENERADOR DE REPORTE: CRM → OPERACIONES                  ║');
  console.log('╚═══════════════════════════════════════════════════════════╝\n');
  
  const email = process.argv[2];
  const password = process.argv[3];
  
  if (!email || !password) {
    console.error('❌ Uso: node generate_report.js <email> <password>');
    process.exit(1);
  }
  
  try {
    console.log('ℹ️  Ejecutando login...');
    const { token, user } = await login(email, password);
    console.log(`✅ Login exitoso: ${user.nombre_completo || user.email}\n`);
    
    console.log('ℹ️  Ejecutando pruebas...');
    const results = await runTests(token, user);
    console.log(`✅ Pruebas completadas: ${results.summary.passed}/${results.summary.total} exitosas\n`);
    
    console.log('ℹ️  Generando reporte HTML...');
    const html = generateHTML(results);
    fs.writeFileSync(OUTPUT_FILE, html, 'utf8');
    console.log(`✅ Reporte generado: ${OUTPUT_FILE}\n`);
    
    const fullPath = path.resolve(OUTPUT_FILE);
    console.log(`📄 Abrir en navegador: file://${fullPath}\n`);
    
    if (results.summary.failed === 0) {
      console.log('🎉 TODAS LAS PRUEBAS PASARON EXITOSAMENTE\n');
      process.exit(0);
    } else {
      console.log('⚠️  ALGUNAS PRUEBAS FALLARON\n');
      process.exit(1);
    }
    
  } catch (error) {
    console.error(`\n❌ ERROR: ${error.message}\n`);
    process.exit(1);
  }
}

main();
