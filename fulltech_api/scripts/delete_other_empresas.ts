import 'dotenv/config';

import { PrismaClient } from '@prisma/client';

type Args = {
  targetEmpresaId?: string;
  apply: boolean;
};

function parseArgs(argv: string[]): Args {
  const args: Args = { apply: false };

  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];

    if (token === '--apply') {
      args.apply = true;
      continue;
    }

    if (token === '--target') {
      const value = argv[i + 1];
      if (!value) throw new Error('Missing value for --target');
      args.targetEmpresaId = value;
      i++;
      continue;
    }

    if (!token.startsWith('--') && !args.targetEmpresaId) {
      args.targetEmpresaId = token;
    }
  }

  return args;
}

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
  const args = parseArgs(process.argv.slice(2));
  const targetEmpresaId = args.targetEmpresaId ?? process.env.DEFAULT_EMPRESA_ID;

  if (!targetEmpresaId) {
    throw new Error(
      'Missing target empresa id. Provide --target <uuid> or set DEFAULT_EMPRESA_ID in env.',
    );
  }

  try {
    const target = await prisma.empresa.findUnique({
      where: { id: targetEmpresaId },
      select: { id: true, nombre: true },
    });

    if (!target) throw new Error(`Target Empresa not found: ${targetEmpresaId}`);

    const empresas = await prisma.empresa.findMany({
      select: { id: true, nombre: true },
      orderBy: { created_at: 'asc' },
    });

    const otherEmpresaIds = empresas.map((e) => e.id).filter((id) => id !== targetEmpresaId);

    const nonTargetCount = async (model: any) =>
      safe(() => model.count({ where: { empresa_id: { not: targetEmpresaId } } }), 0);

    const refs = {
      usuario: await nonTargetCount(prisma.usuario),
      company_settings: await nonTargetCount(prisma.companySettings),
      cliente: await nonTargetCount(prisma.cliente),
      venta: await nonTargetCount(prisma.venta),
      categoria_producto: await nonTargetCount(prisma.categoriaProducto),
      producto: await nonTargetCount(prisma.producto),
      // CRM tables may not exist yet
      customers: await nonTargetCount(prisma.customer),
      crm_threads: await nonTargetCount(prisma.crmThread),
      crm_messages: await nonTargetCount(prisma.crmMessage),
      crm_tasks: await nonTargetCount(prisma.crmTask),
      sales: await nonTargetCount(prisma.sale),
    };

    const blocking = Object.entries(refs).filter(([, v]) => v > 0);

    console.log(
      JSON.stringify(
        {
          ok: true,
          apply: args.apply,
          target,
          otherEmpresas: empresas.filter((e) => e.id !== targetEmpresaId),
          refs,
          canDelete: blocking.length === 0,
          blocking,
        },
        null,
        2,
      ),
    );

    if (!args.apply) {
      console.log('\nDRY RUN: no deletion performed. Use --apply to delete other empresas.');
      return;
    }

    if (blocking.length > 0) {
      throw new Error(
        `Refusing to delete: still have non-target references: ${blocking
          .map(([k, v]) => `${k}=${v}`)
          .join(', ')}`,
      );
    }

    const del = await prisma.empresa.deleteMany({
      where: { id: { in: otherEmpresaIds } },
    });

    const remaining = await prisma.empresa.findMany({
      select: { id: true, nombre: true },
      orderBy: { created_at: 'asc' },
    });

    console.log(JSON.stringify({ ok: true, deletedCount: del.count, remaining }, null, 2));
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((e) => {
  console.error('ERR', e?.message ?? String(e));
  process.exit(1);
});
