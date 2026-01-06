/*
  Generates a Dart file with SQLite schema definitions based on:
    fulltech_app/lib/offline/schema_snapshot.json

  Output:
    fulltech_app/lib/offline/local_db/generated_schema.dart

  We do NOT attempt to perfectly translate all Postgres constraints.
  Goal: matching tables/columns/types as close as possible in SQLite, plus
  offline helper columns required by spec.
*/

const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function sqliteTypeFromPg(pgType) {
  const t = (pgType || '').toLowerCase();

  if (t.includes('uuid')) return 'TEXT';
  if (t.includes('json')) return 'TEXT';
  if (t.includes('bool')) return 'INTEGER';

  // timestamps / dates: keep TEXT (ISO8601) to match existing app usage.
  if (t.includes('timestamp') || t.includes('timestamptz') || t.includes('date')) return 'TEXT';

  if (t.startsWith('int') || t.includes('serial')) return 'INTEGER';
  if (t.includes('decimal') || t.includes('numeric') || t.includes('real') || t.includes('double')) return 'REAL';

  // arrays -> JSON string
  if (t.endsWith('[]')) return 'TEXT';

  // enums, text, varchar
  return 'TEXT';
}

function sqliteDefaultFromPgDefault(def) {
  if (!def) return null;
  const d = String(def).trim();

  // Common functions
  if (d === 'now()' || d.startsWith('now(')) return "(strftime('%Y-%m-%dT%H:%M:%fZ','now'))";
  if (d.includes('gen_random_uuid')) return null; // client generates UUID

  // jsonb defaults like '{}'::jsonb or '[]'::jsonb
  if (d.includes('::jsonb') || d.includes('::json')) {
    const m = d.match(/^'([\s\S]*)'::jsonb$/i) || d.match(/^'([\s\S]*)'::json$/i);
    if (m) return `'${m[1].replace(/'/g, "''")}'`;
  }

  // boolean defaults
  if (d.toUpperCase() === 'TRUE') return '1';
  if (d.toUpperCase() === 'FALSE') return '0';

  // numeric
  if (/^[0-9]+(\.[0-9]+)?$/.test(d)) return d;

  // string literal
  if (d.startsWith("'") && d.endsWith("'")) return d.replace(/::[a-z0-9_]+$/i, '');

  return null;
}

function helperColumns() {
  // Required helper columns for ALL synced tables
  return [
    { name: '_sync_status', type: 'TEXT', nullable: false, default: "'synced'" },
    { name: '_sync_last_error', type: 'TEXT', nullable: true, default: null },
    // epoch ms default
    { name: '_local_updated_at', type: 'INTEGER', nullable: false, default: "(CAST(strftime('%s','now') AS INTEGER) * 1000)" },
    { name: '_server_updated_at', type: 'INTEGER', nullable: true, default: null },
    { name: '_deleted', type: 'INTEGER', nullable: false, default: '0' },
  ];
}

