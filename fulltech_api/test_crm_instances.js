#!/usr/bin/env node

/**
 * Script de prueba para CRM Multi-Instancia
 * 
 * Requisitos:
 * - Backend corriendo
 * - Token de autenticación válido
 * - Al menos un usuario en la base de datos
 * 
 * Uso:
 *   node test_crm_instances.js <AUTH_TOKEN>
 */

const API_BASE = process.env.API_BASE || 'http://localhost:3000/api';
const TOKEN = process.argv[2];

if (!TOKEN) {
  console.error('❌ Token requerido. Uso: node test_crm_instances.js <TOKEN>');
  process.exit(1);
}

const headers = {
  'Authorization': `Bearer ${TOKEN}`,
  'Content-Type': 'application/json',
};

async function request(method, path, body) {
  const url = `${API_BASE}${path}`;
  console.log(`\n➡️  ${method} ${path}`);
  
  try {
    const options = {
      method,
      headers,
    };
    
    if (body) {
      options.body = JSON.stringify(body);
      console.log('   Body:', JSON.stringify(body, null, 2));
    }
    
    const response = await fetch(url, options);
    const data = await response.json();
    
    if (!response.ok) {
      console.log(`   ❌ ${response.status}:`, data);
      return { error: data, status: response.status };
    }
    
    console.log(`   ✅ ${response.status}:`, data);
    return { data, status: response.status };
  } catch (error) {
    console.log('   ❌ Error:', error.message);
    return { error: error.message };
  }
}

async function main() {
  console.log('========================================');
  console.log('🧪 TEST: CRM Multi-Instancia');
  console.log('========================================');
  console.log('API Base:', API_BASE);
  console.log('========================================');

  // 1. Listar instancias actuales
  console.log('\n📋 1. Listar instancias del usuario');
  const list1 = await request('GET', '/crm/instances');

  // 2. Obtener instancia activa
  console.log('\n📋 2. Obtener instancia activa');
  const active1 = await request('GET', '/crm/instances/active');

  // 3. Crear una instancia de prueba
  console.log('\n✨ 3. Crear instancia de prueba');
  const createResult = await request('POST', '/crm/instances', {
    nombre_instancia: 'test_instance_' + Date.now(),
    evolution_base_url: 'https://evolution-api-test.com',
    evolution_api_key: 'TEST_KEY_' + Math.random().toString(36).substring(7),
  });

  if (createResult.error) {
    console.log('\n⚠️  No se pudo crear instancia (puede que ya exista una)');
  }

  const instanceId = createResult.data?.item?.id;

  // 4. Listar instancias después de crear
  console.log('\n📋 4. Listar instancias después de crear');
  await request('GET', '/crm/instances');

  // 5. Obtener instancia activa actualizada
  console.log('\n📋 5. Obtener instancia activa actualizada');
  await request('GET', '/crm/instances/active');

  // 6. Actualizar instancia (si se creó)
  if (instanceId) {
    console.log('\n✏️  6. Actualizar instancia');
    await request('PATCH', `/crm/instances/${instanceId}`, {
      evolution_base_url: 'https://evolution-api-updated.com',
    });
  }

  // 7. Test de conexión (debe fallar con URL fake)
  console.log('\n🔌 7. Test de conexión');
  await request('POST', '/crm/instances/test-connection', {
    nombre_instancia: 'test',
    evolution_base_url: 'https://fake-evolution-api.com',
    evolution_api_key: 'FAKE_KEY',
  });

  // 8. Listar usuarios disponibles para transferencia
  console.log('\n👥 8. Listar usuarios disponibles para transferencia');
  await request('GET', '/crm/users/transfer-list');

  // 9. Listar chats (debe estar filtrado por instancia)
  console.log('\n💬 9. Listar chats (filtrado por instancia)');
  await request('GET', '/crm/chats?limit=5');

  // 10. Eliminar instancia de prueba (solo si no tiene chats)
  if (instanceId) {
    console.log('\n🗑️  10. Eliminar instancia de prueba');
    await request('DELETE', `/crm/instances/${instanceId}`);
  }

  console.log('\n========================================');
  console.log('✅ TEST COMPLETADO');
  console.log('========================================');
  console.log('\nPróximos pasos:');
  console.log('1. Configurar instancia real en la UI');
  console.log('2. Configurar webhook de Evolution con campo "instance"');
  console.log('3. Enviar mensajes de prueba');
  console.log('4. Verificar aislamiento de datos entre usuarios');
  console.log('========================================');
}

main().catch(error => {
  console.error('\n❌ Error fatal:', error);
  process.exit(1);
});
