import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/state/auth_providers.dart';
import '../../../auth/state/auth_state.dart';
import '../../providers/punch_provider.dart';

/// Global, silent best-effort sync for Attendance (Ponchado).
///
/// Guarantees are not possible when the app is fully closed by the OS,
/// but while the app is running it will:
/// - try syncing on login
/// - try syncing when connectivity returns
/// - try syncing when the app is resumed
/// - periodically try syncing (throttled)
class AutoAttendanceSync extends ConsumerStatefulWidget {
  final Widget child;

  const AutoAttendanceSync({super.key, required this.child});

  @override
  ConsumerState<AutoAttendanceSync> createState() => _AutoAttendanceSyncState();
}

class _AutoAttendanceSyncState extends ConsumerState<AutoAttendanceSync>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodic;
  ProviderSubscription<AuthState>? _authSub;

  bool _syncInProgress = false;
  DateTime _lastAttempt = DateTime.fromMillisecondsSinceEpoch(0);

  static const _minInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authSub = ref.listenManual<AuthState>(authControllerProvider, (
      prev,
      next,
    ) {
      if (next is AuthAuthenticated) {
        _scheduleSync();
      }
    });

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) _scheduleSync();
    });

    // DISABLED: Periodic sync causes 401 spam when not authenticated
    // _periodic = Timer.periodic(_periodicInterval, (_) {
    //   _scheduleSync();
    // });

    // DO NOT sync on startup - wait until user is authenticated
    // The auth listener above will trigger sync when login completes
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
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
      final repo = ref.read(punchRepositoryProvider);
      await repo.syncPending();
    } catch (e) {
      // Silently catch errors to prevent spam
      // Only log in debug mode
      assert(() {
        print('[AutoAttendanceSync] Sync failed: $e');
        return true;
      }());
    } finally {
      _syncInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