function quoteIdent(name) {
  // keep exact names; quote if has uppercase or special
  if (/^[a-z_][a-z0-9_]*$/.test(name)) return name;
  return '"' + name.replace(/"/g, '""') + '"';
}

function buildCreateTableSql(table) {
  const name = table.name;
  const pk = table.pk || [];
  const cols = table.columns || [];

  const colLines = [];

  const desired = [];
  for (const c of cols) {
    desired.push({
      name: c.name,
      type: sqliteTypeFromPg(c.type),
      nullable: c.nullable !== false ? true : false,
      default: sqliteDefaultFromPgDefault(c.default),
    });
  }
  for (const hc of helperColumns()) desired.push(hc);

  const desiredColNames = new Set(desired.map((c) => c.name));

  // build pk set
  const pkSet = new Set(pk);

  for (const c of desired) {
    let line = `${quoteIdent(c.name)} ${c.type}`;

    // Primary key for single-column
    if (pk.length === 1 && pkSet.has(c.name)) {
      line += ' PRIMARY KEY';
    }

    if (c.nullable === false && !(pk.length === 1 && pkSet.has(c.name))) {
      line += ' NOT NULL';
    }

    if (c.default != null) {
      line += ` DEFAULT ${c.default}`;
    }

    colLines.push(line);
  }

  // composite pk
  if (pk.length > 1) {
    colLines.push(`PRIMARY KEY (${pk.map(quoteIdent).join(', ')})`);
  }

  // FKs: include only simple ones
  const fks = table.fk || [];
  const seenFk = new Set();
  for (const fk of fks) {
    if (!fk || !fk.column || !fk.refTable || !fk.refColumn) continue;

    // SQLite requires FK column to exist in the same CREATE TABLE statement.
    if (!desiredColNames.has(fk.column)) continue;

    const key = `${fk.column}|${fk.refTable}|${fk.refColumn}`;
    if (seenFk.has(key)) continue;
    seenFk.add(key);

    colLines.push(
      `FOREIGN KEY (${quoteIdent(fk.column)}) REFERENCES ${quoteIdent(fk.refTable)}(${quoteIdent(fk.refColumn)})`,
    );
  }

  const sql = `CREATE TABLE IF NOT EXISTS ${quoteIdent(name)}(\n  ${colLines.join(',\n  ')}\n);`;

  return { sql, desiredColumns: desired };
}

function main() {
  const snapshotPath = path.join(repoRoot, 'fulltech_app', 'lib', 'offline', 'schema_snapshot.json');
  const snapshot = readJson(snapshotPath);

  const tables = snapshot.tables || [];

  const defs = [];
  for (const t of tables) {
    const { sql, desiredColumns } = buildCreateTableSql(t);
    defs.push({ name: t.name, createSql: sql, columns: desiredColumns });
  }

  // Extra local-only tables required by sync spec
  defs.push({
    name: 'sync_outbox',
    createSql: `CREATE TABLE IF NOT EXISTS sync_outbox(\n  id TEXT PRIMARY KEY,\n  entity_table TEXT NOT NULL,\n  entity_id TEXT NOT NULL,\n  operation TEXT NOT NULL,\n  payload TEXT NOT NULL,\n  created_at INTEGER NOT NULL,\n  attempts INTEGER NOT NULL DEFAULT 0,\n  last_error TEXT,\n  next_retry_at INTEGER\n);`,
    columns: [
      { name: 'id', type: 'TEXT', nullable: false, default: null },
      { name: 'entity_table', type: 'TEXT', nullable: false, default: null },
      { name: 'entity_id', type: 'TEXT', nullable: false, default: null },
      { name: 'operation', type: 'TEXT', nullable: false, default: null },
      { name: 'payload', type: 'TEXT', nullable: false, default: null },
      { name: 'created_at', type: 'INTEGER', nullable: false, default: null },
      { name: 'attempts', type: 'INTEGER', nullable: false, default: '0' },
      { name: 'last_error', type: 'TEXT', nullable: true, default: null },
      { name: 'next_retry_at', type: 'INTEGER', nullable: true, default: null },
    ],
  });

  defs.push({
    name: 'sync_state',
    createSql: `CREATE TABLE IF NOT EXISTS sync_state(\n  table_name TEXT PRIMARY KEY,\n  last_pulled_at INTEGER\n);`,
    columns: [
      { name: 'table_name', type: 'TEXT', nullable: false, default: null },
      { name: 'last_pulled_at', type: 'INTEGER', nullable: true, default: null },
    ],
  });

  defs.push({
    name: 'sync_conflicts',
    createSql: `CREATE TABLE IF NOT EXISTS sync_conflicts(\n  id TEXT PRIMARY KEY,\n  entity_table TEXT NOT NULL,\n  entity_id TEXT NOT NULL,\n  conflict_at INTEGER NOT NULL,\n  local_payload TEXT NOT NULL,\n  server_payload TEXT NOT NULL,\n  note TEXT\n);`,
    columns: [
      { name: 'id', type: 'TEXT', nullable: false, default: null },
      { name: 'entity_table', type: 'TEXT', nullable: false, default: null },
      { name: 'entity_id', type: 'TEXT', nullable: false, default: null },
      { name: 'conflict_at', type: 'INTEGER', nullable: false, default: null },
      { name: 'local_payload', type: 'TEXT', nullable: false, default: null },
      { name: 'server_payload', type: 'TEXT', nullable: false, default: null },
      { name: 'note', type: 'TEXT', nullable: true, default: null },
    ],
  });

  // indexes for outbox
  const extraIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_sync_outbox_next_retry_at ON sync_outbox(next_retry_at);',
    'CREATE INDEX IF NOT EXISTS idx_sync_outbox_entity ON sync_outbox(entity_table, entity_id);',
    'CREATE INDEX IF NOT EXISTS idx_sync_outbox_created_at ON sync_outbox(created_at);',
  ];

  const outPath = path.join(repoRoot, 'fulltech_app', 'lib', 'offline', 'local_db', 'generated_schema.dart');
  fs.mkdirSync(path.dirname(outPath), { recursive: true });

  const content = `// GENERATED FILE. Do not edit by hand.\n// Source: fulltech_app/lib/offline/schema_snapshot.json\n\nclass OfflineTableDef {\n  final String name;\n  final String createSql;\n  final List<OfflineColumnDef> columns;\n\n  const OfflineTableDef({required this.name, required this.createSql, required this.columns});\n}\n\nclass OfflineColumnDef {\n  final String name;\n  final String type;\n  final bool nullable;\n  final String? defaultSql;\n\n  const OfflineColumnDef({required this.name, required this.type, required this.nullable, this.defaultSql});\n}\n\nconst offlineTableDefs = <OfflineTableDef>[\n${defs
    .map((t) => {
      const cols = t.columns
        .map((c) =>
          `    OfflineColumnDef(name: '${c.name}', type: '${c.type}', nullable: ${c.nullable ? 'true' : 'false'}, defaultSql: ${c.default == null ? 'null' : `'${String(c.default).replace(/'/g, "\\'")}'`}),`)
        .join('\n');

      return `  OfflineTableDef(\n    name: '${t.name}',\n    createSql: r'''${t.createSql}''',\n    columns: const <OfflineColumnDef>[\n${cols}\n    ],\n  ),`;
    })
    .join('\n')}
];\n\nconst offlineExtraIndexes = <String>[\n${extraIndexes.map((s) => `  r'''${s}''',`).join('\n')}\n];\n`;

  fs.writeFileSync(outPath, content, 'utf8');
  // eslint-disable-next-line no-console
  console.log(`✅ Wrote: ${outPath}`);
  // eslint-disable-next-line no-console
  console.log(`✅ Tables defs: ${defs.length}`);
}

main();
