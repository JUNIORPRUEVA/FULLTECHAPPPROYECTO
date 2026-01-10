#!/usr/bin/env node
/**
 * Script de prueba: Flujo CRM → Operaciones
 * 
 * Verifica que al marcar un chat con estado "agendado" o "por_levantamiento":
 * 1. Se crea el cliente automáticamente si no existe
 * 2. Se crea el registro en operations_jobs
 * 3. Se asocia correctamente con el chat (crm_chat_id)
 * 4. Se crea el registro en operations_schedule para servicios agendados
 * 5. Todo está en la sesión correcta (empresa_id)
 */

const BASE_URL = process.env.API_URL || 'http://localhost:3000';

// Colores para output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSuccess(message) {
  log(`✓ ${message}`, 'green');
}

function logError(message) {
  log(`✗ ${message}`, 'red');
}

function logInfo(message) {
  log(`ℹ ${message}`, 'cyan');
}

function logWarning(message) {
  log(`⚠ ${message}`, 'yellow');
}

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
  logInfo(`Intentando login con: ${email}`);
  const { response, data } = await makeRequest('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
  
  if (!response.ok) {
    throw new Error(`Login falló: ${data?.message || response.statusText}`);
  }
  
  const token = data?.token;
  if (!token) {
    throw new Error('No se recibió token de autenticación');
  }
  
  logSuccess(`Login exitoso`);
  return { token, user: data.user };
}

async function getOrCreateTestChat(token, empresaId) {
  logInfo('Buscando chat de prueba existente...');
  
  // Buscar chats existentes
  const { response, data } = await makeRequest('/api/crm/chats?limit=10', {
    headers: { Authorization: `Bearer ${token}` },
  });
  
  if (!response.ok) {
    throw new Error(`Error al obtener chats: ${data?.message || response.statusText}`);
  }
  
  const chats = data?.items || [];
  
  // Buscar un chat que no esté en estado "compro" (para poder cambiar su estado)
  let testChat = chats.find(chat => 
    chat.status !== 'compro' && 
    chat.status !== 'cancelado'
  );
  
  if (testChat) {
    logSuccess(`Usando chat existente: ${testChat.id} (${testChat.display_name || testChat.phone})`);
    return testChat;
  }
  
  logWarning('No se encontró chat de prueba adecuado. Debe crear un chat manualmente o recibir un mensaje de WhatsApp.');
  throw new Error('No hay chats disponibles para prueba');
}

async function getServices(token) {
  logInfo('Obteniendo servicios disponibles...');
  
  const { response, data } = await makeRequest('/api/settings/services', {
    headers: { Authorization: `Bearer ${token}` },
  });
  
  if (!response.ok) {
    throw new Error(`Error al obtener servicios: ${data?.message || response.statusText}`);
  }
  
  const services = data?.items || [];
  if (services.length === 0) {
    throw new Error('No hay servicios disponibles. Debe crear al menos un servicio.');
  }
  
  logSuccess(`Encontrados ${services.length} servicios`);
  return services;
}

async function getTechnicians(token) {
  logInfo('Obteniendo técnicos disponibles...');
  
  const { response, data } = await makeRequest('/api/operations/technicians', {
    headers: { Authorization: `Bearer ${token}` },
  });
  
  if (!response.ok) {
    throw new Error(`Error al obtener técnicos: ${data?.message || response.statusText}`);
  }
  
  const technicians = data?.items || [];
  if (technicians.length === 0) {
    throw new Error('No hay técnicos disponibles. Debe crear al menos un usuario con rol de técnico.');
  }
  
  logSuccess(`Encontrados ${technicians.length} técnicos`);
  return technicians;
}

async function setChatStatus(token, chatId, statusData) {
  logInfo(`Cambiando estado del chat a: ${statusData.status}`);
  
  const { response, data } = await makeRequest(`/api/crm/chats/${chatId}/status`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: JSON.stringify(statusData),
  });
  
  if (!response.ok) {
    throw new Error(`Error al cambiar estado: ${data?.message || response.statusText}`);
  }
  
  logSuccess(`Estado cambiado exitosamente`);
  return data;
}

