import 'dart:async';

import 'package:sqflite/sqflite.dart' as sqflite;

import 'generated_schema.dart';

class OfflineLocalDatabase {
  final sqflite.Database db;

  const OfflineLocalDatabase(this.db);

  Future<void> ensureServerSchema() async {
    await db.transaction((txn) async {
      for (final def in offlineTableDefs) {
        await txn.execute(def.createSql);
        await _ensureColumns(txn, def.name, def.columns);
      }

      for (final idx in offlineExtraIndexes) {
        await txn.execute(idx);
      }
    });
  }

  Future<void> _ensureColumns(
    sqflite.DatabaseExecutor db,
    String tableName,
    List<OfflineColumnDef> desiredColumns,
  ) async {
    // SQLite: PRAGMA table_info(table)
    final rows = await db.rawQuery('PRAGMA table_info(${_quoteIdent(tableName)})');
    final existing = <String>{
      for (final r in rows)
        if (r['name'] != null) (r['name'] as String),
    };

    for (final col in desiredColumns) {
      if (existing.contains(col.name)) continue;

      final buf = StringBuffer();
      buf.write('ALTER TABLE ${_quoteIdent(tableName)} ADD COLUMN ${_quoteIdent(col.name)} ${col.type}');
      if (!col.nullable && col.defaultSql != null) {
        buf.write(' NOT NULL');
      }
      if (col.defaultSql != null) {
        buf.write(' DEFAULT ${col.defaultSql}');
      }

      await db.execute(buf.toString());
    }
  }

  String _quoteIdent(String name) {
    final safe = RegExp(r'^[a-z_][a-z0-9_]*$');
    if (safe.hasMatch(name)) return name;
    return '"' + name.replaceAll('"', '""') + '"';
  }
}
