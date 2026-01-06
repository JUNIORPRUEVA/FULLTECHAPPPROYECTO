/*
  Generates: fulltech_app/lib/offline/schema_snapshot.json

  Sources:
   - fulltech_api/prisma/schema.prisma (Prisma datamodel)
   - fulltech_api/sql/*.sql (DDL scripts)
   - fulltech_api/scripts/*.ts (raw SQL strings)

  NOTE:
   - This is a best-effort structural extractor based only on repo sources.
   - It does not require a live database.
*/

const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');

function readText(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

function listFiles(dir, predicate) {
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir)
    .map((name) => path.join(dir, name))
    .filter((p) => fs.statSync(p).isFile())
    .filter((p) => (predicate ? predicate(p) : true));
}

function normalizeWhitespace(s) {
  return s.replace(/\r\n/g, '\n');
}

function stripInlineComment(line) {
  // removes -- comment, but keeps if inside quotes (simple heuristic)
  const idx = line.indexOf('--');
  if (idx === -1) return line;
  const before = line.slice(0, idx);
  const quotes = (before.match(/'/g) || []).length;
  if (quotes % 2 === 1) return line;
  return before;
}

function parsePrismaSchema(prismaText) {
  const text = normalizeWhitespace(prismaText);
  const models = [];

  const modelRe = /^model\s+(\w+)\s*\{([\s\S]*?)^\}/gm;
  let match;
  while ((match = modelRe.exec(text))) {
    const modelName = match[1];
    const body = match[2];
    const lines = body
      .split('\n')
      .map((l) => l.trim())
      .filter((l) => l.length > 0 && !l.startsWith('//'));

    let tableName = modelName;
    const columns = [];
    const pk = [];
    const unique = [];
    const indexes = [];
    const fks = [];

    // gather block attributes
    for (const line of lines) {
      if (line.startsWith('@@map(')) {
        const m = line.match(/@@map\("([^"]+)"\)/);
        if (m) tableName = m[1];
      }
      if (line.startsWith('@@unique(')) {
        unique.push({ raw: line });
      }
      if (line.startsWith('@@index(')) {
        indexes.push({ raw: line });
      }
      if (line.startsWith('@@id(')) {
        // composite pk
        const m = line.match(/@@id\(\[([^\]]+)\]/);
        if (m) {
          const fields = m[1]
            .split(',')
            .map((s) => s.trim())
            .filter(Boolean);
          for (const f of fields) pk.push(f);
        }
      }
    }

    // parse fields
    for (const line of lines) {
      if (line.startsWith('@@')) continue;
      if (line.startsWith('//')) continue;

      // Field format: name Type? @attr ...
      // Example: nombre_completo String   @map("name")
      const m = line.match(/^(\w+)\s+([\w\[\]]+)(\?)?\s*(.*)$/);
      if (!m) continue;

      const fieldName = m[1];
      const fieldType = m[2];
      const isNullable = Boolean(m[3]);
      const attrs = m[4] || '';

      // Skip relation fields that are object types without scalar mapping.
      // Heuristic: if type starts with uppercase letter and there's no @db., treat as relation object field.
      const isScalarArray = fieldType.endsWith('[]') && /^[A-Z]/.test(fieldType.replace(/\[\]$/, '')) === false;
      const isRelationObject = /^[A-Z]/.test(fieldType.replace(/\[\]$/, '')) && !attrs.includes('@db.') && !attrs.includes('@id');
      if (isRelationObject) {
        // Extract fk info from @relation(...) if present on the object field.
        const rel = attrs.match(/@relation\(.*fields:\s*\[([^\]]+)\].*references:\s*\[([^\]]+)\]/);
        if (rel) {
          const fkFields = rel[1].split(',').map((s) => s.trim()).filter(Boolean);
          const refFields = rel[2].split(',').map((s) => s.trim()).filter(Boolean);
          const refTable = fieldType.replace(/\[\]$/, '');
          for (let i = 0; i < Math.min(fkFields.length, refFields.length); i++) {
            fks.push({ column: fkFields[i], refTable, refColumn: refFields[i], raw: line });
          }
        }
        continue;
      }

      let columnName = fieldName;
      const mapMatch = attrs.match(/@map\("([^"]+)"\)/);
      if (mapMatch) columnName = mapMatch[1];

      const isId = attrs.includes('@id');
      if (isId) pk.push(columnName);

      const isUnique = attrs.includes('@unique');
      if (isUnique) unique.push({ columns: [columnName], raw: line });

      // Determine postgres-ish type string
      let pgType = null;
      const dbAttr = attrs.match(/@db\.([A-Za-z0-9_]+)(\(([^)]*)\))?/);
      if (dbAttr) {
        const dbType = dbAttr[1];
        const dbArgs = dbAttr[3];
        if (dbArgs) pgType = `${dbType.toLowerCase()}(${dbArgs})`;
        else pgType = dbType.toLowerCase();
      } else {
        const base = fieldType.replace(/\[\]$/, '');
        switch (base) {
          case 'String':
            pgType = fieldType.endsWith('[]') ? 'text[]' : 'text';
            break;
          case 'Int':
            pgType = 'int4';
            break;
          case 'Boolean':
            pgType = 'boolean';
            break;
          case 'DateTime':
            pgType = 'timestamptz';
            break;
          case 'Decimal':
            pgType = 'numeric';
            break;
          case 'Json':
            pgType = 'jsonb';
            break;
          default:
            // enums etc
            pgType = base;
        }
      }

      // defaults
      let def = null;
      const defMatch = attrs.match(/@default\(([^)]+)\)/);
      if (defMatch) def = defMatch[1];
      const updatedAt = attrs.includes('@updatedAt');
      if (updatedAt) def = def ? `${def}; updatedAt` : 'updatedAt';

      columns.push({ name: columnName, type: pgType, nullable: isNullable, default: def });
    }

    // Deduplicate pk entries
    const pkDedup = Array.from(new Set(pk));

    models.push({
      name: tableName,
      source: { kind: 'prisma', model: modelName },
      pk: pkDedup,
      columns,
      unique,
      indexes,
      fk: fks,
    });
  }

  return models;
}

