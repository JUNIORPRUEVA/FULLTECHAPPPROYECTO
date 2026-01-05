const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

(async () => {
  try {
    const empresas = await prisma.empresa.count();
    const usuarios = await prisma.usuario.count();

    console.log(`DB OK. empresas=${empresas} usuarios=${usuarios}`);

    // Attendance / Ponchado: verify table exists and summarize sync.
    try {
      const punchesTotal = await prisma.punchRecord.count();
      console.log(`punch_records OK. total=${punchesTotal}`);

      const byStatus = await prisma.punchRecord.groupBy({
        by: ['sync_status'],
        _count: { _all: true },
      });

      if (byStatus.length > 0) {
        const summary = byStatus
          .map((row) => `${row.sync_status}:${row._count._all}`)
          .join(' ');
        console.log(`punch_records by sync_status -> ${summary}`);
      }

      const lastPunch = await prisma.punchRecord.findFirst({
        orderBy: { created_at: 'desc' },
        select: {
          id: true,
          empresa_id: true,
          user_id: true,
          type: true,
          datetime_utc: true,
          datetime_local: true,
          timezone: true,
          sync_status: true,
          created_at: true,
        },
      });

      if (lastPunch) {
        console.log('lastPunch=', lastPunch);
      }
    } catch (attendanceErr) {
      console.error(
        'punch_records ERROR (table missing / not migrated yet?):',
        attendanceErr && attendanceErr.message ? attendanceErr.message : attendanceErr,
      );
    }

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
