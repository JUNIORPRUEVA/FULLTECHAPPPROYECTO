-- Drop lat/lng columns from operations_jobs.
-- Use operations_jobs.location_text and/or customer_address as the plain address (dirección).

ALTER TABLE IF EXISTS operations_jobs
  DROP COLUMN IF EXISTS lat,
  DROP COLUMN IF EXISTS lng;

