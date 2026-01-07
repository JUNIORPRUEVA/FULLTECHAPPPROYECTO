import dotenv from 'dotenv';
import { Client } from 'pg';

dotenv.config();

async function main() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error('DATABASE_URL is missing');

  const client = new Client({ connectionString: url });
  await client.connect();

  const result = await client.query(
    "select column_name from information_schema.columns where table_name='Producto' and column_name in ('stock_qty','min_stock','max_stock','allow_negative_stock') order by column_name",
  );

  console.log(result.rows);

  await client.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