function extractSqlBlocksFromText(text) {
  const blocks = [];
  const norm = normalizeWhitespace(text);

  // Capture CREATE TABLE statements while correctly handling nested parentheses
  // like DEFAULT now() or functions in CHECK constraints.
  const upper = norm.toUpperCase();
  let searchFrom = 0;
  while (true) {
    const idx = upper.indexOf('CREATE TABLE', searchFrom);
    if (idx === -1) break;

    // Find table name after CREATE TABLE [IF NOT EXISTS]
    let i = idx + 'CREATE TABLE'.length;
    while (i < norm.length && /\s/.test(norm[i])) i++;

    // Optional IF NOT EXISTS
    if (upper.slice(i, i + 'IF NOT EXISTS'.length) === 'IF NOT EXISTS') {
      i += 'IF NOT EXISTS'.length;
      while (i < norm.length && /\s/.test(norm[i])) i++;
    }

    // Table identifier: either quoted "..." or bare word
    let tableRaw = '';
    if (norm[i] === '"') {
      const end = norm.indexOf('"', i + 1);
      if (end === -1) {
        searchFrom = idx + 1;
        continue;
      }
      tableRaw = norm.slice(i, end + 1);
      i = end + 1;
    } else {
      const start = i;
      while (i < norm.length && /[A-Za-z0-9_]/.test(norm[i])) i++;
      tableRaw = norm.slice(start, i);
    }

    // Find opening paren
    while (i < norm.length && /\s/.test(norm[i])) i++;
    if (norm[i] !== '(') {
      searchFrom = idx + 1;
      continue;
    }

    const bodyStart = i + 1;
    i++; // consume '('
    let depth = 1;
    let inSingleQuote = false;
    let inDoubleQuote = false;
    for (; i < norm.length; i++) {
      const ch = norm[i];
      const prev = i > 0 ? norm[i - 1] : '';

      if (!inDoubleQuote && ch === "'" && prev !== '\\') {
        inSingleQuote = !inSingleQuote;
        continue;
      }
      if (!inSingleQuote && ch === '"' && prev !== '\\') {
        inDoubleQuote = !inDoubleQuote;
        continue;
      }
      if (inSingleQuote || inDoubleQuote) continue;

      if (ch === '(') depth++;
      else if (ch === ')') depth--;

      if (depth === 0) break;
    }

    if (depth !== 0) {
      searchFrom = idx + 1;
      continue;
    }

    const bodyEnd = i; // points to ')'
    const body = norm.slice(bodyStart, bodyEnd);

    // Consume until semicolon (best-effort)
    let stmtEnd = i + 1;
    while (stmtEnd < norm.length && norm[stmtEnd] !== ';') stmtEnd++;
    if (stmtEnd < norm.length && norm[stmtEnd] === ';') stmtEnd++;

    const raw = norm.slice(idx, stmtEnd);
    blocks.push({ kind: 'create_table', tableRaw, body, raw });
    searchFrom = stmtEnd;
  }

  let m;

  const alterAddColumnRe = /ALTER\s+TABLE\s+(IF\s+EXISTS\s+)?("?[A-Za-z0-9_]+"?)\s+ADD\s+COLUMN\s+(IF\s+NOT\s+EXISTS\s+)?([^;]+);/gim;
  while ((m = alterAddColumnRe.exec(norm))) {
    blocks.push({ kind: 'alter_add_column', tableRaw: m[2], clause: m[4].trim(), raw: m[0] });
  }

  const createIndexRe = /CREATE\s+INDEX\s+(IF\s+NOT\s+EXISTS\s+)?("?[A-Za-z0-9_]+"?)\s+ON\s+("?[A-Za-z0-9_]+"?)\s*\(([^)]+)\)(\s+WHERE\s+[^;]+)?;/gim;
  while ((m = createIndexRe.exec(norm))) {
    blocks.push({
      kind: 'create_index',
      indexName: m[2],
      tableRaw: m[3],
      columnsRaw: m[4],
      whereRaw: m[5] ? m[5].trim() : null,
      raw: m[0],
    });
  }

  const alterAddFkRe = /ALTER\s+TABLE\s+(ONLY\s+)?("?[A-Za-z0-9_]+"?)\s+ADD\s+CONSTRAINT\s+"?[A-Za-z0-9_]+"?\s+FOREIGN\s+KEY\s*\(([^)]+)\)\s+REFERENCES\s+("?[A-Za-z0-9_]+"?)\s*\(([^)]+)\)/gim;
  while ((m = alterAddFkRe.exec(norm))) {
    blocks.push({
      kind: 'alter_add_fk',
      tableRaw: m[2],
      columnsRaw: m[3],
      refTableRaw: m[4],
      refColumnsRaw: m[5],
      raw: m[0],
    });
  }

  return blocks;
}

