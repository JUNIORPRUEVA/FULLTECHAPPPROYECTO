import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient({ log: ['error'] });
  try {
    const reg = await prisma.$queryRawUnsafe<
      Array<{ sales: string | null; sale_evidence: string | null; sales_legacy: string | null }>
    >(
      "select to_regclass('public.sales')::text as sales, to_regclass('public.sale_evidence')::text as sale_evidence, to_regclass('public.sales_legacy')::text as sales_legacy",
    );

    const counts = {
      salesRecord: await prisma.salesRecord.count().catch(() => null),
      salesEvidence: await prisma.salesEvidence.count().catch(() => null),
      salesLegacy: await prisma.sale.count().catch(() => null),
    };

    // eslint-disable-next-line no-console
    console.log({ reg: reg?.[0] ?? null, counts });
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e);
  process.exit(1);
});
