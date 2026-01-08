import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Emergency script to clear pending attendance punches from local SQLite
/// 
/// USE WHEN: App is spamming POST /attendance/punches with 400 errors
/// 
/// This happens when:
/// - Punches were queued offline with invalid/incomplete data
/// - Schema changed but old queued items don't match
/// - Corrupted sync queue needs to be cleared
///
/// Run: dart run tool/clear_pending_punches.dart

void main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║  CLEAR PENDING ATTENDANCE PUNCHES FROM LOCAL DATABASE     ║');
  print('╚═══════════════════════════════════════════════════════════╝\n');

  // Initialize FFI for desktop
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  // Find database path
  final dbPath = await _findDatabasePath();
  if (dbPath == null) {
    print('❌ Could not find database file');
    print('   Expected locations:');
    print('   - Windows: %APPDATA%\\fulltech_app\\*.db');
    print('   - Build folder: build/windows/*/data/flutter_assets/...\\*.db');
    exit(1);
  }

  print('📁 Found database: $dbPath\n');

  final db = await factory.openDatabase(dbPath);

  try {
    // Check if sync_queue table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_queue'",
    );

    if (tables.isEmpty) {
      print('ℹ️  No sync_queue table found - nothing to clean');
      return;
    }

    // Count pending attendance punches
    final countResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM sync_queue 
      WHERE module = 'attendance' OR module = 'ponchado'
    ''');
    
    final count = countResult.first['count'] as int;
    
    if (count == 0) {
      print('✅ No pending attendance punches found - queue is clean');
      return;
    }

    print('⚠️  Found $count pending attendance punch(es) in sync queue');
    print('');
    print('These are likely causing 400 errors in backend logs:');
    print('  POST /api/attendance/punches 400 ~3ms - 46');
    print('');
    print('Waiting 3 seconds... Press Ctrl+C to cancel');
    await Future.delayed(const Duration(seconds: 3));

    // Delete pending attendance punches
    final deleted = await db.rawDelete('''
      DELETE FROM sync_queue 
      WHERE module = 'attendance' OR module = 'ponchado'
    ''');

    print('');
    print('✅ Deleted $deleted pending punch record(s) from sync queue');
    print('');
    print('Next steps:');
    print('  1. Restart the Flutter app');
    print('  2. Backend should stop showing 400 spam');
    print('  3. Users can create new punches normally');
    print('');

  } finally {
    await db.close();
  }
}

Future<String?> _findDatabasePath() async {
  // Try common locations
  final candidates = <String>[];

  // Windows AppData
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null) {
      final dbDir = p.join(appData, 'fulltech_app');
      if (Directory(dbDir).existsSync()) {
        final files = Directory(dbDir)
            .listSync()
            .where((f) => f.path.endsWith('.db'))
            .map((f) => f.path)
            .toList();
        candidates.addAll(files);
      }
    }
  }

  // Build output folders
  final buildPaths = [
    'build/windows/runner/Debug/data/flutter_assets',
    'build/windows/runner/Release/data/flutter_assets',
    'build/windows/x64/runner/Debug/data/flutter_assets',
    'build/windows/x64/runner/Release/data/flutter_assets',
  ];

  for (final buildPath in buildPaths) {
    final dir = Directory(buildPath);
    if (dir.existsSync()) {
      final files = dir
          .listSync(recursive: true)
          .where((f) => f.path.endsWith('.db'))
          .map((f) => f.path)
          .toList();
      candidates.addAll(files);
    }
  }

  // Return first found
  if (candidates.isNotEmpty) {
    return candidates.first;
  }

  return null;
}
