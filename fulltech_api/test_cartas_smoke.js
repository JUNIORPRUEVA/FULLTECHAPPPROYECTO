#!/usr/bin/env node

/**
 * Smoke test: Cartas (Presupuesto)
 *
 * Requisitos:
 * - Backend corriendo
 * - Token de autenticación válido
 * - Una cotización (quotation) existente para usar como presupuestoId/cotizacionId
 * - Para evitar llamada real a OpenAI: iniciar backend con OPENAI_MOCK=true
 *
 * Uso:
 *   node test_cartas_smoke.js <AUTH_TOKEN> <COTIZACION_ID>
 */

const API_BASE = process.env.API_BASE || 'http://localhost:3000/api';
const TOKEN = process.argv[2];
const QUOTATION_ID = process.argv[3];

if (!TOKEN || !QUOTATION_ID) {
  console.error('❌ Uso: node test_cartas_smoke.js <AUTH_TOKEN> <COTIZACION_ID>');
  process.exit(1);
}

const headers = {
  Authorization: `Bearer ${TOKEN}`,
  'Content-Type': 'application/json',
};

async function request(method, path, body) {
  const url = `${API_BASE}${path}`;
  console.log(`\n➡️  ${method} ${path}`);

  const options = { method, headers };
  if (body) {
    options.body = JSON.stringify(body);
    console.log('   Body:', JSON.stringify(body, null, 2));
  }

  const res = await fetch(url, options);
  const text = await res.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    data = text;
  }

  if (!res.ok) {
    console.log(`   ❌ ${res.status}:`, data);
    return { ok: false, status: res.status, data };
  }

  console.log(`   ✅ ${res.status}:`, data);
  return { ok: true, status: res.status, data };
}

async function main() {
  console.log('========================================');
  console.log('🧪 SMOKE TEST: /api/cartas');
  console.log('========================================');
  console.log('API Base:', API_BASE);
  console.log('Quotation/Presupuesto ID:', QUOTATION_ID);
  console.log('Tip: run backend with OPENAI_MOCK=true for deterministic output.');
  console.log('========================================');

  // 1) List (should be empty initially)
  await request('GET', `/cartas?presupuestoId=${encodeURIComponent(QUOTATION_ID)}&limit=5`);

  // 2) Generate
  const gen = await request('POST', '/cartas/generate', {
    presupuestoId: QUOTATION_ID,
    attachQuotation: true,
    cotizacionId: QUOTATION_ID,
    letterType: 'AGRADECIMIENTO',
    subject: 'Agradecimiento por su preferencia',
    userInstructions:
      'Genera una carta breve, formal y cordial. Menciona que adjuntamos la cotización y quedamos atentos a cualquier duda.',
  });

  const cartaId = gen.ok ? gen.data?.item?.id : null;
  if (!cartaId) {
    console.log('\n⚠️  No se pudo generar carta; abortando pasos restantes.');
    process.exit(1);
  }

  // 3) Get
  await request('GET', `/cartas/${encodeURIComponent(cartaId)}`);

  // 4) PDF stream check (status only)
  console.log(`\n➡️  GET /cartas/${cartaId}/pdf (stream)`);
  const pdfRes = await fetch(`${API_BASE}/cartas/${encodeURIComponent(cartaId)}/pdf`, {
    method: 'GET',
    headers,
  });
  console.log(`   ${pdfRes.ok ? '✅' : '❌'} ${pdfRes.status} content-type=${pdfRes.headers.get('content-type')}`);

  // 5) Delete
  await request('DELETE', `/cartas/${encodeURIComponent(cartaId)}`);

  console.log('\n========================================');
  console.log('✅ SMOKE TEST COMPLETADO');
  console.log('========================================');
}

main().catch((e) => {
  console.error('\n❌ Error fatal:', e);
  process.exit(1);
});
