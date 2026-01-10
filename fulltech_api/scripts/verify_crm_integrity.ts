import { prisma } from '../src/config/prisma';
import { env } from '../src/config/env';

type Check = {
  name: string;
  sql: string;
  params?: any[];
};

async function runCheck(check: Check): Promise<number> {
  const rows = await prisma.$queryRawUnsafe<any[]>(check.sql, ...(check.params ?? []));
  const count = Array.isArray(rows) ? rows.length : 0;
  if (count === 0) {
    console.log(`[OK] ${check.name}`);
    return 0;
  }

  console.error(`[FAIL] ${check.name}: ${count} row(s)`);
  console.error(JSON.stringify(rows.slice(0, 25), null, 2));
  if (count > 25) console.error(`... truncated (${count - 25} more rows)`);
  return 1;
}

async function main() {
  const empresaId = (process.argv[2] ?? env.DEFAULT_EMPRESA_ID ?? '').trim();
  if (!empresaId) {
    throw new Error('Missing empresaId. Provide as argv[2] or set DEFAULT_EMPRESA_ID');
  }

  const checks: Check[] = [
    {
      name: 'Duplicate chats per empresa + wa_id',
      sql: `
        SELECT empresa_id, wa_id, COUNT(*) AS cnt
        FROM crm_chats
        WHERE empresa_id = $1::uuid
        GROUP BY empresa_id, wa_id
        HAVING COUNT(*) > 1
      `,
      params: [empresaId],
    },
    {
      name: 'Duplicate remote_message_id per empresa (non-null)',
      sql: `
        SELECT empresa_id, remote_message_id, COUNT(*) AS cnt
        FROM crm_messages
        WHERE empresa_id = $1::uuid AND remote_message_id IS NOT NULL
        GROUP BY empresa_id, remote_message_id
        HAVING COUNT(*) > 1
      `,
      params: [empresaId],
    },
    {
      name: 'Messages referencing missing chats',
      sql: `
        SELECT m.id, m.chat_id
        FROM crm_messages m
        LEFT JOIN crm_chats c ON c.id = m.chat_id
        WHERE m.empresa_id = $1::uuid AND c.id IS NULL
      `,
      params: [empresaId],
    },
    {
      name: 'Messages empresa_id mismatch vs chat empresa_id',
      sql: `
        SELECT m.id, m.chat_id, m.empresa_id AS msg_empresa_id, c.empresa_id AS chat_empresa_id
        FROM crm_messages m
        JOIN crm_chats c ON c.id = m.chat_id
        WHERE m.empresa_id = $1::uuid AND m.empresa_id <> c.empresa_id
      `,
      params: [empresaId],
    },
    {
      name: 'Chat phone digits mismatch vs wa_id digits',
      sql: `
        SELECT id, empresa_id, wa_id, phone
        FROM crm_chats
        WHERE empresa_id = $1::uuid
          AND phone IS NOT NULL
          AND regexp_replace(wa_id, '\\D', '', 'g') <> regexp_replace(phone, '\\D', '', 'g')
      `,
      params: [empresaId],
    },
  ];

  let failed = 0;
  for (const c of checks) failed += await runCheck(c);

  if (failed) {
    console.error(`CRM integrity checks failed: ${failed} check(s)`);
    process.exit(1);
  }

  console.log('CRM integrity checks: all good');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
