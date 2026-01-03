const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

(async () => {
  try {
    const empresas = await prisma.empresa.count();
    const usuarios = await prisma.usuario.count();

    console.log(`DB OK. empresas=${empresas} usuarios=${usuarios}`);

    if (usuarios > 0) {
      const sampleUser = await prisma.usuario.findFirst({
        select: {
          id: true,
          email: true,
          rol: true,
          estado: true,
          empresa_id: true,
        },
      });
      console.log('sampleUser=', sampleUser);
    }
  } catch (err) {
    console.error('DB ERROR:', err && err.message ? err.message : err);
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
  }
})();
