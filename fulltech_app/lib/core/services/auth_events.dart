import 'dart:async';

enum AuthEventType {
  unauthorized,
}

class AuthEvent {
  final AuthEventType type;
  final int? statusCode;
  final String? detail;

  const AuthEvent._(this.type, this.statusCode, this.detail);

  const AuthEvent.unauthorized([int? statusCode, String? detail])
    : this._(AuthEventType.unauthorized, statusCode, detail);
}

/// Tiny in-memory event bus to broadcast auth-related events across layers
/// without introducing provider dependency cycles.
class AuthEvents {
  AuthEvents._();

  static final StreamController<AuthEvent> _controller = StreamController<AuthEvent>.broadcast();

  static Stream<AuthEvent> get stream => _controller.stream;

  static void unauthorized([int? statusCode, String? detail]) {
    _controller.add(AuthEvent.unauthorized(statusCode, detail));
  }
}
