import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'auth_session.dart';
import 'local_db_interface.dart';
import 'sync_queue_item.dart';

class LocalDbIo implements LocalDb {
  sqflite.Database? _db;

  @override
  Future<void> init() async {
    // Desktop uses FFI. Mobile uses native sqflite.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      sqflite.databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await _resolveDbPath();
    _db = await sqflite.openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, _version) async {
        await db.execute('''
          CREATE TABLE auth_session(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            token TEXT NOT NULL,
            user_json TEXT NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE sync_queue(
            id TEXT PRIMARY KEY,
            module TEXT NOT NULL,
            op TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            created_at_ms INTEGER NOT NULL,
            status INTEGER NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE store_entities(
            store TEXT NOT NULL,
            id TEXT NOT NULL,
            json TEXT NOT NULL,
            updated_at_ms INTEGER NOT NULL,
            PRIMARY KEY (store, id)
          );
        ''');

        await db.execute('CREATE INDEX idx_store_entities_store ON store_entities(store);');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS store_entities(
              store TEXT NOT NULL,
              id TEXT NOT NULL,
              json TEXT NOT NULL,
              updated_at_ms INTEGER NOT NULL,
              PRIMARY KEY (store, id)
            );
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_store_entities_store ON store_entities(store);');
        }
      },
    );
  }

  Future<String> _resolveDbPath() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await getApplicationSupportDirectory();
      return p.join(dir.path, 'fulltech_app.db');
    }

    final path = await sqflite.getDatabasesPath();
    return p.join(path, 'fulltech_app.db');
  }

  sqflite.Database get _database {
    final db = _db;
    if (db == null) throw StateError('LocalDb not initialized');
    return db;
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    await _database.insert(
      'auth_session',
      {
        'id': 1,
        'token': session.token,
        'user_json': jsonEncode(session.user.toJson()),
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<AuthSession?> readSession() async {
    final rows = await _database.query('auth_session', where: 'id = 1');
    if (rows.isEmpty) return null;
    final row = rows.first;
    return AuthSession.fromJson({
      'token': row['token'] as String,
      'user': jsonDecode(row['user_json'] as String) as Map<String, dynamic>,
    });
  }

  @override
  Future<void> clearSession() async {
    await _database.delete('auth_session');
  }

  @override
  Future<void> enqueueSync({
    required String module,
    required String op,
    required String entityId,
    required String payloadJson,
  }) async {
    final id = '${DateTime.now().millisecondsSinceEpoch}-$module-$entityId';
    await _database.insert(
      'sync_queue',
      {
        'id': id,
        'module': module,
        'op': op,
        'entity_id': entityId,
        'payload_json': payloadJson,
        'created_at_ms': DateTime.now().millisecondsSinceEpoch,
        'status': 0,
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<SyncQueueItem>> getPendingSyncItems() async {
    final rows = await _database.query(
      'sync_queue',
      where: 'status = 0',
      orderBy: 'created_at_ms ASC',
    );

    return rows
        .map(
          (r) => SyncQueueItem(
            id: r['id'] as String,
            module: r['module'] as String,
            op: r['op'] as String,
            entityId: r['entity_id'] as String,
            payloadJson: r['payload_json'] as String,
            createdAtMs: r['created_at_ms'] as int,
            status: r['status'] as int,
          ),
        )
        .toList();
  }

  @override
  Future<void> markSyncItemSent(String id) async {
    await _database.update(
      'sync_queue',
      {'status': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markSyncItemError(String id) async {
    await _database.update(
      'sync_queue',
      {'status': 2},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> upsertEntity({
    required String store,
    required String id,
    required String json,
  }) async {
    await _database.insert(
      'store_entities',
      {
        'store': store,
        'id': id,
        'json': json,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<String>> listEntitiesJson({required String store}) async {
    final rows = await _database.query(
      'store_entities',
      columns: ['json'],
      where: 'store = ?',
      whereArgs: [store],
      orderBy: 'updated_at_ms DESC',
    );

    return rows.map((r) => r['json'] as String).toList();
  }

  @override
  Future<void> deleteEntity({required String store, required String id}) async {
    await _database.delete(
      'store_entities',
      where: 'store = ? AND id = ?',
      whereArgs: [store, id],
    );
  }

  @override
  Future<void> clearStore({required String store}) async {
    await _database.delete(
      'store_entities',
      where: 'store = ?',
      whereArgs: [store],
    );
  }
}

LocalDb createLocalDb() => LocalDbIo();
