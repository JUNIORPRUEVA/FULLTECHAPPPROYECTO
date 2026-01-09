import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Serializes all database write operations to prevent lock contention.
///
/// Usage:
/// ```dart
/// await dbWriteQueue.enqueue(() async {
///   await db.insert(...);
///   await db.update(...);
/// });
/// ```
class DbWriteQueue {
  final _queue = Queue<_QueuedWrite>();
  bool _isProcessing = false;

  /// Enqueue a database write operation.
  /// Returns a Future that completes when the operation finishes.
  Future<T> enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    final queued = _QueuedWrite(operation, completer);
    _queue.add(queued);

    _processQueue();

    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final write = _queue.removeFirst();
      final startTime = DateTime.now();

      try {
        final result = await write.operation();
        write.completer.complete(result);

        if (kDebugMode) {
          final duration = DateTime.now().difference(startTime);
          if (duration.inMilliseconds > 100) {
            debugPrint(
              '[DB_QUEUE] Slow operation: ${duration.inMilliseconds}ms',
            );
          }
        }
      } catch (e, st) {
        write.completer.completeError(e, st);
        if (kDebugMode) {
          debugPrint('[DB_QUEUE] Operation failed: $e');
        }
      }
    }

    _isProcessing = false;
  }

  /// Get the current queue length (for debugging).
  int get queueLength => _queue.length;
}

class _QueuedWrite<T> {
  final Future<T> Function() operation;
  final Completer<T> completer;

  _QueuedWrite(this.operation, this.completer);
}

/// Global singleton for database write operations.
final dbWriteQueue = DbWriteQueue();
