import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function migrate() {
  try {
    console.log('🔄 Executing migration: crm_webhook_events enhanced');

    // Ensure uuid generator exists
    console.log('  - Ensuring pgcrypto extension...');
    await prisma.$executeRaw`CREATE EXTENSION IF NOT EXISTS pgcrypto`;
    
    // Drop old table
    console.log('  - Dropping old table...');
    await prisma.$executeRaw`DROP TABLE IF EXISTS crm_webhook_events CASCADE`;
    
    // Create new table
    console.log('  - Creating new table...');
    await prisma.$executeRaw`
      CREATE TABLE crm_webhook_events (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        created_at timestamptz NOT NULL DEFAULT now(),
        
        -- Request metadata
        headers jsonb,
        ip_address text,
        user_agent text,
        
        -- Event data
        payload jsonb NOT NULL,
        event_type text,
        source text DEFAULT 'evolution',
        
        -- Processing info
        processed boolean DEFAULT false,
        processed_at timestamptz,
        processing_error text,
        
        -- For debugging
        raw_body text
      )
    `;
    
    // Create indexes
    console.log('  - Creating indexes...');
    await prisma.$executeRaw`CREATE INDEX idx_webhook_events_created_at ON crm_webhook_events(created_at DESC)`;
    await prisma.$executeRaw`CREATE INDEX idx_webhook_events_event_type ON crm_webhook_events(event_type)`;
    await prisma.$executeRaw`CREATE INDEX idx_webhook_events_processed ON crm_webhook_events(processed) WHERE NOT processed`;
    
    // Add comments
    console.log('  - Adding comments...');
    await prisma.$executeRaw`COMMENT ON TABLE crm_webhook_events IS 'Stores all webhook events from Evolution API for debugging'`;
    await prisma.$executeRaw`COMMENT ON COLUMN crm_webhook_events.payload IS 'Full JSON payload received'`;
    await prisma.$executeRaw`COMMENT ON COLUMN crm_webhook_events.headers IS 'HTTP headers from the webhook request'`;
    await prisma.$executeRaw`COMMENT ON COLUMN crm_webhook_events.event_type IS 'Parsed event type (message.new, message.status, etc.)'`;
    
    console.log('✅ Migration executed successfully');
    console.log('');
    console.log('New table: crm_webhook_events');
    console.log('  - Enhanced with headers, ip_address, user_agent');
    console.log('  - Event type detection');
    console.log('  - Processing status tracking');
    console.log('');
    
    // Verify table exists
    const result = await prisma.$queryRaw<Array<{ count: bigint }>>`
      SELECT COUNT(*) as count FROM crm_webhook_events
    `;
    
    console.log(`Current events in table: ${result[0].count}`);
    
    process.exit(0);
  } catch (e) {
    console.error('❌ Migration failed:', e);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

migrate();