function unquoteIdent(raw) {
  if (!raw) return raw;
  const s = raw.trim();
  if (s.startsWith('"') && s.endsWith('"')) return s.slice(1, -1);
  return s;
}

function parseSqlCreateTable(block) {
  const tableName = unquoteIdent(block.tableRaw);
  const bodyLines = normalizeWhitespace(block.body)
    .split('\n')
    .map((l) => stripInlineComment(l).trim())
    .filter((l) => l.length > 0);

  const columns = [];
  const pk = [];
  const unique = [];
  const fk = [];

  for (let line of bodyLines) {
    // remove trailing comma
    line = line.replace(/,$/, '').trim();
    if (!line) continue;

    // table-level constraints
    if (/^PRIMARY\s+KEY\s*\(/i.test(line)) {
      const m = line.match(/^PRIMARY\s+KEY\s*\(([^)]+)\)/i);
      if (m) {
        m[1]
          .split(',')
          .map((s) => unquoteIdent(s))
          .map((s) => s.trim())
          .filter(Boolean)
          .forEach((c) => pk.push(c));
      }
      continue;
    }

    if (/^UNIQUE\s*\(/i.test(line)) {
      unique.push({ raw: line });
      continue;
    }

    if (/^CONSTRAINT\s+/i.test(line)) {
      // try foreign key constraint
      const fkMatch = line.match(/FOREIGN\s+KEY\s*\(([^)]+)\)\s+REFERENCES\s+("?[A-Za-z0-9_]+"?)\s*\(([^)]+)\)/i);
      if (fkMatch) {
        const cols = fkMatch[1].split(',').map((s) => unquoteIdent(s).trim());
        const refTable = unquoteIdent(fkMatch[2]);
        const refCols = fkMatch[3].split(',').map((s) => unquoteIdent(s).trim());
        for (let i = 0; i < Math.min(cols.length, refCols.length); i++) {
          fk.push({ column: cols[i], refTable, refColumn: refCols[i], raw: line });
        }
      }
      continue;
    }

    // column definition: name type ...
    const cm = line.match(/^("?[A-Za-z0-9_]+"?)\s+([^\s]+)([\s\S]*)$/);
    if (!cm) continue;
    const colName = unquoteIdent(cm[1]);
    const colType = cm[2];
    const rest = cm[3] || '';

    let nullable = !/NOT\s+NULL/i.test(rest);
    const defMatch = rest.match(/DEFAULT\s+([^\s,]+(\s*::\s*[^\s,]+)?)/i);
    const def = defMatch ? defMatch[1].trim() : null;

    if (/PRIMARY\s+KEY/i.test(rest)) {
      pk.push(colName);
      // In Postgres, PRIMARY KEY implies NOT NULL.
      nullable = false;
    }
    if (/UNIQUE/i.test(rest)) unique.push({ columns: [colName], raw: line });

    const refMatch = rest.match(/REFERENCES\s+("?[A-Za-z0-9_]+"?)\s*\(([^)]+)\)/i);
    if (refMatch) {
      const refTable = unquoteIdent(refMatch[1]);
      const refCol = unquoteIdent(refMatch[2].split(',')[0]).trim();
      fk.push({ column: colName, refTable, refColumn: refCol, raw: line });
    }

    columns.push({ name: colName, type: colType.toLowerCase(), nullable, default: def });
  }

  // Ensure pk columns are marked NOT NULL.
  const pkDedup = Array.from(new Set(pk));
  for (const pkCol of pkDedup) {
    const c = columns.find((x) => x.name === pkCol);
    if (c) c.nullable = false;
  }

  return { name: tableName, pk: pkDedup, columns, unique, fk, indexes: [] };
}

