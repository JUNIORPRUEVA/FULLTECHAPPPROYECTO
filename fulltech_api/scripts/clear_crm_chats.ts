#!/usr/bin/env tsx
/**
 * Script para limpiar todos los chats y mensajes del CRM
 * 
 * Esto eliminará:
 * - Todos los mensajes de CRM (crm_messages)
 * - Todos los chats/threads de CRM (crm_threads)
 * - Metadata de chats (crm_chat_meta)
 * - Eventos de webhooks antiguos (crm_webhook_events - opcional)
 * 
 * Después de ejecutar este script, todos los nuevos chats
 * se guardarán con los números correctos gracias al fix del parser.
 * 
 * PRECAUCIÓN: Esta acción NO SE PUEDE DESHACER
 * 
 * Uso:
 *   npm run clear-crm-chats
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('========================================');
  console.log('[CLEAR_CRM] Iniciando limpieza de CRM');
  console.log('========================================');
  console.log('');
  console.log('⚠️  ADVERTENCIA: Esta acción eliminará TODOS los chats y mensajes del CRM');
  console.log('⚠️  Los datos NO SE PUEDEN RECUPERAR después de esta operación');
  console.log('');
  console.log('Tablas que serán limpiadas:');
  console.log('  - crm_messages (mensajes)');
  console.log('  - crm_chat_meta (metadata de chats)');
  console.log('  - crm_threads (chats/threads)');
  console.log('  - crm_webhook_events (eventos de webhooks - opcional)');
  console.log('');

  // Contar registros actuales
  const messagesCount = await prisma.$queryRaw<[{ count: bigint }]>`
    SELECT COUNT(*) as count FROM crm_messages
  `;
  const threadsCount = await prisma.$queryRaw<[{ count: bigint }]>`
    SELECT COUNT(*) as count FROM crm_threads
  `;
  const webhookEventsCount = await prisma.$queryRaw<[{ count: bigint }]>`
    SELECT COUNT(*) as count FROM crm_webhook_events
  `;

  console.log('📊 Registros actuales:');
  console.log(`  - Mensajes: ${messagesCount[0].count}`);
  console.log(`  - Chats: ${threadsCount[0].count}`);
  console.log(`  - Eventos webhook: ${webhookEventsCount[0].count}`);
  console.log('');

  // Esperar 5 segundos para dar tiempo de cancelar
  console.log('⏳ Esperando 5 segundos antes de continuar...');
  console.log('   Presiona Ctrl+C para cancelar');
  console.log('');
  
  await new Promise(resolve => setTimeout(resolve, 5000));

  console.log('🗑️  Iniciando eliminación...');
  console.log('');

  try {
    // 1. Eliminar mensajes primero (tienen FK a threads)
    console.log('[1/4] Eliminando mensajes (crm_messages)...');
    const deletedMessages = await prisma.$executeRaw`
      DELETE FROM crm_messages
    `;
    console.log(`✅ Eliminados ${deletedMessages} mensajes`);

    // 2. Eliminar metadata de chats
    console.log('[2/4] Eliminando metadata de chats (crm_chat_meta)...');
    const deletedMeta = await prisma.$executeRaw`
      DELETE FROM crm_chat_meta
    `;
    console.log(`✅ Eliminados ${deletedMeta} registros de metadata`);

    // 3. Eliminar threads/chats
    console.log('[3/4] Eliminando chats/threads (crm_threads)...');
    const deletedThreads = await prisma.$executeRaw`
      DELETE FROM crm_threads
    `;
    console.log(`✅ Eliminados ${deletedThreads} chats`);

    // 4. OPCIONAL: Limpiar eventos de webhooks antiguos
    console.log('[4/4] ¿Eliminar eventos de webhooks? (Opcional)');
    console.log('   Los eventos de webhooks son para debugging/auditoría');
    console.log('   Si los eliminas, perderás el historial de webhooks recibidos');
    console.log('');
    console.log('   Eliminando eventos de webhooks más antiguos de 7 días...');
    
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const deletedWebhooks = await prisma.$executeRaw`
      DELETE FROM crm_webhook_events 
      WHERE created_at < ${sevenDaysAgo}
    `;
    console.log(`✅ Eliminados ${deletedWebhooks} eventos de webhooks antiguos`);

    console.log('');
    console.log('========================================');
    console.log('✅ Limpieza completada exitosamente');
    console.log('========================================');
    console.log('');
    console.log('📝 Resumen:');
    console.log(`  - ${deletedMessages} mensajes eliminados`);
    console.log(`  - ${deletedMeta} metadatos eliminados`);
    console.log(`  - ${deletedThreads} chats eliminados`);
    console.log(`  - ${deletedWebhooks} eventos webhook antiguos eliminados`);
    console.log('');
    console.log('🎉 Ahora todos los nuevos chats se guardarán con los números correctos');
    console.log('   gracias al fix del webhook parser implementado anteriormente.');
    console.log('');

  } catch (error) {
    console.error('');
    console.error('❌ ERROR durante la limpieza:');
    console.error(error);
    console.error('');
    console.error('La operación pudo haber fallado parcialmente.');
    console.error('Verifica el estado de la base de datos manualmente.');
    process.exit(1);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
