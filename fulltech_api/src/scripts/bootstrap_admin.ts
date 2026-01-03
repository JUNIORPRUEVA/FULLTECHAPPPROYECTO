import { prisma } from '../config/prisma';
import '../config/env';
import { hashPassword } from '../services/password';

async function main() {
  const empresaNombre = process.env.EMPRESA_NOMBRE ?? 'FULLTECH';
  const adminEmail = process.env.ADMIN_EMAIL ?? 'admin@fulltech.com';
  const adminPassword = process.env.ADMIN_PASSWORD ?? 'Admin1234';
  const adminName = process.env.ADMIN_NAME ?? 'Admin';

  const empresa =
    (await prisma.empresa.findFirst({ where: { nombre: empresaNombre } })) ??
    (await prisma.empresa.create({ data: { nombre: empresaNombre } }));

  const passwordHash = await hashPassword(adminPassword);

  const existing = await prisma.usuario.findUnique({ where: { email: adminEmail } });

  if (existing) {
    await prisma.usuario.update({
      where: { email: adminEmail },
      data: {
        nombre_completo: adminName,
        rol: 'admin',
        posicion: 'admin',
        empresa_id: empresa.id,
        password_hash: passwordHash,
      },
    });

    // Avoid printing secrets; only confirm identity.
    console.log(`Admin actualizado: ${adminEmail} (empresa: ${empresaNombre})`);
    return;
  }

  await prisma.usuario.create({
    data: {
      email: adminEmail,
      nombre_completo: adminName,
      rol: 'admin',
      posicion: 'admin',
      empresa_id: empresa.id,
      password_hash: passwordHash,
    },
  });

  console.log(`Admin creado: ${adminEmail} (empresa: ${empresaNombre})`);
}

main()
  .catch((err) => {
    console.error('bootstrap_admin failed');
    console.error(err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
