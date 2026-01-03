import 'dotenv/config';

import { PrismaClient } from '@prisma/client';

function isMissingTableError(e: any): boolean {
  return (
    e?.code === 'P2021' ||
    String(e?.message ?? '').toLowerCase().includes('does not exist')
  );
}

async function safe<T>(fn: () => Promise<T>, fallback: T): Promise<T> {
  try {
    return await fn();
  } catch (e: any) {
    if (isMissingTableError(e)) return fallback;
    throw e;
  }
}

async function main() {
  const prisma = new PrismaClient();
  try {
    const empresas = await prisma.empresa.findMany({
      select: { id: true, nombre: true, created_at: true },
      orderBy: { created_at: 'asc' },
    });

    const groupBy = async (model: any) =>
      safe(() => model.groupBy({ by: ['empresa_id'], _count: { _all: true } }), '(table missing)');

    const out = {
      empresas,
      usuario: await groupBy(prisma.usuario),
      company_settings: await groupBy(prisma.companySettings),
      cliente: await groupBy(prisma.cliente),
      venta: await groupBy(prisma.venta),
      categoria_producto: await groupBy(prisma.categoriaProducto),
      producto: await groupBy(prisma.producto),
      // CRM tables may not exist yet in this DB
      customers: await groupBy(prisma.customer),
      crm_threads: await groupBy(prisma.crmThread),
      crm_messages: await groupBy(prisma.crmMessage),
      crm_tasks: await groupBy(prisma.crmTask),
      sales: await groupBy(prisma.sale),
    };

    console.log(JSON.stringify(out, null, 2));
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((e) => {
  console.error('ERR', e?.message ?? String(e));
  process.exit(1);
});
