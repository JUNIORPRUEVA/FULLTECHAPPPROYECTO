-- Enhanced webhook events table
-- This table stores ALL webhook events for debugging and inspection

-- Drop old table if exists and recreate with enhanced fields
DROP TABLE IF EXISTS crm_webhook_events CASCADE;

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
);

-- Index for quick access to recent events
CREATE INDEX idx_webhook_events_created_at ON crm_webhook_events(created_at DESC);
CREATE INDEX idx_webhook_events_event_type ON crm_webhook_events(event_type);
CREATE INDEX idx_webhook_events_processed ON crm_webhook_events(processed) WHERE NOT processed;

COMMENT ON TABLE crm_webhook_events IS 'Stores all webhook events from Evolution API for debugging';
COMMENT ON COLUMN crm_webhook_events.payload IS 'Full JSON payload received';
COMMENT ON COLUMN crm_webhook_events.headers IS 'HTTP headers from the webhook request';
COMMENT ON COLUMN crm_webhook_events.event_type IS 'Parsed event type (message.new, message.status, etc.)';
