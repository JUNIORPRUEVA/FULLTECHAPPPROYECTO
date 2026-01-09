const { Client } = require('pg');

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('DATABASE_URL is missing');
  }

  const client = new Client({ connectionString: databaseUrl });
  await client.connect();

  try {
    const cols = await client.query(
      "SELECT column_name, data_type FROM information_schema.columns WHERE table_schema='public' AND table_name='operations_jobs' AND column_name IN ('chat_id','address_text','gps_lat','gps_lng','product_id','service_id','vendedor_user_id','technician_user_id','scheduled_at','reservation_at','warranty_start_date','warranty_end_date','warranty_months','product_serial','issue_details','resolution_due_at','completed_at') ORDER BY column_name",
    );

    const idx = await client.query(
      "SELECT indexname FROM pg_indexes WHERE schemaname='public' AND tablename='operations_jobs' AND indexname IN ('operations_jobs_chat_id_unique','operations_jobs_empresa_status_idx','operations_jobs_chat_id_idx','operations_jobs_scheduled_at_idx','operations_jobs_reservation_at_idx','operations_jobs_resolution_due_at_idx') ORDER BY indexname",
    );

    console.log(
      JSON.stringify(
        {
          columns: cols.rows,
          indexes: idx.rows.map((r) => r.indexname),
        },
        null,
        2,
      ),
    );
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
