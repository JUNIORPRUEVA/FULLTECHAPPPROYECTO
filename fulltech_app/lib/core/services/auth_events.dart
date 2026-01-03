import 'dart:async';

enum AuthEventType {
  unauthorized,
}

class AuthEvent {
  final AuthEventType type;
  final int? statusCode;

  const AuthEvent._(this.type, this.statusCode);

  const AuthEvent.unauthorized([int? statusCode]) : this._(AuthEventType.unauthorized, statusCode);
}

/// Tiny in-memory event bus to broadcast auth-related events across layers
/// without introducing provider dependency cycles.
class AuthEvents {
  AuthEvents._();

  static final StreamController<AuthEvent> _controller = StreamController<AuthEvent>.broadcast();

  static Stream<AuthEvent> get stream => _controller.stream;

  static void unauthorized([int? statusCode]) {
    _controller.add(AuthEvent.unauthorized(statusCode));
  }
}
