#!/usr/bin/env node
/**
 * Script de prueba para validar endpoints de Cotizaciones
 * Ejecutar: node test_cotizaciones.js
 */

const BASE_URL = process.env.API_URL || 'http://localhost:3000';
const TOKEN = process.env.AUTH_TOKEN || 'your-jwt-token-here';

console.log('🧪 PRUEBAS MÓDULO COTIZACIONES\n');
console.log(`Base URL: ${BASE_URL}`);
console.log(`Token: ${TOKEN.substring(0, 20)}...\n`);

const headers = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${TOKEN}`
};

async function testEndpoints() {
  let quotationId = null;
  
  // 1. Listar cotizaciones
  console.log('1️⃣ GET /quotations - Listar cotizaciones');
  try {
    const res = await fetch(`${BASE_URL}/quotations?limit=5`, { headers });
    const data = await res.json();
    console.log(`   ✅ Status: ${res.status}`);
    console.log(`   📊 Total: ${data.total || 0} cotizaciones`);
    if (data.items && data.items.length > 0) {
      quotationId = data.items[0].id;
      console.log(`   📝 Primera cotización ID: ${quotationId}`);
    }
  } catch (e) {
    console.log(`   ❌ Error: ${e.message}`);
  }
  
  // 2. Crear cotización
  console.log('\n2️⃣ POST /quotations - Crear cotización');
  try {
    const newQuotation = {
      customer_name: 'Cliente Prueba',
      customer_phone: '1234567890',
      notes: 'Cotización de prueba',
      itbis_enabled: true,
      itbis_rate: 0.18,
      items: [
        {
          nombre: 'Producto Test',
          cantidad: 2,
          unit_price: 100,
          unit_cost: 50,
          discount_pct: 0
        }
      ]
    };
    
    const res = await fetch(`${BASE_URL}/quotations`, {
      method: 'POST',
      headers,
      body: JSON.stringify(newQuotation)
    });
    const data = await res.json();
    console.log(`   ✅ Status: ${res.status}`);
    if (data.item) {
      quotationId = data.item.id;
      console.log(`   📝 Cotización creada ID: ${quotationId}`);
      console.log(`   💰 Total: ${data.item.total}`);
    }
  } catch (e) {
    console.log(`   ❌ Error: ${e.message}`);
  }
  
  if (!quotationId) {
    console.log('\n⚠️ No hay cotización disponible para probar. Saliendo...');
    return;
  }
  
  // 3. Obtener detalle
  console.log(`\n3️⃣ GET /quotations/${quotationId} - Obtener detalle`);
  try {
    const res = await fetch(`${BASE_URL}/quotations/${quotationId}`, { headers });
    const data = await res.json();
    console.log(`   ✅ Status: ${res.status}`);
    console.log(`   📝 Número: ${data.item?.numero || 'N/A'}`);
    console.log(`   💰 Total: ${data.item?.total || 0}`);
  } catch (e) {
    console.log(`   ❌ Error: ${e.message}`);
  }
  
  // 4. Duplicar
  console.log(`\n4️⃣ POST /quotations/${quotationId}/duplicate - Duplicar`);
  let duplicatedId = null;
  try {
    const res = await fetch(`${BASE_URL}/quotations/${quotationId}/duplicate`, {
      method: 'POST',
      headers
    });
    const data = await res.json();
    console.log(`   ✅ Status: ${res.status}`);
    if (data.item) {
      duplicatedId = data.item.id;
      console.log(`   📝 Cotización duplicada ID: ${duplicatedId}`);
    }
  } catch (e) {
    console.log(`   ❌ Error: ${e.message}`);
  }
  
  // 5. Convertir a ticket
  console.log(`\n5️⃣ POST /quotations/${quotationId}/convert-to-ticket - Convertir a ticket`);
  let ticketId = null;
  try {
    const res = await fetch(`${BASE_URL}/quotations/${quotationId}/convert-to-ticket`, {
      method: 'POST',
      headers
    });
    const data = await res.json();
    console.log(`   ✅ Status: ${res.status}`);
    if (data.ticketId) {
      ticketId = data.ticketId;
      console.log(`   🎫 Ticket creado ID: ${ticketId}`);
    }
  } catch (e) {
    console.log(`   ❌ Error: ${e.message}`);
  }
  
  // 6. Intentar convertir de nuevo (debe fallar)
  console.log(`\n6️⃣ POST /quotations/${quotationId}/convert-to-ticket - Intentar convertir de nuevo`);
  try {
    const res = await fetch(`${BASE_URL}/quotations/${quotationId}/convert-to-ticket`, {
      method: 'POST',
      headers
    });
    const data = await res.json();
    if (res.status === 400) {
      console.log(`   ✅ Error esperado: ${data.message || 'Already converted'}`);
    } else {
      console.log(`   ⚠️ Status inesperado: ${res.status}`);
    }
  } catch (e) {
    console.log(`   ❌ Error: ${e.message}`);
  }
  
  // 7. Eliminar cotización duplicada
  if (duplicatedId) {
    console.log(`\n7️⃣ DELETE /quotations/${duplicatedId} - Eliminar duplicada`);
    try {
      const res = await fetch(`${BASE_URL}/quotations/${duplicatedId}`, {
        method: 'DELETE',
        headers
      });
      console.log(`   ✅ Status: ${res.status}`);
      console.log(`   🗑️ Cotización eliminada`);
    } catch (e) {
      console.log(`   ❌ Error: ${e.message}`);
    }
  }
  
  console.log('\n✅ PRUEBAS COMPLETADAS\n');
  console.log('📋 Resumen:');
  console.log(`   - Cotización de prueba ID: ${quotationId}`);
  console.log(`   - Status: converted`);
  if (ticketId) {
    console.log(`   - Ticket generado ID: ${ticketId}`);
  }
  console.log('');
}

// Ejecutar pruebas
testEndpoints().catch(console.error);
