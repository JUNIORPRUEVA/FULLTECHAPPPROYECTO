import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'auth_session.dart';
import 'local_db_interface.dart';
import 'sync_queue_item.dart';
import '../../offline/local_db/migrations/offline_schema_migrator.dart';
import '../services/sync_signals.dart';

class LocalDbWeb implements LocalDb {
  sqflite.Database? _db;

  static const _schemaVersion = 9;

  @override
  Future<void> init() async {
    // Web uses an IndexedDB-backed implementation.
    sqflite.databaseFactory = databaseFactoryFfiWeb;

    _db = await sqflite.openDatabase(
      'fulltech_app.db',
      version: _schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE auth_session(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            token TEXT NOT NULL,
            refresh_token TEXT,
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

        await db.execute(
          'CREATE INDEX idx_store_entities_store ON store_entities(store);',
        );

        await db.execute('''
          CREATE TABLE cotizaciones(
            id TEXT PRIMARY KEY,
            empresa_id TEXT NOT NULL,
            numero TEXT,
            customer_id TEXT,
            customer_name TEXT NOT NULL,
            customer_phone TEXT,
            customer_email TEXT,
            itbis_enabled INTEGER NOT NULL,
            itbis_rate REAL NOT NULL,
            subtotal REAL NOT NULL,
            itbis_amount REAL NOT NULL,
            total REAL NOT NULL,
            notes TEXT,
            status TEXT NOT NULL,
            created_by_user_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status TEXT NOT NULL
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_cotizaciones_empresa_created_at ON cotizaciones(empresa_id, created_at);',
        );
        await db.execute(
          'CREATE INDEX idx_cotizaciones_empresa_status ON cotizaciones(empresa_id, status);',
        );
        await db.execute(
          'CREATE INDEX idx_cotizaciones_empresa_customer ON cotizaciones(empresa_id, customer_name);',
        );

        await db.execute('''
          CREATE TABLE cotizacion_items(
            id TEXT PRIMARY KEY,
            quotation_id TEXT NOT NULL,
            product_id TEXT,
            nombre TEXT NOT NULL,
            cantidad REAL NOT NULL,
            unit_cost REAL NOT NULL,
            unit_price REAL NOT NULL,
            discount_pct REAL NOT NULL,
            discount_amount REAL NOT NULL,
            line_subtotal REAL NOT NULL,
            line_total REAL NOT NULL,
            created_at TEXT NOT NULL
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_cotizacion_items_quotation ON cotizacion_items(quotation_id);',
        );

        await db.execute('''
          CREATE TABLE presupuesto_draft(
            draft_key TEXT PRIMARY KEY,
            draft_json TEXT NOT NULL,
            updated_at_ms INTEGER NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE cartas(
            id TEXT PRIMARY KEY,
            empresa_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            quotation_id TEXT,
            customer_name TEXT NOT NULL,
            customer_phone TEXT,
            customer_email TEXT,
            letter_type TEXT NOT NULL,
            subject TEXT NOT NULL,
            body TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            last_error TEXT,
            deleted_at TEXT
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_cartas_empresa_created_at ON cartas(empresa_id, created_at);',
        );
        await db.execute(
          'CREATE INDEX idx_cartas_empresa_status ON cartas(empresa_id, status);',
        );
        await db.execute(
          'CREATE INDEX idx_cartas_empresa_letter_type ON cartas(empresa_id, letter_type);',
        );

        await db.execute('''
          CREATE TABLE sales_records(
            id TEXT PRIMARY KEY,
            empresa_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            customer_name TEXT,
            customer_phone TEXT,
            customer_document TEXT,
            product_or_service TEXT NOT NULL,
            details_json TEXT,
            amount REAL NOT NULL,
            payment_method TEXT,
            channel TEXT NOT NULL,
            status TEXT,
            notes TEXT,
            sold_at TEXT NOT NULL,
            evidence_required INTEGER NOT NULL,
            evidence_count INTEGER NOT NULL,
            deleted INTEGER NOT NULL,
            deleted_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            last_error TEXT
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_sales_records_empresa_sold_at ON sales_records(empresa_id, sold_at);',
        );
        await db.execute(
          'CREATE INDEX idx_sales_records_empresa_channel ON sales_records(empresa_id, channel);',
        );
        await db.execute(
          'CREATE INDEX idx_sales_records_empresa_status ON sales_records(empresa_id, status);',
        );
        await db.execute(
          'CREATE INDEX idx_sales_records_empresa_deleted ON sales_records(empresa_id, deleted);',
        );

        await db.execute('''
          CREATE TABLE sale_evidence(
            id TEXT PRIMARY KEY,
            sale_id TEXT NOT NULL,
            type TEXT NOT NULL,
            url_or_path TEXT NOT NULL,
            caption TEXT,
            created_at TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            last_error TEXT
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_sale_evidence_sale_id ON sale_evidence(sale_id);',
        );

        // === Operaciones (Operations) ===
        await db.execute('''
          CREATE TABLE operations_jobs(
            id TEXT PRIMARY KEY,
            empresa_id TEXT NOT NULL,
            crm_customer_id TEXT NOT NULL,
            crm_chat_id TEXT,
            crm_task_type TEXT,
            product_id TEXT,
            service_id TEXT,
            customer_name TEXT NOT NULL,
            customer_phone TEXT,
            customer_address TEXT,
            service_type TEXT NOT NULL,
            priority TEXT NOT NULL,
            status TEXT NOT NULL,
            notes TEXT,
            technician_notes TEXT,
            cancel_reason TEXT,
            scheduled_date TEXT,
            preferred_time TEXT,
            created_by_user_id TEXT,
            assigned_tech_id TEXT,
            last_update_by_user_id TEXT,
            assigned_team_ids_json TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted INTEGER NOT NULL,
            deleted_at TEXT,
            sync_status TEXT NOT NULL,
            last_error TEXT
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_operations_jobs_empresa_created_at ON operations_jobs(empresa_id, created_at);',
        );
        await db.execute(
          'CREATE INDEX idx_operations_jobs_empresa_status ON operations_jobs(empresa_id, status);',
        );
        await db.execute(
          'CREATE INDEX idx_operations_jobs_empresa_assigned_tech ON operations_jobs(empresa_id, assigned_tech_id);',
        );
        await db.execute(
          'CREATE INDEX idx_operations_jobs_empresa_customer_name ON operations_jobs(empresa_id, customer_name);',
        );

        await db.execute('''
          CREATE TABLE operations_surveys(
            id TEXT PRIMARY KEY,
            job_id TEXT NOT NULL UNIQUE,
            mode TEXT NOT NULL,
            gps_lat REAL,
            gps_lng REAL,
            address_confirmed TEXT,
            complexity TEXT,
            site_notes TEXT,
            tools_needed_json TEXT,
            materials_needed_json TEXT,
            products_to_use_json TEXT,
            future_opportunities TEXT,
            created_by_tech_id TEXT,
            created_at TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            last_error TEXT
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_operations_surveys_job_id ON operations_surveys(job_id);',
        );

        await db.execute('''
          CREATE TABLE operations_survey_media(
            id TEXT PRIMARY KEY,
            survey_id TEXT NOT NULL,
            type TEXT NOT NULL,
            url_or_path TEXT NOT NULL,
            caption TEXT,
            created_at TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            last_error TEXT
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_operations_survey_media_survey_id ON operations_survey_media(survey_id);',
        );

        await db.execute('''
          CREATE TABLE operations_schedule(
            id TEXT PRIMARY KEY,
            job_id TEXT NOT NULL UNIQUE,
            scheduled_date TEXT NOT NULL,
            preferred_time TEXT,
            assigned_tech_id TEXT NOT NULL,
            additional_tech_ids_json TEXT,
            customer_availability_notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            last_error TEXT
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_operations_schedule_job_id ON operations_schedule(job_id);',
        );
        await db.execute(
          'CREATE INDEX idx_operations_schedule_date ON operations_schedule(scheduled_date);',
        );
        await db.execute(
          'CREATE INDEX idx_operations_schedule_assigned_tech ON operations_schedule(assigned_tech_id);',
        );

        await db.execute('''
          CREATE TABLE operations_installation_reports(
            id TEXT PRIMARY KEY,
            job_id TEXT NOT NULL,
            started_at TEXT,
            finished_at TEXT,
            tech_notes TEXT,
            work_done_summary TEXT,
            installed_products_json TEXT,
            media_urls_json TEXT,
            signature_name TEXT,
            created_by_tech_id TEXT,
            created_at TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            last_error TEXT
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_operations_installation_reports_job_id ON operations_installation_reports(job_id);',
        );

        await db.execute('''
          CREATE TABLE operations_warranty_tickets(
            id TEXT PRIMARY KEY,
            job_id TEXT NOT NULL,
            reason TEXT NOT NULL,
            reported_at TEXT NOT NULL,
            status TEXT NOT NULL,
            assigned_tech_id TEXT,
            resolution_notes TEXT,
            resolved_at TEXT,
            created_at TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            last_error TEXT
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_operations_warranty_tickets_job_id ON operations_warranty_tickets(job_id);',
        );
        await db.execute(
          'CREATE INDEX idx_operations_warranty_tickets_status ON operations_warranty_tickets(status);',
        );

        // Additive + safe: ensure ALL backend tables exist locally, plus outbox tables.
        await OfflineSchemaMigrator.migrateToLatest(db);
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
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_store_entities_store ON store_entities(store);',
          );
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cotizaciones(
              id TEXT PRIMARY KEY,
              empresa_id TEXT NOT NULL,
              numero TEXT,
              customer_id TEXT,
              customer_name TEXT NOT NULL,
              customer_phone TEXT,
              customer_email TEXT,
              itbis_enabled INTEGER NOT NULL,
              itbis_rate REAL NOT NULL,
              subtotal REAL NOT NULL,
              itbis_amount REAL NOT NULL,
              total REAL NOT NULL,
              notes TEXT,
              status TEXT NOT NULL,
              created_by_user_id TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              sync_status TEXT NOT NULL
            );
          ''');

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_cotizaciones_empresa_created_at ON cotizaciones(empresa_id, created_at);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_cotizaciones_empresa_status ON cotizaciones(empresa_id, status);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_cotizaciones_empresa_customer ON cotizaciones(empresa_id, customer_name);',
          );

          await db.execute('''
            CREATE TABLE IF NOT EXISTS cotizacion_items(
              id TEXT PRIMARY KEY,
              quotation_id TEXT NOT NULL,
              product_id TEXT,
              nombre TEXT NOT NULL,
              cantidad REAL NOT NULL,
              unit_cost REAL NOT NULL,
              unit_price REAL NOT NULL,
              discount_pct REAL NOT NULL,
              discount_amount REAL NOT NULL,
              line_subtotal REAL NOT NULL,
              line_total REAL NOT NULL,
              created_at TEXT NOT NULL
            );
          ''');

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_cotizacion_items_quotation ON cotizacion_items(quotation_id);',
          );
        }

        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS presupuesto_draft(
              draft_key TEXT PRIMARY KEY,
              draft_json TEXT NOT NULL,
              updated_at_ms INTEGER NOT NULL
            );
          ''');
        }

        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cartas(
              id TEXT PRIMARY KEY,
              empresa_id TEXT NOT NULL,
              user_id TEXT NOT NULL,
              quotation_id TEXT,
              customer_name TEXT NOT NULL,
              customer_phone TEXT,
              customer_email TEXT,
              letter_type TEXT NOT NULL,
              subject TEXT NOT NULL,
              body TEXT NOT NULL,
              status TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              sync_status TEXT NOT NULL,
              last_error TEXT,
              deleted_at TEXT
            );
          ''');

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_cartas_empresa_created_at ON cartas(empresa_id, created_at);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_cartas_empresa_status ON cartas(empresa_id, status);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_cartas_empresa_letter_type ON cartas(empresa_id, letter_type);',
          );
        }

        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sales_records(
              id TEXT PRIMARY KEY,
              empresa_id TEXT NOT NULL,
              user_id TEXT NOT NULL,
              customer_name TEXT,
              customer_phone TEXT,
              customer_document TEXT,
              product_or_service TEXT NOT NULL,
              details_json TEXT,
              amount REAL NOT NULL,
              payment_method TEXT,
              channel TEXT NOT NULL,
              status TEXT,
              notes TEXT,
              sold_at TEXT NOT NULL,
              evidence_required INTEGER NOT NULL,
              evidence_count INTEGER NOT NULL,
              deleted INTEGER NOT NULL,
              deleted_at TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              sync_status TEXT NOT NULL,
              last_error TEXT
            );
          ''');

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_sales_records_empresa_sold_at ON sales_records(empresa_id, sold_at);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_sales_records_empresa_channel ON sales_records(empresa_id, channel);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_sales_records_empresa_status ON sales_records(empresa_id, status);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_sales_records_empresa_deleted ON sales_records(empresa_id, deleted);',
          );

          await db.execute('''
            CREATE TABLE IF NOT EXISTS sale_evidence(
              id TEXT PRIMARY KEY,
              sale_id TEXT NOT NULL,
              type TEXT NOT NULL,
              url_or_path TEXT NOT NULL,
              caption TEXT,
              created_at TEXT NOT NULL,
              sync_status TEXT NOT NULL,
              last_error TEXT
            );
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_sale_evidence_sale_id ON sale_evidence(sale_id);',
          );
        }

