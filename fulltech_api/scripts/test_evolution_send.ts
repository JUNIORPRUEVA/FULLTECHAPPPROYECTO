/**
 * Script de prueba para verificar el envío de mensajes via Evolution API
 */
import { EvolutionClient } from '../src/services/evolution/evolution_client';
import { env } from '../src/config/env';

async function testSend() {
  console.log('🧪 Testing Evolution API Send Functionality\n');
  console.log('='.repeat(60));
  console.log('\nConfiguracion:');
  console.log('  EVOLUTION_BASE_URL:', env.EVOLUTION_BASE_URL || '❌ NO CONFIGURADO');
  console.log('  EVOLUTION_API_KEY:', env.EVOLUTION_API_KEY ? '✅ Configurado' : '❌ NO CONFIGURADO');
  console.log('  EVOLUTION_INSTANCE:', env.EVOLUTION_INSTANCE || '❌ NO CONFIGURADO');
  console.log('  DEFAULT_EMPRESA_ID:', env.DEFAULT_EMPRESA_ID || '❌ NO CONFIGURADO');

  if (!env.EVOLUTION_BASE_URL || !env.EVOLUTION_API_KEY || !env.EVOLUTION_INSTANCE) {
    console.error('\n❌ Error: Evolution API no está configurado correctamente');
    console.error('Por favor configura las variables de entorno:');
    console.error('  - EVOLUTION_BASE_URL');
    console.error('  - EVOLUTION_API_KEY');
    console.error('  - EVOLUTION_INSTANCE');
    process.exit(1);
  }

  console.log('\n✅ Configuración correcta\n');

  try {
    const client = new EvolutionClient();
    console.log('📤 Enviando mensaje de prueba...');
    
    // IMPORTANTE: Cambia este número por un número de prueba real
    const testPhone = '18295344286'; // Formato: código país + número
    
    const result = await client.sendText({
      toPhone: testPhone,
      text: '✅ Mensaje de prueba del sistema CRM - FullTech App',
    });

    console.log('\n✅ Mensaje enviado exitosamente!');
    console.log('Message ID:', result.messageId);
    console.log('Response:', result.raw);

    console.log('\n📝 Ahora puedes:');
    console.log('1. Verificar que el mensaje llegó a WhatsApp');
    console.log('2. Responder desde WhatsApp y verificar que llegue al backend');
    console.log('3. Enviar mensajes desde la app Flutter');
    
  } catch (error: any) {
    console.error('\n❌ Error enviando mensaje:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', JSON.stringify(error.response.data, null, 2));
    }
    process.exit(1);
  }
}

testSend();
