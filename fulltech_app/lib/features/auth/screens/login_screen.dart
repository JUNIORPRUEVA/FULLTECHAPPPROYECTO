import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/theme/app_colors.dart';
import '../state/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
          );
    } catch (e) {
      final baseUrl = ref.read(apiClientProvider).dio.options.baseUrl;

      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;

        String serverMsg = '';
        if (data is Map) {
          final msg = data['message'] ?? data['error'];
          if (msg != null) serverMsg = msg.toString();
        } else if (data != null) {
          serverMsg = data.toString();
        }

        final parts = <String>[];
        parts.add('No se pudo iniciar sesión.');
        if (status != null) {
          parts.add('HTTP $status.');
        } else {
          // In Flutter Web, CORS/network failures usually have no HTTP status.
          parts.add('Error de red/CORS.');
          if (e.message != null && e.message!.trim().isNotEmpty) {
            parts.add(e.message!.trim());
          }
        }
        if (serverMsg.isNotEmpty) parts.add(serverMsg);
        parts.add('API: $baseUrl');

        setState(() => _error = parts.join(' '));
      } else {
        final msg = e.toString();
        setState(
          () => _error = msg.trim().isEmpty
              ? 'No se pudo iniciar sesión. API: $baseUrl'
              : 'No se pudo iniciar sesión. $msg API: $baseUrl',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.secondaryBlack],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.business, size: 34),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FULLTECH',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'CRM & Operaciones',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Iniciar sesión',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email o usuario',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _error!,
                            style: TextStyle(color: cs.error),
                          ),
                        ),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'TODO: agregar recuperación de contraseña y registro por invitación.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
