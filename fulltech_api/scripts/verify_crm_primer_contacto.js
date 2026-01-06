const { PrismaClient } = require('@prisma/client');

async function main() {
  const prisma = new PrismaClient();
  try {
    const def = await prisma.$queryRawUnsafe(
      "SELECT column_default FROM information_schema.columns WHERE table_schema='public' AND table_name='crm_chats' AND column_name='status'",
    );

    const counts = await prisma.$queryRawUnsafe(
      "SELECT status, COUNT(*)::int AS count FROM crm_chats GROUP BY status ORDER BY count DESC, status ASC",
    );

    const nullOrEmpty = await prisma.$queryRawUnsafe(
      "SELECT COUNT(*)::int AS null_or_empty FROM crm_chats WHERE status IS NULL OR btrim(status) = ''",
    );

    console.log('crm_chats.status default:', def);
    console.log('counts by status:', counts);
    console.log('null_or_empty:', nullOrEmpty);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
