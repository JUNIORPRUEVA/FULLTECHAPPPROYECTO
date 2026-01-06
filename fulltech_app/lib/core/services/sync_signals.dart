import 'dart:async';

/// Lightweight in-app signal bus to trigger best-effort sync runs.
///
/// This intentionally avoids Riverpod dependencies so it can be used from
/// low-level storage layers (LocalDb) without creating circular deps.
class SyncSignals {
  SyncSignals._();

  static final SyncSignals instance = SyncSignals._();

  final StreamController<void> _queueChanged = StreamController<void>.broadcast();

  Stream<void> get onQueueChanged => _queueChanged.stream;

  void notifyQueueChanged() {
    if (_queueChanged.isClosed) return;
    _queueChanged.add(null);
  }

  Future<void> dispose() async {
    await _queueChanged.close();
  }
}
