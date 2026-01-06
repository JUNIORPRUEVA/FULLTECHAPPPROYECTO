import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fulltech_app/offline/local_db/migrations/offline_schema_migrator.dart';

void main() {
  test('offline schema creates all backend tables + outbox tables', () async {
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;

    final db = await factory.openDatabase(inMemoryDatabasePath);
    try {
      await OfflineSchemaMigrator.migrateToLatest(db);

      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;",
      );
      final actual = rows.map((r) => r['name'] as String).toSet();

      final snapshotText = File('lib/offline/schema_snapshot.json').readAsStringSync();
      final snapshot = jsonDecode(snapshotText) as Map<String, dynamic>;

      final serverTables = (snapshot['tables'] as List)
          .map((t) => (t as Map<String, dynamic>)['name'] as String)
          .toSet();

      const extraLocal = <String>{'sync_outbox', 'sync_state', 'sync_conflicts'};
      final expected = <String>{...serverTables, ...extraLocal};

      final missing = expected.difference(actual).toList()..sort();
      expect(missing, isEmpty, reason: 'Missing tables: $missing');
    } finally {
      await db.close();
    }
  });
}
