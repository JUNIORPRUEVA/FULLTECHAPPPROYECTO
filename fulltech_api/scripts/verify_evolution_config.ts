/**
 * Script para verificar la configuración de Evolution API
 */
import { env } from '../src/config/env';
import axios from 'axios';

async function verifyConfig() {
  console.log('🔍 Verificando configuración de Evolution API\n');
  console.log('='.repeat(60));
  
  // 1. Variables de entorno
  console.log('\n1️⃣ Variables de Entorno:');
  console.log('  EVOLUTION_BASE_URL:', env.EVOLUTION_BASE_URL || '❌ NO CONFIGURADO');
  console.log('  EVOLUTION_API_KEY:', env.EVOLUTION_API_KEY ? '✅ Configurado (oculto)' : '❌ NO CONFIGURADO');
  console.log('  EVOLUTION_INSTANCE:', env.EVOLUTION_INSTANCE || '❌ NO CONFIGURADO');
  console.log('  EVOLUTION_DEFAULT_COUNTRY_CODE:', env.EVOLUTION_DEFAULT_COUNTRY_CODE);
  console.log('  PUBLIC_BASE_URL:', env.PUBLIC_BASE_URL);
  console.log('  DEFAULT_EMPRESA_ID:', env.DEFAULT_EMPRESA_ID || '❌ NO CONFIGURADO');

  if (!env.EVOLUTION_BASE_URL || !env.EVOLUTION_API_KEY || !env.EVOLUTION_INSTANCE) {
    console.error('\n❌ Configuración incompleta!');
    console.error('\nPara configurar Evolution API, asegúrate de tener estas variables:');
    console.error('  EVOLUTION_BASE_URL=https://tu-evolution-api.com');
    console.error('  EVOLUTION_API_KEY=tu-api-key');
    console.error('  EVOLUTION_INSTANCE=tu-instancia');
    console.error('\nEn Easypanel, configúralas en la sección "Environment Variables"');
    process.exit(1);
  }

  // 2. Probar conexión a Evolution API
  console.log('\n2️⃣ Probando conexión a Evolution API...');
  try {
    const baseUrl = env.EVOLUTION_BASE_URL;
    const instance = env.EVOLUTION_INSTANCE;
    
    // Intentar obtener el estado de la instancia
    const response = await axios.get(
      `${baseUrl}/instance/connectionState/${instance}`,
      {
        headers: {
          'apikey': env.EVOLUTION_API_KEY,
          'Content-Type': 'application/json',
        },
        timeout: 10000,
      }
    );

    console.log('  ✅ Conexión exitosa');
    console.log('  Estado:', response.data?.instance?.state || response.data?.state || 'unknown');
    console.log('  Respuesta completa:', JSON.stringify(response.data, null, 2));
    
  } catch (error: any) {
    console.error('  ❌ Error conectando a Evolution API');
    if (error.response) {
      console.error('  Status:', error.response.status);
      console.error('  Data:', error.response.data);
    } else if (error.request) {
      console.error('  No se recibió respuesta del servidor');
      console.error('  Verifica que EVOLUTION_BASE_URL sea correcto:', env.EVOLUTION_BASE_URL);
    } else {
      console.error('  Error:', error.message);
    }
  }

  // 3. Verificar webhook configurado
  console.log('\n3️⃣ Webhook configurado:');
  console.log('  URL esperada:', `${env.PUBLIC_BASE_URL}/webhooks/evolution`);
  console.log('  Verifica en tu panel de Evolution que el webhook apunte a esta URL');

  // 4. Instrucciones
  console.log('\n4️⃣ Próximos pasos:');
  console.log('  ✅ Si todo está correcto, ejecuta: npm run dev');
  console.log('  ✅ Luego prueba enviar: npx tsx scripts/test_evolution_send.ts');
  console.log('  ✅ En la app Flutter, ve a CRM > Configuración (ícono engranaje)');
  console.log('  ✅ Activa "Envío directo a Evolution" y completa los datos');
}

verifyConfig().catch(console.error);
