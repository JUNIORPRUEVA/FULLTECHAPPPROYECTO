#!/usr/bin/env node

/**
 * Script para agregar tags 'activo' a algunos clientes existentes
 * para probar el módulo de Clientes Activos
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
  console.log('🔧 ACTUALIZANDO CLIENTES PARA PRUEBA DE MÓDULO ACTIVOS');
  console.log('===================================================');
  
  try {
    // Obtener algunos clientes para actualizar
    const clients = await prisma.customer.findMany({
      where: { deleted_at: null },
      take: 3
    });

    console.log(`Encontrados ${clients.length} clientes para actualizar`);

    for (let i = 0; i < clients.length; i++) {
      const client = clients[i];
      const newTags = [...client.tags];
      
      if (i === 0) {
        // Primer cliente: agregar 'activo'
        if (!newTags.includes('activo')) {
          newTags.push('activo');
        }
      } else if (i === 1) {
        // Segundo cliente: agregar 'compro'
        if (!newTags.includes('compro')) {
          newTags.push('compro');
        }
      } else {
        // Tercer cliente: agregar 'activo'
        if (!newTags.includes('activo')) {
          newTags.push('activo');
        }
      }

      await prisma.customer.update({
        where: { id: client.id },
        data: { tags: newTags }
      });

      console.log(`✅ Actualizado: ${client.nombre} - nuevos tags: [${newTags.join(', ')}]`);
    }

    console.log('');
    console.log('🎉 ACTUALIZACIÓN COMPLETADA');
    console.log('Los clientes ahora deberían aparecer en "Clientes Activos"');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(console.error);