function applySqlAlterAddColumn(table, clause) {
  // clause example: keywords TEXT
  const line = clause.replace(/,$/, '').trim();
  const m = line.match(/^("?[A-Za-z0-9_]+"?)\s+([^\s]+)([\s\S]*)$/);
  if (!m) return;
  const colName = unquoteIdent(m[1]);
  const colType = m[2].toLowerCase();
  const rest = m[3] || '';
  const nullable = !/NOT\s+NULL/i.test(rest);
  const defMatch = rest.match(/DEFAULT\s+([^\s,]+(\s*::\s*[^\s,]+)?)/i);
  const def = defMatch ? defMatch[1].trim() : null;

  const existing = table.columns.find((c) => c.name === colName);
  if (existing) {
    existing.type = colType;
    existing.nullable = nullable;
    existing.default = def;
  } else {
    table.columns.push({ name: colName, type: colType, nullable, default: def });
  }
}

function mergeTables(baseByName, incoming, sourceTag) {
  // incoming: {name, pk, columns, unique, fk, indexes}
  const name = incoming.name;
  const existing = baseByName.get(name);
  if (!existing) {
    baseByName.set(name, { ...incoming, source: sourceTag });
    return;
  }

  // Merge columns by name (incoming wins)
  const byCol = new Map(existing.columns.map((c) => [c.name, c]));
  for (const c of incoming.columns) {
    byCol.set(c.name, { ...byCol.get(c.name), ...c });
  }
  existing.columns = Array.from(byCol.values()).sort((a, b) => a.name.localeCompare(b.name));

  // Merge pk
  existing.pk = Array.from(new Set([...(existing.pk || []), ...(incoming.pk || [])]));

  // Append constraints
  existing.unique = [...(existing.unique || []), ...(incoming.unique || [])];
  existing.fk = [...(existing.fk || []), ...(incoming.fk || [])];
  existing.indexes = [...(existing.indexes || []), ...(incoming.indexes || [])];

  existing.source = existing.source || sourceTag;
}