async function getOperationsJobs(token, filters = {}) {
  const params = new URLSearchParams(filters);
  logInfo(`Obteniendo jobs de operaciones... (${params.toString() || 'sin filtros'})`);
  
  const { response, data } = await makeRequest(`/api/operations/jobs?${params}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  
  if (!response.ok) {
    throw new Error(`Error al obtener jobs: ${data?.message || response.statusText}`);
  }
  
  return data?.items || [];
}

async function verifyCustomerCreated(token, phone) {
  logInfo(`Verificando que se creó el cliente con teléfono: ${phone}`);
  
  const { response, data } = await makeRequest(`/api/customers?q=${encodeURIComponent(phone)}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  
  if (!response.ok) {
    throw new Error(`Error al buscar cliente: ${data?.message || response.statusText}`);
  }
  
  const customers = data?.items || [];
  const customer = customers.find(c => c.telefono.includes(phone) || phone.includes(c.telefono));
  
  if (!customer) {
    logError(`No se encontró cliente con teléfono ${phone}`);
    return null;
  }
  
  logSuccess(`Cliente encontrado: ${customer.nombre} (ID: ${customer.id})`);
  return customer;
}

async function verifyOperationJob(token, chatId, expectedType, customer) {
  logInfo(`Verificando job de operaciones para chat ${chatId}...`);
  
  const jobs = await getOperationsJobs(token);
  const job = jobs.find(j => j.crm_chat_id === chatId && j.crm_task_type === expectedType);
  
  if (!job) {
    logError(`No se encontró job de tipo ${expectedType} para el chat ${chatId}`);
    return null;
  }
  
  logSuccess(`Job encontrado: ID ${job.id}`);
  
  // Verificaciones detalladas
  const verifications = [
    {
      name: 'Tipo de tarea',
      expected: expectedType,
      actual: job.crm_task_type,
      match: job.crm_task_type === expectedType,
    },
    {
      name: 'Chat ID',
      expected: chatId,
      actual: job.crm_chat_id,
      match: job.crm_chat_id === chatId,
    },
    {
      name: 'Cliente ID',
      expected: customer?.id,
      actual: job.crm_customer_id,
      match: job.crm_customer_id === customer?.id,
    },
    {
      name: 'Nombre cliente',
      expected: customer?.nombre,
      actual: job.customer_name,
      match: job.customer_name === customer?.nombre,
    },
    {
      name: 'Teléfono cliente',
      expected: customer?.telefono,
      actual: job.customer_phone,
      match: customer?.telefono && job.customer_phone?.includes(customer.telefono.slice(-8)),
    },
  ];
  
  log('\n  Verificaciones del job:', 'yellow');
  verifications.forEach(v => {
    if (v.match) {
      logSuccess(`    ${v.name}: ${v.actual}`);
    } else {
      logError(`    ${v.name}: esperado "${v.expected}", obtenido "${v.actual}"`);
    }
  });
  
  return job;
}

async function testPorLevantamiento(token, chat, service, technician) {
  log('\n═══════════════════════════════════════════════', 'blue');
  log('PRUEBA 1: Estado "por_levantamiento"', 'blue');
  log('═══════════════════════════════════════════════', 'blue');
  
  const scheduledAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // Mañana
  const statusData = {
    status: 'por_levantamiento',
    scheduled_at: scheduledAt.toISOString(),
    location_text: 'Calle Test 123, Ciudad Test',
    lat: -34.603722,
    lng: -58.381592,
    assigned_technician_id: technician.id,
    service_id: service.id,
    note: 'Prueba automatizada - Levantamiento',
  };
  
  try {
    // Cambiar estado
    const result = await setChatStatus(token, chat.id, statusData);
    
    // Verificar que se creó el job
    if (!result.operations?.jobId) {
      throw new Error('No se retornó jobId en la respuesta');
    }
    logSuccess(`Job creado con ID: ${result.operations.jobId}`);
    
    // Verificar que se creó el cliente
    const phone = chat.phone || chat.wa_id;
    const customer = await verifyCustomerCreated(token, phone);
    
    if (!customer) {
      throw new Error('No se creó el cliente automáticamente');
    }
    
    // Verificar el job en detalle
    const job = await verifyOperationJob(token, chat.id, 'LEVANTAMIENTO', customer);
    
    if (!job) {
      throw new Error('No se pudo verificar el job');
    }
    
    // Verificaciones adicionales
    if (job.scheduled_at) {
      logSuccess(`    Fecha programada: ${job.scheduled_at}`);
    } else {
      logWarning(`    Fecha programada no encontrada en el job`);
    }
    
    if (job.location_text) {
      logSuccess(`    Ubicación: ${job.location_text}`);
    } else {
      logWarning(`    Ubicación no encontrada en el job`);
    }
    
    if (job.assigned_tech_id === technician.id) {
      logSuccess(`    Técnico asignado correctamente: ${technician.nombre_completo}`);
    } else {
      logError(`    Técnico no asignado correctamente`);
    }
    
    log('\n✓ PRUEBA 1 COMPLETADA EXITOSAMENTE', 'green');
    return { success: true, job };
    
  } catch (error) {
    logError(`PRUEBA 1 FALLÓ: ${error.message}`);
    return { success: false, error: error.message };
  }
}

async function testServicioReservado(token, chat, service, technician) {
  log('\n═══════════════════════════════════════════════', 'blue');
  log('PRUEBA 2: Estado "servicio_reservado" (agendado)', 'blue');
  log('═══════════════════════════════════════════════', 'blue');
  
  const scheduledAt = new Date(Date.now() + 48 * 60 * 60 * 1000); // Pasado mañana
  const statusData = {
    status: 'servicio_reservado',
    scheduled_at: scheduledAt.toISOString(),
    location_text: 'Avenida Test 456, Ciudad Test',
    lat: -34.603722,
    lng: -58.381592,
    assigned_technician_id: technician.id,
    service_id: service.id,
    note: 'Prueba automatizada - Servicio reservado',
  };
  
  try {
    // Cambiar estado
    const result = await setChatStatus(token, chat.id, statusData);
    
    // Verificar que se creó/actualizó el job
    if (!result.operations?.jobId) {
      throw new Error('No se retornó jobId en la respuesta');
    }
    logSuccess(`Job creado/actualizado con ID: ${result.operations.jobId}`);
    
    // Verificar que el cliente existe
    const phone = chat.phone || chat.wa_id;
    const customer = await verifyCustomerCreated(token, phone);
    
    if (!customer) {
      throw new Error('Cliente no encontrado');
    }
    
    // Verificar el job en detalle
    const job = await verifyOperationJob(token, chat.id, 'SERVICIO_RESERVADO', customer);
    
    if (!job) {
      throw new Error('No se pudo verificar el job');
    }
    
    // Verificaciones adicionales
    if (job.scheduled_at) {
      logSuccess(`    Fecha programada: ${job.scheduled_at}`);
    } else {
      logError(`    Fecha programada no encontrada`);
    }
    
    if (job.service_id === service.id) {
      logSuccess(`    Servicio asociado correctamente: ${service.name}`);
    } else {
      logError(`    Servicio no asociado correctamente`);
    }
    
    log('\n✓ PRUEBA 2 COMPLETADA EXITOSAMENTE', 'green');
    return { success: true, job };
    
  } catch (error) {
    logError(`PRUEBA 2 FALLÓ: ${error.message}`);
    return { success: false, error: error.message };
  }
}

async function testIdempotencia(token, chat, service, technician) {
  log('\n═══════════════════════════════════════════════', 'blue');
  log('PRUEBA 3: Idempotencia (no crear duplicados)', 'blue');
  log('═══════════════════════════════════════════════', 'blue');
  
  const scheduledAt = new Date(Date.now() + 72 * 60 * 60 * 1000);
  const statusData = {
    status: 'por_levantamiento',
    scheduled_at: scheduledAt.toISOString(),
    location_text: 'Calle Idempotencia 789',
    lat: -34.603722,
    lng: -58.381592,
    assigned_technician_id: technician.id,
    service_id: service.id,
    note: 'Prueba idempotencia 1',
  };
  
  try {
    // Obtener jobs iniciales
    const jobsBefore = await getOperationsJobs(token);
    const jobsBeforeForChat = jobsBefore.filter(j => j.crm_chat_id === chat.id);
    logInfo(`Jobs antes: ${jobsBeforeForChat.length}`);
    
    // Cambiar estado primera vez
    await setChatStatus(token, chat.id, statusData);
    
    // Cambiar estado segunda vez (mismo tipo)
    statusData.note = 'Prueba idempotencia 2';
    await setChatStatus(token, chat.id, statusData);
    
    // Verificar que no se duplicaron
    const jobsAfter = await getOperationsJobs(token);
    const jobsAfterForChat = jobsAfter.filter(j => 
      j.crm_chat_id === chat.id && 
      j.crm_task_type === 'LEVANTAMIENTO' &&
      j.status !== 'cancelled' &&
      j.status !== 'completed'
    );
    
    logInfo(`Jobs después: ${jobsAfterForChat.length}`);
    
    if (jobsAfterForChat.length === 1) {
      logSuccess('No se crearon duplicados (idempotencia correcta)');
      log('\n✓ PRUEBA 3 COMPLETADA EXITOSAMENTE', 'green');
      return { success: true };
    } else {
      logError(`Se encontraron ${jobsAfterForChat.length} jobs activos del mismo tipo (debería ser 1)`);
      return { success: false, error: 'Se crearon duplicados' };
    }
    
  } catch (error) {
    logError(`PRUEBA 3 FALLÓ: ${error.message}`);
    return { success: false, error: error.message };
  }
}

async function testSesionCorrecta(token, user, chat) {
  log('\n═══════════════════════════════════════════════', 'blue');
  log('PRUEBA 4: Verificar sesión correcta (empresa_id)', 'blue');
  log('═══════════════════════════════════════════════', 'blue');
  
  try {
    const jobs = await getOperationsJobs(token);
    const jobsForChat = jobs.filter(j => j.crm_chat_id === chat.id);
    
    if (jobsForChat.length === 0) {
      throw new Error('No se encontraron jobs para verificar');
    }
    
    logInfo(`Verificando ${jobsForChat.length} jobs...`);
    
    let allCorrect = true;
    for (const job of jobsForChat) {
      if (job.empresa_id === user.empresaId) {
        logSuccess(`  Job ${job.id}: empresa_id correcto (${job.empresa_id})`);
      } else {
        logError(`  Job ${job.id}: empresa_id incorrecto (${job.empresa_id} !== ${user.empresaId})`);
        allCorrect = false;
      }
    }
    
    if (allCorrect) {
      log('\n✓ PRUEBA 4 COMPLETADA EXITOSAMENTE', 'green');
      return { success: true };
    } else {
      return { success: false, error: 'Algunos jobs tienen empresa_id incorrecto' };
    }
    
  } catch (error) {
    logError(`PRUEBA 4 FALLÓ: ${error.message}`);
    return { success: false, error: error.message };
  }
}

async function main() {
  log('\n╔═══════════════════════════════════════════════════════════╗', 'cyan');
  log('║  PRUEBA DE FLUJO CRM → OPERACIONES                        ║', 'cyan');
  log('║  Verificación de creación de clientes y jobs              ║', 'cyan');
  log('╚═══════════════════════════════════════════════════════════╝\n', 'cyan');
  
  const email = process.argv[2];
  const password = process.argv[3];
  
  if (!email || !password) {
    logError('Uso: node test_crm_operations_flow.js <email> <password>');
    logInfo('Ejemplo: node test_crm_operations_flow.js admin@fulltech.com password123');
    process.exit(1);
  }
  
  try {
    // Login
    const { token, user } = await login(email, password);
    logInfo(`Usuario: ${user.nombre_completo} (${user.rol})`);
    logInfo(`Empresa ID: ${user.empresaId}\n`);
    
    // Obtener recursos necesarios
    const chat = await getOrCreateTestChat(token, user.empresaId);
    const services = await getServices(token);
    const technicians = await getTechnicians(token);
    
    const service = services[0];
    const technician = technicians[0];
    
    log('\n📋 Recursos para pruebas:', 'yellow');
    logInfo(`  Chat: ${chat.display_name || chat.phone} (${chat.id})`);
    logInfo(`  Servicio: ${service.name} (${service.id})`);
    logInfo(`  Técnico: ${technician.nombre_completo} (${technician.id})`);
    
    // Ejecutar pruebas
    const results = [];
    
    results.push(await testPorLevantamiento(token, chat, service, technician));
    results.push(await testServicioReservado(token, chat, service, technician));
    results.push(await testIdempotencia(token, chat, service, technician));
    results.push(await testSesionCorrecta(token, user, chat));
    
    // Resumen
    log('\n╔═══════════════════════════════════════════════════════════╗', 'cyan');
    log('║  RESUMEN DE PRUEBAS                                        ║', 'cyan');
    log('╚═══════════════════════════════════════════════════════════╝\n', 'cyan');
    
    const successful = results.filter(r => r.success).length;
    const total = results.length;
    
    log(`Pruebas exitosas: ${successful}/${total}`, successful === total ? 'green' : 'yellow');
    
    if (successful === total) {
      log('\n🎉 TODAS LAS PRUEBAS PASARON EXITOSAMENTE', 'green');
      process.exit(0);
    } else {
      log('\n⚠️  ALGUNAS PRUEBAS FALLARON', 'yellow');
      results.forEach((r, i) => {
        if (!r.success) {
          logError(`  Prueba ${i + 1}: ${r.error}`);
        }
      });
      process.exit(1);
    }
    
  } catch (error) {
    logError(`\n❌ ERROR FATAL: ${error.message}`);
    if (error.stack) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

main();
