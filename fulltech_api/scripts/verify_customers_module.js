#!/usr/bin/env node

/**
 * Verificación completa del módulo de Clientes Activos
 * Este script verifica toda la cadena: DB -> API -> Frontend
 */

const { PrismaClient } = require('@prisma/client');
const axios = require('axios');

const prisma = new PrismaClient();

async function main() {
  console.log('🔍 VERIFICACIÓN COMPLETA - MÓDULO CLIENTES ACTIVOS');
  console.log('================================================');
  console.log(`Fecha: ${new Date().toISOString()}`);
  console.log('');

  let hasError = false;

  try {
    // 1. Verificar tabla customers existe
    console.log('1️⃣ Verificando tabla customers en base de datos...');
    
    const totalCustomers = await prisma.customer.count({
      where: { deleted_at: null }
    });
    
    console.log(`   ✅ Tabla customers existe`);
    console.log(`   ✅ Total clientes en DB: ${totalCustomers}`);

    if (totalCustomers === 0) {
      console.log('   ⚠️  No hay clientes en la base de datos');
    } else {
      // Mostrar algunos clientes de ejemplo
      const sampleCustomers = await prisma.customer.findMany({
        where: { deleted_at: null },
        select: {
          id: true,
          nombre: true,
          telefono: true,
          tags: true,
          created_at: true
        },
        take: 5
      });

      console.log('   📋 Muestra de clientes:');
      sampleCustomers.forEach((c, i) => {
        console.log(`   ${i+1}. ${c.nombre} - ${c.telefono} - tags: [${c.tags.join(', ')}]`);
      });
    }

    // 2. Verificar clientes con tags 'activo'
    console.log('');
    console.log('2️⃣ Verificando clientes con tag "activo"...');
    
    const activeCustomers = await prisma.customer.findMany({
      where: { 
        deleted_at: null,
        tags: { has: 'activo' }
      },
      select: {
        id: true,
        nombre: true,
        telefono: true,
        tags: true
      }
    });

    console.log(`   ✅ Clientes con tag 'activo': ${activeCustomers.length}`);
    if (activeCustomers.length > 0) {
      console.log('   📋 Clientes activos encontrados:');
      activeCustomers.forEach((c, i) => {
        console.log(`   ${i+1}. ${c.nombre} - ${c.telefono} - tags: [${c.tags.join(', ')}]`);
      });
    }

    // 3. Verificar clientes con tags 'compro'
    console.log('');
    console.log('3️⃣ Verificando clientes con tag "compro"...');
    
    const boughtCustomers = await prisma.customer.findMany({
      where: { 
        deleted_at: null,
        tags: { has: 'compro' }
      },
      select: {
        id: true,
        nombre: true,
        telefono: true,
        tags: true
      }
    });

    console.log(`   ✅ Clientes con tag 'compro': ${boughtCustomers.length}`);
    if (boughtCustomers.length > 0) {
      console.log('   📋 Clientes que compraron:');
      boughtCustomers.forEach((c, i) => {
        console.log(`   ${i+1}. ${c.nombre} - ${c.telefono} - tags: [${c.tags.join(', ')}]`);
      });
    }

    // 4. Probar API endpoint directamente
    console.log('');
    console.log('4️⃣ Probando API /api/customers...');
    
    try {
      // Primero necesitamos hacer login
      console.log('   🔐 Haciendo login...');
      const loginResponse = await axios.post('http://localhost:3000/api/auth/login', {
        email: 'admin@fulltech.com',
        password: 'Admin1234'
      });

      const token = loginResponse.data.token;
      console.log(`   ✅ Login exitoso, token obtenido`);

      // Probar endpoint de customers
      console.log('   📡 Llamando GET /api/customers...');
      const customersResponse = await axios.get('http://localhost:3000/api/customers', {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      console.log(`   ✅ API Response Status: ${customersResponse.status}`);
      console.log(`   ✅ Total items devueltos: ${customersResponse.data.items?.length || 0}`);
      console.log(`   ✅ Stats del API:`);
      if (customersResponse.data.stats) {
        const stats = customersResponse.data.stats;
        console.log(`      - Total Customers: ${stats.totalCustomers}`);
        console.log(`      - Active Customers: ${stats.activeCustomers}`);
        console.log(`      - By Status: ${JSON.stringify(stats.byStatus)}`);
      }

      // Mostrar algunos clientes del API
      if (customersResponse.data.items && customersResponse.data.items.length > 0) {
        console.log('   📋 Muestra de clientes del API:');
        customersResponse.data.items.slice(0, 5).forEach((c, i) => {
          console.log(`   ${i+1}. ${c.fullName} - ${c.phone} - status: ${c.status} - isActive: ${c.isActiveCustomer} - tags: [${c.tags.join(', ')}]`);
        });
      }

    } catch (apiError) {
      console.log(`   ❌ Error en API: ${apiError.message}`);
      if (apiError.response) {
        console.log(`   ❌ Status: ${apiError.response.status}`);
        console.log(`   ❌ Response: ${JSON.stringify(apiError.response.data)}`);
      }
      hasError = true;
    }

    // 5. Verificar empresa_id correcto
    console.log('');
    console.log('5️⃣ Verificando empresa_id...');
    
    const empresas = await prisma.empresa.findMany();
    console.log(`   ✅ Empresas en DB: ${empresas.length}`);
    empresas.forEach((e, i) => {
      console.log(`   ${i+1}. ${e.nombre} (ID: ${e.id})`);
    });

    // Verificar a qué empresa pertenecen los customers
    if (totalCustomers > 0) {
      const customersByEmpresa = await prisma.customer.groupBy({
        by: ['empresa_id'],
        where: { deleted_at: null },
        _count: true
      });

      console.log('   📊 Clientes por empresa:');
      for (const group of customersByEmpresa) {
        const empresa = await prisma.empresa.findUnique({ where: { id: group.empresa_id } });
        console.log(`   - ${empresa?.nombre || 'Unknown'}: ${group._count} clientes`);
      }
    }

  } catch (error) {
    console.log(`❌ Error durante verificación: ${error.message}`);
    hasError = true;
  } finally {
    await prisma.$disconnect();
  }

  // Resultado final
  console.log('');
  console.log('================================================');
  if (hasError) {
    console.log('❌ VERIFICACIÓN FALLÓ - Se encontraron problemas');
    process.exit(1);
  } else {
    console.log('✅ VERIFICACIÓN COMPLETADA - Revisar resultados arriba');
    process.exit(0);
  }
}

main().catch(console.error);