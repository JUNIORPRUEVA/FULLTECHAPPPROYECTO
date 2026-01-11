import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_instance.dart';
import '../state/crm_instances_providers.dart';

class CrmInstanceConfigScreen extends ConsumerStatefulWidget {
  const CrmInstanceConfigScreen({super.key});

  @override
  ConsumerState<CrmInstanceConfigScreen> createState() =>
      _CrmInstanceConfigScreenState();
}

class _CrmInstanceConfigScreenState
    extends ConsumerState<CrmInstanceConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instanceNameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _isLoading = false;
  bool _isTesting = false;
  bool _obscureApiKey = true;
  CrmInstance? _currentInstance;

  @override
  void dispose() {
    _instanceNameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentInstance() async {
    try {
      final instance = await ref.read(crmActiveInstanceProvider.future);
      if (instance != null) {
        setState(() {
          _currentInstance = instance;
          _instanceNameController.text = instance.nombreInstancia;
          _baseUrlController.text = instance.evolutionBaseUrl;
          // Don't populate API key for security - user must re-enter to update
        });
      }
    } catch (e) {
      // No active instance yet
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      final test = ref.read(testCrmConnectionProvider);
      final result = await test(
        nombreInstancia: _instanceNameController.text.trim(),
        evolutionBaseUrl: _baseUrlController.text.trim(),
        evolutionApiKey: _apiKeyController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Conexión exitosa: ${result['message'] ?? 'OK'}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _saveInstance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_currentInstance == null) {
        // Create new instance
        final create = ref.read(createCrmInstanceProvider);
        await create(
          nombreInstancia: _instanceNameController.text.trim(),
          evolutionBaseUrl: _baseUrlController.text.trim(),
          evolutionApiKey: _apiKeyController.text.trim(),
        );
      } else {
        // Update existing instance
        final update = ref.read(updateCrmInstanceProvider);
        await update(
          _currentInstance!.id,
          nombreInstancia: _instanceNameController.text.trim(),
          evolutionBaseUrl: _baseUrlController.text.trim(),
          // Only update API key if provided
          evolutionApiKey: _apiKeyController.text.isNotEmpty
              ? _apiKeyController.text.trim()
              : null,
        );
      }

      if (!mounted) return;

      // Invalidate providers to refresh
      ref.invalidate(crmActiveInstanceProvider);
      ref.invalidate(crmInstancesListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Configuración guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Instancia Evolution'),
        backgroundColor: const Color(0xFF0D47A1), // Corporate dark blue
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Configuración de Instancia',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configura tu propia instancia de Evolution API. '
                        'Todos los chats y mensajes estarán aislados por instancia.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Instance Name
              TextFormField(
                controller: _instanceNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Instancia *',
                  hintText: 'Ejemplo: junior01',
                  prefixIcon: Icon(Icons.label_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre de instancia es requerido';
                  }
                  if (value.trim().length < 3) {
                    return 'Mínimo 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Base URL
              TextFormField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL Base de Evolution API *',
                  hintText: 'https://tu-evolution-api.com',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La URL es requerida';
                  }
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return 'Debe ser una URL válida (http:// o https://)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // API Key
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: _currentInstance == null
                      ? 'API Key *'
                      : 'API Key (dejar vacío para mantener actual)',
                  hintText: 'Tu clave API de Evolution',
                  prefixIcon: const Icon(Icons.key),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureApiKey = !_obscureApiKey);
                    },
                  ),
                ),
                obscureText: _obscureApiKey,
                validator: (value) {
                  // Only required for new instances
                  if (_currentInstance == null &&
                      (value == null || value.trim().isEmpty)) {
                    return 'La API Key es requerida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Test Connection Button
              OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check),
                label: Text(
                  _isTesting ? 'Probando conexión...' : 'Probar Conexión',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),

              // Save Button
              FilledButton.icon(
                onPressed: _isLoading ? null : _saveInstance,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Guardando...' : 'Guardar'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: const Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentInstance();
    });
  }
}
