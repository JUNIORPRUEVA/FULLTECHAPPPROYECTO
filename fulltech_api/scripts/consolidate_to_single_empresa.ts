import 'dotenv/config';

import { PrismaClient } from '@prisma/client';

type Args = {
  targetEmpresaId?: string;
  dryRun: boolean;
};

type EmpresaRow = { id: string; nombre: string; created_at: Date };
type CountByEmpresaRow = { empresa_id: string; _count: { _all: number } };

function parseArgs(argv: string[]): Args {
  const args: Args = { dryRun: true };

  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];

    if (token === '--apply') {
      args.dryRun = false;
      continue;
    }
    if (token === '--dry-run') {
      args.dryRun = true;
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

function shortId(id: string) {
  return id.slice(0, 8);
}

function isMissingTableError(e: any): boolean {
  // Prisma throws P2021 for "table does not exist".
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

  const envTarget = process.env.DEFAULT_EMPRESA_ID;
  const targetEmpresaId = args.targetEmpresaId ?? envTarget;

  if (!targetEmpresaId) {
    throw new Error(
      'Missing target empresa id. Provide --target <uuid> or set DEFAULT_EMPRESA_ID in env.',
    );
  }

  try {
    const targetEmpresa = await prisma.empresa.findUnique({
      where: { id: targetEmpresaId },
      select: { id: true, nombre: true, created_at: true },
    });

    if (!targetEmpresa) {
      throw new Error(`Target Empresa not found: ${targetEmpresaId}`);
    }

    const empresas: EmpresaRow[] = await prisma.empresa.findMany({
      select: { id: true, nombre: true, created_at: true },
      orderBy: { created_at: 'asc' },
    });

    const otherEmpresaIds = empresas
      .map((e) => e.id)
      .filter((id) => id !== targetEmpresaId);

    const counts: Record<string, number> = {
      empresa: empresas.length,
      usuario: await safe(() => prisma.usuario.count(), 0),
      company_settings: await safe(() => prisma.companySettings.count(), 0),
      cliente: await safe(() => prisma.cliente.count(), 0),
      venta: await safe(() => prisma.venta.count(), 0),
      categoria_producto: await safe(() => prisma.categoriaProducto.count(), 0),
      producto: await safe(() => prisma.producto.count(), 0),
      customers: await safe(() => prisma.customer.count(), 0),
      crm_threads: await safe(() => prisma.crmThread.count(), 0),
      crm_messages: await safe(() => prisma.crmMessage.count(), 0),
      crm_tasks: await safe(() => prisma.crmTask.count(), 0),
      sales: await safe(() => prisma.sale.count(), 0),
    };

    const byEmpresa = {
      usuario: await safe<CountByEmpresaRow[]>(
        () => prisma.usuario.groupBy({ by: ['empresa_id'], _count: { _all: true } }) as any,
        [],
      ),
      clientes: await safe<CountByEmpresaRow[]>(
        () => prisma.cliente.groupBy({ by: ['empresa_id'], _count: { _all: true } }) as any,
        [],
      ),
      ventas: await safe<CountByEmpresaRow[]>(
        () => prisma.venta.groupBy({ by: ['empresa_id'], _count: { _all: true } }) as any,
        [],
      ),
      categorias: await safe<CountByEmpresaRow[]>(
        () =>
          prisma.categoriaProducto.groupBy({ by: ['empresa_id'], _count: { _all: true } }) as any,
        [],
      ),
      productos: await safe<CountByEmpresaRow[]>(
        () => prisma.producto.groupBy({ by: ['empresa_id'], _count: { _all: true } }) as any,
        [],
      ),
      customers: await safe<CountByEmpresaRow[]>(
        () => prisma.customer.groupBy({ by: ['empresa_id'], _count: { _all: true } }) as any,
        [],
      ),
      threads: await safe<CountByEmpresaRow[]>(
        () => prisma.crmThread.groupBy({ by: ['empresa_id'], _count: { _all: true } }) as any,
        [],
      ),
      messages: await safe<CountByEmpresaRow[]>(
        () => prisma.crmMessage.groupBy({ by: ['empresa_id'], _count: { _all: true } }) as any,
        [],
      ),
      tasks: await safe<CountByEmpresaRow[]>(
        () => prisma.crmTask.groupBy({ by: ['empresa_id'], _count: { _all: true } }) as any,
        [],
      ),
      sales: await safe<CountByEmpresaRow[]>(
        () => prisma.sale.groupBy({ by: ['empresa_id'], _count: { _all: true } }) as any,
        [],
      ),
    };

    console.log(
      JSON.stringify(
        {
          ok: true,
          dryRun: args.dryRun,
          targetEmpresa,
          counts,
          byEmpresa,
          otherEmpresas: empresas
            .filter((e) => e.id !== targetEmpresaId)
            .map((e) => ({ id: e.id, nombre: e.nombre, created_at: e.created_at })),
        },
        null,
        2,
      ),
    );

    if (args.dryRun) {
      console.log('\nDRY RUN: no changes applied. Use --apply to perform migration.');
      return;
    }

    // 1) CompanySettings: empresa_id is unique. Keep target if exists, otherwise move the oldest one.
    const targetSettings = await safe<
      { id: string; empresa_id: string; updated_at: Date } | null
    >(
      () =>
        prisma.companySettings.findUnique({
          where: { empresa_id: targetEmpresaId },
          select: { id: true, empresa_id: true, updated_at: true },
        }),
      null,
    );

    if (targetSettings) {
      await safe(
        () =>
          prisma.companySettings.deleteMany({
            where: { empresa_id: { in: otherEmpresaIds } },
          }),
        { count: 0 },
      );
    } else {
      const oldest = await safe<{ id: string; empresa_id: string } | null>(
        () =>
          prisma.companySettings.findFirst({
            where: { empresa_id: { in: otherEmpresaIds } },
            orderBy: { created_at: 'asc' },
            select: { id: true, empresa_id: true },
          }),
        null,
      );

      if (oldest) {
        await safe(
          () =>
            prisma.companySettings.update({
              where: { id: oldest.id },
              data: { empresa_id: targetEmpresaId },
            }),
          null as any,
        );

        await safe(
          () =>
            prisma.companySettings.deleteMany({
              where: { empresa_id: { in: otherEmpresaIds } },
            }),
          { count: 0 },
        );
      }
    }

    // 2) CategoriaProducto: unique(empresa_id, nombre) => rename on conflicts.
    const targetCategoryRows = await safe<Array<{ nombre: string }>>(
      () =>
        prisma.categoriaProducto.findMany({
          where: { empresa_id: targetEmpresaId },
          select: { nombre: true },
        }),
      [],
    );
    const targetCategoryNames = new Set(targetCategoryRows.map((c) => c.nombre.trim()));

    const otherCategories = await safe<
      Array<{ id: string; empresa_id: string; nombre: string }>
    >(
      () =>
        prisma.categoriaProducto.findMany({
          where: { empresa_id: { in: otherEmpresaIds } },
          select: { id: true, empresa_id: true, nombre: true },
        }),
      [],
    );

    for (const cat of otherCategories) {
      const originalName = cat.nombre.trim();
      let newName = originalName;

      if (targetCategoryNames.has(newName)) {
        const base = `${originalName} - MIGRADO ${shortId(cat.empresa_id)}`;
        newName = base;
        let suffix = 2;
        while (targetCategoryNames.has(newName)) {
          newName = `${base} (${suffix})`;
          suffix++;
        }
      }

      await safe(
        () =>
          prisma.categoriaProducto.update({
            where: { id: cat.id },
            data: {
              empresa_id: targetEmpresaId,
              nombre: newName,
            },
          }),
        null as any,
      );

      targetCategoryNames.add(newName);
    }

    // 3) Customers: unique(empresa_id, telefono). Merge duplicates by telefono.
    const dupTelefonos = await safe<Array<{ telefono: string; _count: { _all: number } }>>(
      async () =>
        (await prisma.customer.groupBy({
          by: ['telefono'],
          _count: { _all: true },
        })).filter((g) => g._count._all > 1),
      [],
    );

    for (const row of dupTelefonos) {
      const telefono = row.telefono;
      const all = await safe<Array<{ id: string; empresa_id: string; created_at: Date }>>(
        () =>
          prisma.customer.findMany({
            where: { telefono },
            select: { id: true, empresa_id: true, created_at: true },
            orderBy: { created_at: 'asc' },
          }),
        [],
      );

      if (all.length <= 1) continue;

      const inTarget: (typeof all)[number] | undefined = all.find(
        (c) => c.empresa_id === targetEmpresaId,
      );
      const canonical: (typeof all)[number] = inTarget ?? all[0];

      if (canonical.empresa_id !== targetEmpresaId) {
        await safe(
          () =>
            prisma.customer.update({
              where: { id: canonical.id },
              data: { empresa_id: targetEmpresaId },
            }),
          null as any,
        );
      }

      for (const other of all) {
        if (other.id === canonical.id) continue;

        await safe(
          () =>
            prisma.crmThread.updateMany({
              where: { customer_id: other.id },
              data: { customer_id: canonical.id },
            }),
          { count: 0 },
        );

        await safe(
          () =>
            prisma.sale.updateMany({
              where: { customer_id: other.id },
              data: { customer_id: canonical.id },
            }),
          { count: 0 },
        );

        await safe(() => prisma.customer.delete({ where: { id: other.id } }), null as any);
      }
    }

    // 4) CRM Threads: unique(empresa_id, phone_number). Merge duplicates by phone_number.
    const dupPhones = await safe<
      Array<{ phone_number: string; _count: { _all: number } }>
    >(
      async () =>
        (await prisma.crmThread.groupBy({
          by: ['phone_number'],
          _count: { _all: true },
        })).filter((g) => g._count._all > 1),
      [],
    );

    for (const row of dupPhones) {
      const phone = row.phone_number;
      const threads = await safe<
        Array<{
          id: string;
          empresa_id: string;
          created_at: Date;
          customer_id: string | null;
          assigned_user_id: string | null;
        }>
      >(
        () =>
          prisma.crmThread.findMany({
            where: { phone_number: phone },
            select: {
              id: true,
              empresa_id: true,
              created_at: true,
              customer_id: true,
              assigned_user_id: true,
            },
            orderBy: { created_at: 'asc' },
          }),
        [],
      );

      if (threads.length <= 1) continue;

      const inTarget: (typeof threads)[number] | undefined = threads.find(
        (t) => t.empresa_id === targetEmpresaId,
      );
      const canonical: (typeof threads)[number] = inTarget ?? threads[0];

      if (canonical.empresa_id !== targetEmpresaId) {
        await safe(
          () =>
            prisma.crmThread.update({
              where: { id: canonical.id },
              data: { empresa_id: targetEmpresaId },
            }),
          null as any,
        );
      }

      for (const other of threads) {
        if (other.id === canonical.id) continue;

        // Prefer keeping a customer_id if canonical doesn't have one.
        if (!canonical.customer_id && other.customer_id) {
          await safe(
            () =>
              prisma.crmThread.update({
                where: { id: canonical.id },
                data: { customer_id: other.customer_id },
              }),
            null as any,
          );
        }

        await safe(
          () =>
            prisma.crmMessage.updateMany({
              where: { thread_id: other.id },
              data: { thread_id: canonical.id, empresa_id: targetEmpresaId },
            }),
          { count: 0 },
        );

        await safe(
          () =>
            prisma.crmTask.updateMany({
              where: { thread_id: other.id },
              data: { thread_id: canonical.id, empresa_id: targetEmpresaId },
            }),
          { count: 0 },
        );

        await safe(
          () =>
            prisma.sale.updateMany({
              where: { thread_id: other.id },
              data: { thread_id: canonical.id, empresa_id: targetEmpresaId },
            }),
          { count: 0 },
        );

        await safe(
          () => prisma.crmThread.delete({ where: { id: other.id } }),
          null as any,
        );
      }
    }

    // 5) Bulk move remaining rows to target empresa.
    await safe(
      () =>
        prisma.usuario.updateMany({
          where: { empresa_id: { not: targetEmpresaId } },
          data: { empresa_id: targetEmpresaId },
        }),
      { count: 0 },
    );

    await safe(
      () =>
        prisma.cliente.updateMany({
          where: { empresa_id: { not: targetEmpresaId } },
          data: { empresa_id: targetEmpresaId },
        }),
      { count: 0 },
    );

    await safe(
      () =>
        prisma.venta.updateMany({
          where: { empresa_id: { not: targetEmpresaId } },
          data: { empresa_id: targetEmpresaId },
        }),
      { count: 0 },
    );

    // categories migrated already (record-by-record).

    await safe(
      () =>
        prisma.producto.updateMany({
          where: { empresa_id: { not: targetEmpresaId } },
          data: { empresa_id: targetEmpresaId },
        }),
      { count: 0 },
    );

    await safe(
      () =>
        prisma.customer.updateMany({
          where: { empresa_id: { not: targetEmpresaId } },
          data: { empresa_id: targetEmpresaId },
        }),
      { count: 0 },
    );

    await safe(
      () =>
        prisma.crmThread.updateMany({
          where: { empresa_id: { not: targetEmpresaId } },
          data: { empresa_id: targetEmpresaId },
        }),
      { count: 0 },
    );

    await safe(
      () =>
        prisma.crmMessage.updateMany({
          where: { empresa_id: { not: targetEmpresaId } },
          data: { empresa_id: targetEmpresaId },
        }),
      { count: 0 },
    );

    await safe(
      () =>
        prisma.crmTask.updateMany({
          where: { empresa_id: { not: targetEmpresaId } },
          data: { empresa_id: targetEmpresaId },
        }),
      { count: 0 },
    );

    await safe(
      () =>
        prisma.sale.updateMany({
          where: { empresa_id: { not: targetEmpresaId } },
          data: { empresa_id: targetEmpresaId },
        }),
      { count: 0 },
    );

    const remainingEmpresas: Array<{ id: string; nombre: string }> = await prisma.empresa.findMany({
      select: { id: true, nombre: true },
      orderBy: { created_at: 'asc' },
    });

    const afterByEmpresaUsers = await safe(
      () =>
        prisma.usuario.groupBy({
          by: ['empresa_id'],
          _count: { _all: true },
        }),
      [],
    );

    console.log(
      JSON.stringify(
        {
          ok: true,
          applied: true,
          targetEmpresaId,
          remainingEmpresas,
          usersByEmpresa: afterByEmpresaUsers,
        },
        null,
        2,
      ),
    );
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((e) => {
  console.error('ERR', e?.message ?? String(e));
  process.exit(1);
});
