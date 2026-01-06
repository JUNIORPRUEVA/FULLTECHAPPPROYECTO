import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/state/auth_providers.dart';
import '../../features/auth/state/auth_state.dart';
import '../../features/cotizaciones/state/cotizaciones_providers.dart';
import '../../features/cotizaciones/state/letters_providers.dart';
import '../../features/maintenance/providers/maintenance_provider.dart';
import '../../features/operaciones/state/operations_providers.dart';
import '../../features/ponchado/providers/punch_provider.dart';
import '../../features/ventas/state/ventas_providers.dart';
import '../services/http_queue_sync_service.dart';
import '../services/sync_signals.dart';

/// Global, silent best-effort sync for all offline-first modules.
///
/// While the app is running it will:
/// - try syncing on login
/// - try syncing when connectivity returns
/// - try syncing when the app is resumed
/// - periodically try syncing (throttled)
///
/// This uses the existing per-module sync logic already implemented in
/// repositories (e.g. `syncPending()`), plus a simple retry mechanism
/// for previously errored queue items.
class AutoSync extends ConsumerStatefulWidget {
  final Widget child;

  const AutoSync({super.key, required this.child});

  @override
  ConsumerState<AutoSync> createState() => _AutoSyncState();
}

class _AutoSyncState extends ConsumerState<AutoSync> with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<void>? _queueChangedSub;
  Timer? _periodic;
  ProviderSubscription<AuthState>? _authSub;

  bool _syncInProgress = false;
  DateTime _lastAttempt = DateTime.fromMillisecondsSinceEpoch(0);

  static const _minInterval = Duration(seconds: 10);
  static const _periodicInterval = Duration(seconds: 45);
  static const _retryErroredMinAge = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authSub = ref.listenManual<AuthState>(authControllerProvider, (prev, next) {
      if (next is AuthAuthenticated) {
        _scheduleSync();
      }
    });

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) _scheduleSync();
    });

    _queueChangedSub = SyncSignals.instance.onQueueChanged.listen((_) {
      // New queued work: try syncing quickly.
      _scheduleSync();
    });

    _periodic = Timer.periodic(_periodicInterval, (_) {
      _scheduleSync();
    });

    // Best effort: try early during startup.
    Future.microtask(_scheduleSync);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _queueChangedSub?.cancel();
    _periodic?.cancel();
    _authSub?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleSync();
    }
  }

  void _scheduleSync() {
    if (!mounted) return;

    final now = DateTime.now();
    if (_syncInProgress) return;
    if (now.difference(_lastAttempt) < _minInterval) return;

    _lastAttempt = now;
    // ignore: unawaited_futures
    _runSync();
  }

  Future<void> _runSync() async {
    if (_syncInProgress) return;

    final auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) return;

    _syncInProgress = true;
    try {
      final db = ref.read(localDbProvider);

      // Retry previously-errored items (simple, throttled by _scheduleSync).
      await db.retryErroredSyncItems(minAge: _retryErroredMinAge);

      // Generic queued HTTP requests (used by modules that don't have a dedicated syncPending yet).
      final httpSync = ref.read(httpQueueSyncServiceProvider);
      await httpSync.flushPending();

      // --- Attendance (Ponchado)
      final punchRepo = ref.read(punchRepositoryProvider);
      await punchRepo.retryFailed();
      await punchRepo.syncPending();

      // --- Sales
      final salesRepo = ref.read(salesRepositoryProvider);
      await salesRepo.syncPending();

      // --- Cotizaciones
      final quotationRepo = ref.read(quotationRepositoryProvider);
      await quotationRepo.syncPending();

      // --- Cartas (Letters)
      final lettersRepo = ref.read(lettersRepositoryProvider);
      await lettersRepo.syncPending();

      // --- Operations
      final operationsRepo = ref.read(operationsRepositoryProvider);
      await operationsRepo.syncPending();

      // --- Maintenance
      final maintenanceRepo = ref.read(maintenanceRepositoryProvider);
      await maintenanceRepo.syncPending();
    } finally {
      _syncInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