function main() {
  const prismaPath = path.join(repoRoot, 'fulltech_api', 'prisma', 'schema.prisma');
  const sqlDir = path.join(repoRoot, 'fulltech_api', 'sql');
  const scriptsDir = path.join(repoRoot, 'fulltech_api', 'scripts');

  const prismaText = readText(prismaPath);
  const prismaTables = parsePrismaSchema(prismaText);

  const baseByName = new Map();
  for (const t of prismaTables) {
    mergeTables(baseByName, t, t.source);
  }

  // Collect SQL blocks from all sources first, then apply in two phases:
  // 1) CREATE TABLE (so tables exist)
  // 2) ALTER/INDEX/FK (so later scripts can modify earlier-created tables)
  const pending = [];

  const sqlFiles = listFiles(sqlDir, (p) => p.toLowerCase().endsWith('.sql')).sort();
  for (const file of sqlFiles) {
    const txt = readText(file);
    const blocks = extractSqlBlocksFromText(txt);
    const source = { kind: 'sql', file: path.relative(repoRoot, file).replace(/\\/g, '/') };
    for (const b of blocks) pending.push({ ...b, __source: source });
  }

  const tsFiles = listFiles(scriptsDir, (p) => p.toLowerCase().endsWith('.ts')).sort();
  for (const file of tsFiles) {
    const txt = readText(file);
    const backticks = Array.from(txt.matchAll(/`([\s\S]*?)`/g)).map((m) => m[1]);
    const source = { kind: 'ts_sql', file: path.relative(repoRoot, file).replace(/\\/g, '/') };
    for (const s of backticks) {
      const blocks = extractSqlBlocksFromText(s);
      for (const b of blocks) pending.push({ ...b, __source: source });
    }
  }

  // Phase 1: create tables
  for (const b of pending) {
    if (b.kind === 'create_table') {
      const t = parseSqlCreateTable(b);
      mergeTables(baseByName, t, b.__source);
    }
  }

  // Phase 2: alters + indexes + fks
  for (const b of pending) {
    if (b.kind === 'alter_add_column') {
      const tableName = unquoteIdent(b.tableRaw);
      const table = baseByName.get(tableName);
      if (table) applySqlAlterAddColumn(table, b.clause);
    }

    if (b.kind === 'create_index') {
      const tableName = unquoteIdent(b.tableRaw);
      const table = baseByName.get(tableName);
      if (table) {
        table.indexes = table.indexes || [];
        table.indexes.push({
          name: unquoteIdent(b.indexName),
          columns: b.columnsRaw.split(',').map((s) => unquoteIdent(s).trim()),
          where: b.whereRaw,
          raw: b.raw,
        });
      }
    }

    if (b.kind === 'alter_add_fk') {
      const tableName = unquoteIdent(b.tableRaw);
      const table = baseByName.get(tableName);
      if (table) {
        const cols = b.columnsRaw.split(',').map((s) => unquoteIdent(s).trim());
        const refTable = unquoteIdent(b.refTableRaw);
        const refCols = b.refColumnsRaw.split(',').map((s) => unquoteIdent(s).trim());
        table.fk = table.fk || [];
        for (let i = 0; i < Math.min(cols.length, refCols.length); i++) {
          table.fk.push({ column: cols[i], refTable, refColumn: refCols[i], raw: b.raw });
        }
      }
    }
  }

  // Finalize + sort
  const tables = Array.from(baseByName.values()).map((t) => {
    const cols = (t.columns || []).slice().sort((a, b) => a.name.localeCompare(b.name));
    const pk = (t.pk || []).slice();
    const unique = (t.unique || []).slice();
    const fk = (t.fk || []).slice();
    const indexes = (t.indexes || []).slice();

    // Normalize fk columns to actual column names if Prisma used field names
    return { name: t.name, pk, columns: cols, unique, fk, indexes, source: t.source };
  });

  tables.sort((a, b) => a.name.localeCompare(b.name));

  const out = {
    generated_at: new Date().toISOString(),
    sources: {
      prisma: path.relative(repoRoot, prismaPath).replace(/\\/g, '/'),
      sql_dir: path.relative(repoRoot, sqlDir).replace(/\\/g, '/'),
      scripts_dir: path.relative(repoRoot, scriptsDir).replace(/\\/g, '/'),
    },
    tables,
  };

  const outPath = path.join(repoRoot, 'fulltech_app', 'lib', 'offline', 'schema_snapshot.json');
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, JSON.stringify(out, null, 2) + '\n', 'utf8');

  // eslint-disable-next-line no-console
  console.log(`✅ Wrote schema snapshot: ${outPath}`);
  // eslint-disable-next-line no-console
  console.log(`✅ Tables: ${tables.length}`);
}

main();
