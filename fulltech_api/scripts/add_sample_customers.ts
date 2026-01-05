import { prisma } from '../src/config/prisma';

async function main() {
  console.log('🔍 Buscando empresa...');
  
  const empresa = await prisma.empresa.findFirst();
  
  if (!empresa) {
    console.error('❌ No hay empresas en la base de datos');
    // @ts-ignore - process is available in Node.js runtime
    process.exitCode = 1;
    return;
  }

  console.log(`✅ Empresa encontrada: ${empresa.nombre} (${empresa.id})`);

  const sampleCustomers = [
    {
      nombre: 'Juan Pérez García',
      telefono: '8091234567',
      email: 'juan.perez@example.com',
      direccion: 'Av. Winston Churchill #1234, Santo Domingo',
      tags: ['vip', 'frecuente'],
      notas: 'Cliente frecuente, prefiere productos de alta gama',
    },
    {
      nombre: 'María Santos López',
      telefono: '8097654321',
      email: 'maria.santos@example.com',
      direccion: 'C/ El Conde #567, Zona Colonial',
      tags: ['nuevo'],
      notas: 'Primera compra realizada en diciembre',
    },
    {
      nombre: 'Carlos Rodríguez',
      telefono: '8092345678',
      email: 'carlos.r@example.com',
      direccion: 'Av. Abraham Lincoln #890, Santo Domingo',
      tags: ['corporativo'],
      notas: 'Compras para empresa',
    },
    {
      nombre: 'Ana Martínez',
      telefono: '8093456789',
      email: null,
      direccion: 'C/ Duarte #123, Santiago',
      tags: ['whatsapp'],
      notas: 'Contacto solo por WhatsApp',
    },
    {
      nombre: 'Luis Fernández',
      telefono: '8094567890',
      email: 'luis.f@example.com',
      direccion: null,
      tags: ['referido'],
      notas: 'Referido por Juan Pérez',
    },
  ];

  console.log('\n📝 Agregando clientes de prueba...\n');

  for (const customer of sampleCustomers) {
    try {
      const existing = await prisma.customer.findUnique({
        where: {
          empresa_id_telefono: {
            empresa_id: empresa.id,
            telefono: customer.telefono,
          },
        },
      });

      if (existing) {
        console.log(`⏭️  ${customer.nombre} (${customer.telefono}) ya existe`);
        continue;
      }

      const created = await prisma.customer.create({
        data: {
          empresa_id: empresa.id,
          ...customer,
        },
      });

      console.log(`✅ ${customer.nombre} (${customer.telefono}) - ID: ${created.id}`);
    } catch (error: any) {
      console.error(`❌ Error creando ${customer.nombre}:`, error.message);
    }
  }

  // Agregar algunas ventas de prueba para los clientes
  console.log('\n💰 Agregando ventas de prueba...\n');

  const customers = await prisma.customer.findMany({
    where: { empresa_id: empresa.id },
    take: 3,
  });

  const products = await prisma.producto.findMany({
    where: { empresa_id: empresa.id },
    take: 5,
  });

  if (customers.length > 0 && products.length > 0) {
    for (let i = 0; i < customers.length; i++) {
      const customer = customers[i];
      const numSales = Math.floor(Math.random() * 3) + 1; // 1-3 ventas

      for (let j = 0; j < numSales; j++) {
        const product = products[Math.floor(Math.random() * products.length)];
        const quantity = Math.floor(Math.random() * 3) + 1;
        const unitPrice = parseFloat(product.precio_venta.toString());
        const total = unitPrice * quantity;

        try {
          await prisma.sale.create({
            data: {
              empresa_id: empresa.id,
              customer_id: customer.id,
              total: total,
              detalles: {
                productos: [
                  {
                    producto_id: product.id,
                    nombre: product.nombre,
                    cantidad: quantity,
                    precio_unitario: unitPrice,
                  }
                ]
              },
              created_at: new Date(
                Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000
              ), // últimos 30 días
            },
          });

          console.log(
            `✅ Venta: ${customer.nombre} - ${product.nombre} (x${quantity}) = $${total.toFixed(2)}`
          );
        } catch (error: any) {
          console.error(`❌ Error creando venta:`, error.message);
        }
      }
    }
  }

  console.log('\n✅ Clientes y ventas de prueba agregados correctamente');
}

main()
  .catch((e) => {
    console.error('❌ Error:', e);
    // @ts-ignore - process is available in Node.js runtime
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
