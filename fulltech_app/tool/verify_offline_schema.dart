import 'dart:convert';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../lib/offline/local_db/migrations/offline_schema_migrator.dart';

Future<void> main() async {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  final db = await factory.openDatabase(inMemoryDatabasePath);
  try {
    await OfflineSchemaMigrator.migrateToLatest(db);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;",
    );

    final local = tables.map((r) => r['name'] as String).toList();

    // Read the snapshot JSON from the package path (tool script runs in repo).
    // We avoid importing Flutter assets here.
    final snapshotText = await _readFileText('lib/offline/schema_snapshot.json');
    final snapshot = jsonDecode(snapshotText) as Map<String, dynamic>;

    final serverTables = (snapshot['tables'] as List)
        .map((t) => (t as Map<String, dynamic>)['name'] as String)
        .toList();

    const extraLocal = <String>{'sync_outbox', 'sync_state', 'sync_conflicts'};

    final expected = <String>{...serverTables, ...extraLocal};
    final actual = local.toSet();

    final missing = expected.difference(actual).toList()..sort();
    final extra = actual.difference(expected).toList()..sort();

    if (missing.isEmpty && extra.isEmpty) {
      // ignore: avoid_print
      print('✅ Offline schema OK: all expected tables exist (${expected.length}).');
      return;
    }

    if (missing.isNotEmpty) {
      // ignore: avoid_print
      print('❌ Missing tables (${missing.length}):');
      for (final t in missing) {
        // ignore: avoid_print
        print('  - $t');
      }
    }

    if (extra.isNotEmpty) {
      // ignore: avoid_print
      print('ℹ️ Extra tables present locally (${extra.length}):');
      for (final t in extra) {
        // ignore: avoid_print
        print('  - $t');
      }
    }

    throw StateError('Offline schema verification failed');
  } finally {
    await db.close();
  }
}

Future<String> _readFileText(String relativePath) async {
  final file = File(relativePath);
  return file.readAsString();
}
