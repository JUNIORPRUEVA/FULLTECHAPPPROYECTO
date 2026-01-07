import { prisma } from '../src/config/prisma';

async function main() {
  // This script is intentionally safe/idempotent: it only creates the new WhatsApp CRM tables if missing.
  // It does NOT rename or drop any existing legacy CRM tables.

  await prisma.$executeRawUnsafe(`CREATE EXTENSION IF NOT EXISTS pgcrypto;`);

  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS crm_chats (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      wa_id text NOT NULL UNIQUE,
      display_name text,
      phone text,
      last_message_preview text,
      last_message_at timestamp(3),
      unread_count integer NOT NULL DEFAULT 0,
      status text NOT NULL DEFAULT 'activo',
      created_at timestamp(3) NOT NULL DEFAULT now(),
      updated_at timestamp(3) NOT NULL DEFAULT now()
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS crm_chats_last_message_at_idx
    ON crm_chats (last_message_at);
  `);

  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS crm_messages (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      chat_id uuid NOT NULL REFERENCES crm_chats(id) ON DELETE CASCADE,
      direction text NOT NULL,
      message_type text NOT NULL,
      text text,
      media_url text,
      media_mime text,
      media_size integer,
      media_name text,
      remote_message_id text UNIQUE,
      quoted_message_id text,
      status text NOT NULL DEFAULT 'received',
      error text,
      timestamp timestamp(3) NOT NULL,
      created_at timestamp(3) NOT NULL DEFAULT now()
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS crm_messages_chat_id_timestamp_idx
    ON crm_messages (chat_id, timestamp DESC);
  `);

  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS crm_webhook_events (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      event_id text NOT NULL UNIQUE,
      payload jsonb NOT NULL,
      created_at timestamp(3) NOT NULL DEFAULT now()
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS quick_replies (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      title text NOT NULL,
      category text NOT NULL,
      content text NOT NULL,
      is_active boolean NOT NULL DEFAULT TRUE,
      created_at timestamp(3) NOT NULL DEFAULT now(),
      updated_at timestamp(3) NOT NULL DEFAULT now()
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS quick_replies_category_idx
    ON quick_replies (category);
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS quick_replies_is_active_idx
    ON quick_replies (is_active);
  `);

  // Extra metadata for chats (CRM management) without changing Prisma models.
  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS crm_chat_meta (
      chat_id uuid PRIMARY KEY REFERENCES crm_chats(id) ON DELETE CASCADE,
      important boolean NOT NULL DEFAULT FALSE,
      follow_up boolean NOT NULL DEFAULT FALSE,
      product_id text,
      internal_note text,
      assigned_user_id uuid,
      created_at timestamp(3) NOT NULL DEFAULT now(),
      updated_at timestamp(3) NOT NULL DEFAULT now()
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS crm_chat_meta_product_id_idx
    ON crm_chat_meta (product_id);
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS crm_chat_meta_important_idx
    ON crm_chat_meta (important);
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS crm_chat_meta_follow_up_idx
    ON crm_chat_meta (follow_up);
  `);

  // eslint-disable-next-line no-console
  console.log(
    '✅ WhatsApp CRM tables ensured: crm_chats, crm_messages, crm_webhook_events, crm_chat_meta, quick_replies',
  );
}

main()
  .catch((e) => {
    // eslint-disable-next-line no-console
    console.error('❌ Failed creating WhatsApp CRM tables', e);
    // @ts-ignore - process is available in Node.js runtime
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