        if (oldVersion < 7) {
          try {
            await db.execute(
              'ALTER TABLE sales_records ADD COLUMN details_json TEXT;',
            );
          } catch (_) {
            // ignore (column may already exist)
          }
        }

        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS operations_jobs(
              id TEXT PRIMARY KEY,
              empresa_id TEXT NOT NULL,
              crm_customer_id TEXT NOT NULL,
              customer_name TEXT NOT NULL,
              customer_phone TEXT,
              customer_address TEXT,
              service_type TEXT NOT NULL,
              priority TEXT NOT NULL,
              status TEXT NOT NULL,
              notes TEXT,
              created_by_user_id TEXT,
              assigned_tech_id TEXT,
              assigned_team_ids_json TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted INTEGER NOT NULL,
              deleted_at TEXT,
              sync_status TEXT NOT NULL,
              last_error TEXT
            );
          ''');

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_operations_jobs_empresa_created_at ON operations_jobs(empresa_id, created_at);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_operations_jobs_empresa_status ON operations_jobs(empresa_id, status);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_operations_jobs_empresa_assigned_tech ON operations_jobs(empresa_id, assigned_tech_id);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_operations_jobs_empresa_customer_name ON operations_jobs(empresa_id, customer_name);',
          );

          await db.execute('''
            CREATE TABLE IF NOT EXISTS operations_surveys(
              id TEXT PRIMARY KEY,
              job_id TEXT NOT NULL UNIQUE,
              mode TEXT NOT NULL,
              gps_lat REAL,
              gps_lng REAL,
              address_confirmed TEXT,
              complexity TEXT,
              site_notes TEXT,
              tools_needed_json TEXT,
              materials_needed_json TEXT,
              products_to_use_json TEXT,
              future_opportunities TEXT,
              created_by_tech_id TEXT,
              created_at TEXT NOT NULL,
              sync_status TEXT NOT NULL,
              last_error TEXT
            );
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_operations_surveys_job_id ON operations_surveys(job_id);',
          );

          await db.execute('''
            CREATE TABLE IF NOT EXISTS operations_survey_media(
              id TEXT PRIMARY KEY,
              survey_id TEXT NOT NULL,
              type TEXT NOT NULL,
              url_or_path TEXT NOT NULL,
              caption TEXT,
              created_at TEXT NOT NULL,
              sync_status TEXT NOT NULL,
              last_error TEXT
            );
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_operations_survey_media_survey_id ON operations_survey_media(survey_id);',
          );

          await db.execute('''
            CREATE TABLE IF NOT EXISTS operations_schedule(
              id TEXT PRIMARY KEY,
              job_id TEXT NOT NULL UNIQUE,
              scheduled_date TEXT NOT NULL,
              preferred_time TEXT,
              assigned_tech_id TEXT NOT NULL,
              additional_tech_ids_json TEXT,
              customer_availability_notes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              sync_status TEXT NOT NULL,
              last_error TEXT
            );
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_operations_schedule_job_id ON operations_schedule(job_id);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_operations_schedule_date ON operations_schedule(scheduled_date);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_operations_schedule_assigned_tech ON operations_schedule(assigned_tech_id);',
          );

          await db.execute('''
            CREATE TABLE IF NOT EXISTS operations_installation_reports(
              id TEXT PRIMARY KEY,
              job_id TEXT NOT NULL,
              started_at TEXT,
              finished_at TEXT,
              tech_notes TEXT,
              work_done_summary TEXT,
              installed_products_json TEXT,
              media_urls_json TEXT,
              signature_name TEXT,
              created_by_tech_id TEXT,
              created_at TEXT NOT NULL,
              sync_status TEXT NOT NULL,
              last_error TEXT
            );
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_operations_installation_reports_job_id ON operations_installation_reports(job_id);',
          );

          await db.execute('''
            CREATE TABLE IF NOT EXISTS operations_warranty_tickets(
              id TEXT PRIMARY KEY,
              job_id TEXT NOT NULL,
              reason TEXT NOT NULL,
              reported_at TEXT NOT NULL,
              status TEXT NOT NULL,
              assigned_tech_id TEXT,
              resolution_notes TEXT,
              resolved_at TEXT,
              created_at TEXT NOT NULL,
              sync_status TEXT NOT NULL,
              last_error TEXT
            );
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_operations_warranty_tickets_job_id ON operations_warranty_tickets(job_id);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_operations_warranty_tickets_status ON operations_warranty_tickets(status);',
          );
        }

        if (oldVersion < 9) {
          // Additive + safe: ensure ALL backend tables exist locally, plus outbox tables.
          await OfflineSchemaMigrator.migrateToLatest(db);
        }
      },
    );

    // Self-heal for legacy installs missing the `id` column in `auth_session`.
    await _ensureAuthSessionSchema(_database);
    await _ensureOperationsJobsSchema(_database);
  }

  sqflite.Database get _database {
    final db = _db;
    if (db == null) throw StateError('LocalDb not initialized');
    return db;
  }

  Future<void> _ensureAuthSessionSchema(sqflite.Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS auth_session(
          id INTEGER PRIMARY KEY CHECK (id = 1),
          token TEXT NOT NULL,
          refresh_token TEXT,
          user_json TEXT NOT NULL
        );
      ''');

      final info = await db.rawQuery('PRAGMA table_info(auth_session);');
      final columnNames = <String>{
        for (final row in info)
          if (row['name'] is String) row['name'] as String,
      };

      if (!columnNames.contains('token') ||
          !columnNames.contains('user_json')) {
        await db.execute('DROP TABLE IF EXISTS auth_session;');
        await db.execute('''
          CREATE TABLE auth_session(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            token TEXT NOT NULL,
            refresh_token TEXT,
            user_json TEXT NOT NULL
          );
        ''');
        return;
      }

      if (!columnNames.contains('id')) {
        await db.execute('ALTER TABLE auth_session ADD COLUMN id INTEGER;');
      }
      if (!columnNames.contains('refresh_token')) {
        await db.execute(
          'ALTER TABLE auth_session ADD COLUMN refresh_token TEXT;',
        );
      }

      await db.execute(
        'DELETE FROM auth_session WHERE rowid NOT IN (SELECT MAX(rowid) FROM auth_session);',
      );
      await db.execute('UPDATE auth_session SET id = 1;');
    } catch (_) {
      // Best-effort only.
    }
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    try {
      await _database.insert('auth_session', {
        'id': 1,
        'token': session.token,
        'refresh_token': session.refreshToken,
        'user_json': jsonEncode(session.user.toJson()),
      }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DB][WEB] Failed to save session: $e');
      }
    }
  }

  Future<void> _ensureOperationsJobsSchema(sqflite.Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS operations_jobs(
          id TEXT PRIMARY KEY,
          empresa_id TEXT NOT NULL,
          crm_customer_id TEXT NOT NULL,
          customer_name TEXT NOT NULL,
          customer_phone TEXT,
          customer_address TEXT,
          service_type TEXT NOT NULL,
          priority TEXT NOT NULL,
          status TEXT NOT NULL,
          notes TEXT,
          created_by_user_id TEXT,
          assigned_tech_id TEXT,
          assigned_team_ids_json TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted INTEGER NOT NULL,
          deleted_at TEXT,
          sync_status TEXT NOT NULL,
          last_error TEXT
        );
      ''');

      final info = await db.rawQuery('PRAGMA table_info(operations_jobs);');
      final cols = <String>{
        for (final row in info)
          if (row['name'] is String) row['name'] as String,
      };

      Future<void> add(String name, String type) async {
        if (cols.contains(name)) return;
        await db.execute('ALTER TABLE operations_jobs ADD COLUMN $name $type;');
      }

      await add('crm_chat_id', 'TEXT');
      await add('crm_task_type', 'TEXT');
      await add('product_id', 'TEXT');
      await add('service_id', 'TEXT');
      await add('technician_notes', 'TEXT');
      await add('cancel_reason', 'TEXT');
      await add('scheduled_date', 'TEXT');
      await add('preferred_time', 'TEXT');
      await add('last_update_by_user_id', 'TEXT');

      await add('tipo_trabajo', 'TEXT');
      await add('estado', 'TEXT');
    } catch (_) {
      // Best-effort only.
    }
  }

  @override
  Future<AuthSession?> readSession() async {
    final rows = await _database.query('auth_session', where: 'id = 1');
    if (rows.isEmpty) return null;
    final row = rows.first;
    return AuthSession.fromJson({
      'token': row['token'] as String,
      'refresh_token': row['refresh_token'] as String?,
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
    await _database.insert('sync_queue', {
      'id': id,
      'module': module,
      'op': op,
      'entity_id': entityId,
      'payload_json': payloadJson,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
      'status': 0,
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);

    SyncSignals.instance.notifyQueueChanged();
  }

  @override
  Future<void> updateQueuedSyncPayload({
    required String module,
    required String op,
    required String entityId,
    required String payloadJson,
  }) async {
    await _database.update(
      'sync_queue',
      {
        'payload_json': payloadJson,
        'created_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'module = ? AND op = ? AND entity_id = ? AND status = 0',
      whereArgs: [module, op, entityId],
    );

    SyncSignals.instance.notifyQueueChanged();
  }

  @override
  Future<void> cancelQueuedSync({
    required String module,
    required String entityId,
  }) async {
    // Mark as cancelled (3). Cancelled items are not pending.
    await _database.update(
      'sync_queue',
      {'status': 3},
      where: 'module = ? AND entity_id = ? AND status = 0',
      whereArgs: [module, entityId],
    );

    SyncSignals.instance.notifyQueueChanged();
  }

  @override
  Future<void> retryErroredSyncItems({
    String? module,
    Duration minAge = const Duration(seconds: 30),
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = nowMs - minAge.inMilliseconds;

    final whereParts = <String>['status = 2', 'created_at_ms <= ?'];
    final args = <Object?>[cutoffMs];
    final m = module?.trim();
    if (m != null && m.isNotEmpty) {
      whereParts.add('module = ?');
      args.add(m);
    }

    await _database.update(
      'sync_queue',
      {'status': 0},
      where: whereParts.join(' AND '),
      whereArgs: args,
    );
  }

  // === Cartas (letters) ===

  @override
  Future<void> upsertCarta({required Map<String, Object?> row}) async {
    await _database.insert(
      'cartas',
      row,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Map<String, Object?>>> listCartas({
    required String empresaId,
    String? q,
    String? letterType,
    String? status,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  }) async {
    final where = <String>['empresa_id = ?', 'deleted_at IS NULL'];
    final args = <Object?>[empresaId];

    if (status != null && status.trim().isNotEmpty) {
      where.add('status = ?');
      args.add(status.trim());
    }

    if (letterType != null && letterType.trim().isNotEmpty) {
      where.add('letter_type = ?');
      args.add(letterType.trim());
    }

    if (fromIso != null && fromIso.trim().isNotEmpty) {
      where.add('created_at >= ?');
      args.add(fromIso.trim());
    }

    if (toIso != null && toIso.trim().isNotEmpty) {
      where.add('created_at <= ?');
      args.add(toIso.trim());
    }

    if (q != null && q.trim().isNotEmpty) {
      final qq = '%${q.trim()}%';
      where.add(
        '(customer_name LIKE ? OR customer_phone LIKE ? OR subject LIKE ?)',
      );
      args.addAll([qq, qq, qq]);
    }

    final rows = await _database.query(
      'cartas',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows;
  }

  @override
  Future<Map<String, Object?>?> getCarta({required String id}) async {
    final rows = await _database.query(
      'cartas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  @override
  Future<void> markCartaDeleted({
    required String id,
    required String deletedAtIso,
  }) async {
    await _database.update(
      'cartas',
      {'deleted_at': deletedAtIso, 'sync_status': 'pending'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === Sales (ventas) ===

  @override
  Future<void> upsertSalesRecord({required Map<String, Object?> row}) async {
    await _database.insert(
      'sales_records',
      row,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Map<String, Object?>>> listSalesRecords({
    required String empresaId,
    String? q,
    String? channel,
    String? status,
    String? paymentMethod,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  }) async {
    final where = <String>['empresa_id = ?', 'deleted = 0'];
    final args = <Object?>[empresaId];

    if (channel != null && channel.trim().isNotEmpty) {
      where.add('channel = ?');
      args.add(channel.trim());
    }
    if (status != null && status.trim().isNotEmpty) {
      where.add('status = ?');
      args.add(status.trim());
    }
    if (paymentMethod != null && paymentMethod.trim().isNotEmpty) {
      where.add('payment_method = ?');
      args.add(paymentMethod.trim());
    }
    if (fromIso != null && fromIso.trim().isNotEmpty) {
      where.add('sold_at >= ?');
      args.add(fromIso.trim());
    }
    if (toIso != null && toIso.trim().isNotEmpty) {
      where.add('sold_at <= ?');
      args.add(toIso.trim());
    }
    if (q != null && q.trim().isNotEmpty) {
      final qq = '%${q.trim()}%';
      where.add(
        '(customer_name LIKE ? OR customer_phone LIKE ? OR product_or_service LIKE ? OR notes LIKE ? OR details_json LIKE ?)',
      );
      args.addAll([qq, qq, qq, qq, qq]);
    }

    final rows = await _database.query(
      'sales_records',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'sold_at DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows;
  }

  @override
  Future<Map<String, Object?>?> getSalesRecord({required String id}) async {
    final rows = await _database.query(
      'sales_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  @override
  Future<void> markSalesRecordDeleted({
    required String id,
    required String deletedAtIso,
  }) async {
    await _database.update(
      'sales_records',
      {'deleted': 1, 'deleted_at': deletedAtIso, 'sync_status': 'pending'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> upsertSalesEvidence({required Map<String, Object?> row}) async {
    await _database.insert(
      'sale_evidence',
      row,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Map<String, Object?>>> listSalesEvidence({
    required String saleId,
  }) async {
    final rows = await _database.query(
      'sale_evidence',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'created_at DESC',
    );
    return rows;
  }

  // === Operaciones (Operations) ===

  @override
  Future<void> upsertOperationsJob({required Map<String, Object?> row}) async {
    await _database.insert(
      'operations_jobs',
      row,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Map<String, Object?>>> listOperationsJobs({
    required String empresaId,
    String? q,
    String? status,
    String? estado,
    String? tipoTrabajo,
    String? assignedTechId,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  }) async {
    final where = <String>['empresa_id = ?', 'deleted = 0'];
    final args = <Object?>[empresaId];

    final st = status?.trim();
    if (st != null && st.isNotEmpty) {
      where.add('status = ?');
      args.add(st);
    }

    final es = estado?.trim();
    if (es != null && es.isNotEmpty) {
      where.add('estado = ?');
      args.add(es);
    }

    final tt = tipoTrabajo?.trim();
    if (tt != null && tt.isNotEmpty) {
      where.add('tipo_trabajo = ?');
      args.add(tt);
    }

    final at = assignedTechId?.trim();
    if (at != null && at.isNotEmpty) {
      where.add('assigned_tech_id = ?');
      args.add(at);
    }

    if (fromIso != null && fromIso.trim().isNotEmpty) {
      where.add('created_at >= ?');
      args.add(fromIso.trim());
    }

    if (toIso != null && toIso.trim().isNotEmpty) {
      where.add('created_at <= ?');
      args.add(toIso.trim());
    }

    final qq = q?.trim();
    if (qq != null && qq.isNotEmpty) {
      final like = '%$qq%';
      where.add(
        '(id LIKE ? OR customer_name LIKE ? OR customer_phone LIKE ? OR customer_address LIKE ? OR service_type LIKE ?)',
      );
      args.addAll([like, like, like, like, like]);
    }

    final rows = await _database.query(
      'operations_jobs',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows;
  }

  @override
  Future<Map<String, Object?>?> getOperationsJob({required String id}) async {
    final rows = await _database.query(
      'operations_jobs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  @override
  Future<void> markOperationsJobDeleted({
    required String id,
    required String deletedAtIso,
  }) async {
    await _database.update(
      'operations_jobs',
      {'deleted': 1, 'deleted_at': deletedAtIso, 'sync_status': 'pending'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> upsertOperationsSurvey({
    required Map<String, Object?> row,
  }) async {
    await _database.insert(
      'operations_surveys',
      row,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Map<String, Object?>?> getOperationsSurveyByJob({
    required String jobId,
  }) async {
    final rows = await _database.query(
      'operations_surveys',
      where: 'job_id = ?',
      whereArgs: [jobId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  @override
  Future<void> replaceOperationsSurveyMedia({
    required String surveyId,
    required List<Map<String, Object?>> items,
  }) async {
    final batch = _database.batch();
    batch.delete(
      'operations_survey_media',
      where: 'survey_id = ?',
      whereArgs: [surveyId],
    );
    for (final item in items) {
      batch.insert(
        'operations_survey_media',
        item,
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Map<String, Object?>>> listOperationsSurveyMedia({
    required String surveyId,
  }) async {
    final rows = await _database.query(
      'operations_survey_media',
      where: 'survey_id = ?',
      whereArgs: [surveyId],
      orderBy: 'created_at DESC',
    );
    return rows;
  }

  @override
  Future<void> upsertOperationsSchedule({
    required Map<String, Object?> row,
  }) async {
    await _database.insert(
      'operations_schedule',
      row,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Map<String, Object?>?> getOperationsScheduleByJob({
    required String jobId,
  }) async {
    final rows = await _database.query(
      'operations_schedule',
      where: 'job_id = ?',
      whereArgs: [jobId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  @override
  Future<void> upsertOperationsInstallationReport({
    required Map<String, Object?> row,
  }) async {
    await _database.insert(
      'operations_installation_reports',
      row,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Map<String, Object?>>> listOperationsInstallationReports({
    required String jobId,
  }) async {
    final rows = await _database.query(
      'operations_installation_reports',
      where: 'job_id = ?',
      whereArgs: [jobId],
      orderBy: 'created_at DESC',
    );
    return rows;
  }

  @override
  Future<void> upsertOperationsWarrantyTicket({
    required Map<String, Object?> row,
  }) async {
    await _database.insert(
      'operations_warranty_tickets',
      row,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Map<String, Object?>>> listOperationsWarrantyTickets({
    required String jobId,
  }) async {
    final rows = await _database.query(
      'operations_warranty_tickets',
      where: 'job_id = ?',
      whereArgs: [jobId],
      orderBy: 'reported_at DESC',
    );
    return rows;
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
    await _database.insert('store_entities', {
      'store': store,
      'id': id,
      'json': json,
      'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  @override
  Future<void> upsertEntityDirect({
    required String store,
    required String id,
    required String json,
  }) async {
    // Web version doesn't need queueing, just forward to upsertEntity
    await upsertEntity(store: store, id: id, json: json);
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
  Future<String?> getEntityJson({
    required String store,
    required String id,
  }) async {
    final rows = await _database.query(
      'store_entities',
      columns: ['json'],
      where: 'store = ? AND id = ?',
      whereArgs: [store, id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['json'] as String?;
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

  @override
  Future<void> clearStoreDirect({required String store}) async {
    // Web version doesn't need queueing, just forward to clearStore
    await clearStore(store: store);
  }

  // === Cotizaciones (local mirror tables) ===

  @override
  Future<void> upsertCotizacion({required Map<String, Object?> row}) async {
    await _database.insert(
      'cotizaciones',
      row,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> replaceCotizacionItems({
    required String quotationId,
    required List<Map<String, Object?>> items,
  }) async {
    final batch = _database.batch();
    batch.delete(
      'cotizacion_items',
      where: 'quotation_id = ?',
      whereArgs: [quotationId],
    );
    for (final item in items) {
      batch.insert(
        'cotizacion_items',
        item,
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Map<String, Object?>>> listCotizaciones({
    required String empresaId,
    String? q,
    String? status,
    String? fromIso,
    String? toIso,
    int limit = 50,
    int offset = 0,
  }) async {
    final whereParts = <String>['empresa_id = ?'];
    final whereArgs = <Object?>[empresaId];

    final qq = q?.trim();
    if (qq != null && qq.isNotEmpty) {
      whereParts.add(
        '(numero LIKE ? OR customer_name LIKE ? OR customer_phone LIKE ?)',
      );
      final like = '%$qq%';
      whereArgs.add(like);
      whereArgs.add(like);
      whereArgs.add(like);
    }

    final st = status?.trim();
    if (st != null && st.isNotEmpty) {
      whereParts.add('status = ?');
      whereArgs.add(st);
    }

    if (fromIso != null && fromIso.trim().isNotEmpty) {
      whereParts.add('created_at >= ?');
      whereArgs.add(fromIso.trim());
    }

    if (toIso != null && toIso.trim().isNotEmpty) {
      whereParts.add('created_at <= ?');
      whereArgs.add(toIso.trim());
    }

    final rows = await _database.query(
      'cotizaciones',
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.cast<Map<String, Object?>>();
  }

  @override
  Future<Map<String, Object?>?> getCotizacion({required String id}) async {
    final rows = await _database.query(
      'cotizaciones',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first.cast<String, Object?>();
  }

  @override
  Future<List<Map<String, Object?>>> listCotizacionItems({
    required String quotationId,
  }) async {
    final rows = await _database.query(
      'cotizacion_items',
      where: 'quotation_id = ?',
      whereArgs: [quotationId],
      orderBy: 'created_at ASC',
    );
    return rows.cast<Map<String, Object?>>();
  }

  @override
  Future<void> deleteCotizacion({required String id}) async {
    await _database.transaction((txn) async {
      await txn.delete(
        'cotizacion_items',
        where: 'quotation_id = ?',
        whereArgs: [id],
      );
      await txn.delete('cotizaciones', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<void> savePresupuestoDraft({
    required String draftKey,
    required String draftJson,
  }) async {
    await _database.insert('presupuesto_draft', {
      'draft_key': draftKey,
      'draft_json': draftJson,
      'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  @override
  Future<String?> loadPresupuestoDraftJson({required String draftKey}) async {
    final rows = await _database.query(
      'presupuesto_draft',
      columns: ['draft_json'],
      where: 'draft_key = ?',
      whereArgs: [draftKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['draft_json'] as String?;
  }

  @override
  Future<void> clearPresupuestoDraft({required String draftKey}) async {
    await _database.delete(
      'presupuesto_draft',
      where: 'draft_key = ?',
      whereArgs: [draftKey],
    );
  }
}

LocalDb createLocalDb() => LocalDbWeb();
