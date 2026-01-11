import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fulltech_app/core/widgets/module_page.dart';
import 'package:fulltech_app/features/cartas/models/letter_models.dart';
import 'package:fulltech_app/features/cartas/state/letters_providers.dart';
import 'package:fulltech_app/features/cotizaciones/state/cotizaciones_providers.dart';
import 'package:fulltech_app/features/auth/state/auth_providers.dart';

class CrearCartasScreen extends ConsumerStatefulWidget {
  const CrearCartasScreen({super.key});

  @override
  ConsumerState<CrearCartasScreen> createState() => _CrearCartasScreenState();
}

class _CrearCartasScreenState extends ConsumerState<CrearCartasScreen> {
  bool _loading = false;
  List<Letter> _letters = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(lettersApiProvider);
      final letters = await api.listLetters(
        q: _searchQuery.isNotEmpty ? _searchQuery : null,
        limit: 50,
      );
      setState(() {
        _letters = letters;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando cartas: $e')));
      }
    }
  }

  Future<void> _deleteLetter(String letterId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Carta'),
        content: const Text('¿Estás seguro de que deseas eliminar esta carta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ref.read(lettersApiProvider);
      await api.deleteLetter(letterId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Carta eliminada')));
      _loadLetters();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Cartas',
      actions: const [],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar cartas...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadLetters();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _letters.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mail_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text('No hay cartas'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _letters.length,
                    itemBuilder: (context, index) {
                      final letter = _letters[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.mail)),
                          title: Text(letter.subject),
                          subtitle: Text(
                            '${letter.customerName} • ${_formatDate(letter.createdAt)}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'ver') {
                                context.go('/crear-cartas/${letter.id}');
                              } else if (value == 'eliminar') {
                                _deleteLetter(letter.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'ver',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility),
                                    SizedBox(width: 8),
                                    Text('Ver detalle'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'eliminar',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Eliminar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => context.go('/crear-cartas/${letter.id}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class CreateLetterDialog extends ConsumerStatefulWidget {
  final VoidCallback onCreated;

  const CreateLetterDialog({super.key, required this.onCreated});

  @override
  ConsumerState<CreateLetterDialog> createState() => _CreateLetterDialogState();
}

class _CreateLetterDialogState extends ConsumerState<CreateLetterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _detallesCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();

  String _letterType = 'general';
  String _tone = 'Formal';
  bool _includeQuotation = false;
  String? _selectedQuotationId;
  List<Map<String, dynamic>> _quotations = [];
  bool _loading = false;
  bool _showPreview = false;
  String _generatedSubject = '';
  String _generatedBody = '';

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _detallesCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuotations() async {
    try {
      final session = await ref.read(localDbProvider).readSession();
      if (session == null) return;

      final repo = ref.read(quotationRepositoryProvider);
      final quotations = await repo.listLocal(
        empresaId: session.user.empresaId,
        limit: 100,
      );
      setState(() {
        _quotations = quotations;
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _generateWithAI() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate customer info if no quotation
    if (!_includeQuotation || _selectedQuotationId == null) {
      if (_customerNameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Nombre del cliente es obligatorio')),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final api = ref.read(lettersApiProvider);

      final request = GenerateLetterRequest(
        letterType: _letterType,
        tone: _tone,
        quotationId: _includeQuotation ? _selectedQuotationId : null,
        customer: (_includeQuotation && _selectedQuotationId != null)
            ? null
            : CustomerInfo(
                name: _customerNameCtrl.text.trim(),
                phone: _customerPhoneCtrl.text.trim().isEmpty
                    ? null
                    : _customerPhoneCtrl.text.trim(),
              ),
        details: _detallesCtrl.text.trim(),
        context: _detallesCtrl.text.trim(),
      );

      final response = await api.generateWithAI(request);

      setState(() {
        _generatedSubject = response.subject;
        _generatedBody = response.body;
        _showPreview = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error generando carta: $e')));
      }
    }
  }

  Future<void> _saveLetter() async {
    if (_generatedSubject.isEmpty || _generatedBody.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Genera la carta primero')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final api = ref.read(lettersApiProvider);

      String customerName = _customerNameCtrl.text.trim();
      String? customerPhone = _customerPhoneCtrl.text.trim().isEmpty
          ? null
          : _customerPhoneCtrl.text.trim();

      // If quotation is selected, get customer info from it
      if (_includeQuotation && _selectedQuotationId != null) {
        final quotation = _quotations.firstWhere(
          (q) => q['id'] == _selectedQuotationId,
          orElse: () => {},
        );
        if (quotation.isNotEmpty) {
          customerName = quotation['customer_name'] as String? ?? customerName;
          customerPhone =
              quotation['customer_phone'] as String? ?? customerPhone;
        }
      }

      final request = CreateLetterRequest(
        quotationId: _includeQuotation ? _selectedQuotationId : null,
        customerName: customerName,
        customerPhone: customerPhone,
        letterType: _letterType,
        subject: _generatedSubject,
        body: _generatedBody,
        status: 'SAVED',
      );

      await api.createLetter(request);

      setState(() => _loading = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Carta guardada')));
        widget.onCreated();
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showPreview) {
      return _buildPreview();
    }

    return AlertDialog(
      title: const Text('Crear Carta con IA'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _letterType,
                  decoration: const InputDecoration(labelText: 'Tipo de carta'),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(
                      value: 'presentacion',
                      child: Text('Presentación'),
                    ),
                    DropdownMenuItem(
                      value: 'propuesta',
                      child: Text('Propuesta'),
                    ),
                    DropdownMenuItem(
                      value: 'seguimiento',
                      child: Text('Seguimiento'),
                    ),
                    DropdownMenuItem(
                      value: 'agradecimiento',
                      child: Text('Agradecimiento'),
                    ),
                    DropdownMenuItem(
                      value: 'solicitud',
                      child: Text('Solicitud'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _letterType = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _tone,
                  decoration: const InputDecoration(labelText: 'Tono'),
                  items: const [
                    DropdownMenuItem(value: 'Formal', child: Text('Formal')),
                    DropdownMenuItem(
                      value: 'Ejecutivo',
                      child: Text('Ejecutivo'),
                    ),
                    DropdownMenuItem(value: 'Cercano', child: Text('Cercano')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _tone = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _detallesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Detalles / Contexto',
                    hintText: 'Describe qué quieres que incluya la carta...',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Incluir cotización'),
                  value: _includeQuotation,
                  onChanged: (value) {
                    setState(() => _includeQuotation = value);
                  },
                ),
                if (_includeQuotation) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedQuotationId,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar cotización',
                    ),
                    items: _quotations
                        .map(
                          (q) => DropdownMenuItem(
                            value: q['id'] as String,
                            child: Text(
                              '${q['numero']} - ${q['customer_name']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedQuotationId = value);
                    },
                  ),
                ],
                if (!_includeQuotation || _selectedQuotationId == null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Datos del cliente',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del cliente *',
                    ),
                    validator: (value) {
                      if (!_includeQuotation &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerPhoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono del cliente',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _generateWithAI,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: const Text('Generar con IA'),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return AlertDialog(
      title: const Text('Vista Previa de la Carta'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Asunto:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: TextEditingController(text: _generatedSubject),
                onChanged: (value) => _generatedSubject = value,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text(
                'Contenido:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: TextEditingController(text: _generatedBody),
                onChanged: (value) => _generatedBody = value,
                maxLines: 15,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() => _showPreview = false);
          },
          child: const Text('Volver'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _saveLetter,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('Guardar Carta'),
        ),
      ],
    );
  }
}
