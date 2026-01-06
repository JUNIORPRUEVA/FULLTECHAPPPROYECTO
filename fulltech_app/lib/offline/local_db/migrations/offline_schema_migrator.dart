import 'package:sqflite/sqflite.dart' as sqflite;

import '../local_database.dart';

class OfflineSchemaMigrator {
  // IMPORTANT: This migrator is additive and safe.
  // It creates missing tables and adds missing columns without dropping or renaming.

  static Future<void> migrateToLatest(sqflite.Database db) async {
    final offlineDb = OfflineLocalDatabase(db);
    await offlineDb.ensureServerSchema();
  }
}
