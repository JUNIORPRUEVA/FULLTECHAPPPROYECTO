import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_config.dart';
import '../../data/models/maintenance_models.dart';
import '../../providers/maintenance_provider.dart';

String _publicUrlFromMaybeRelative(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return '';
  if (v.startsWith('http://') || v.startsWith('https://')) return v;

  final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api$'), '');
  if (v.startsWith('/')) return '$base$v';
  return '$base/$v';
}

class CreateWarrantyDialog extends ConsumerStatefulWidget {
  const CreateWarrantyDialog({super.key});

  @override
  ConsumerState<CreateWarrantyDialog> createState() =>
      _CreateWarrantyDialogState();
}

class _CreateWarrantyDialogState extends ConsumerState<CreateWarrantyDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _productoId;

  final _problemCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _ticketCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _problemCtrl.dispose();
    _supplierCtrl.dispose();
    _ticketCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (_productoId == null || _productoId!.trim().isEmpty) return;

    final dto = CreateWarrantyDto(
      productoId: _productoId!,
      problemDescription: _problemCtrl.text.trim(),
      supplierName: _supplierCtrl.text.trim().isEmpty
          ? null
          : _supplierCtrl.text.trim(),
      supplierTicket: _ticketCtrl.text.trim().isEmpty
          ? null
          : _ticketCtrl.text.trim(),
    );

    setState(() => _saving = true);
    try {
      await ref.read(warrantyControllerProvider.notifier).createWarranty(dto);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el caso de garantía.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(maintenanceProductsProvider);

    return AlertDialog(
      title: const Text('Nuevo caso de garantía'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                productsAsync.when(
                  data: (items) {
                    return DropdownButtonFormField<String>(
                      value: _productoId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        border: OutlineInputBorder(),
                      ),
                      items: items
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p.id,
                              child: Row(
                                children: [
                                  if (p.imagenUrl.trim().isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        _publicUrlFromMaybeRelative(
                                          p.imagenUrl,
                                        ),
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: Icon(
                                                Icons.inventory_2,
                                                size: 18,
                                              ),
                                            ),
                                      ),
                                    )
                                  else
                                    const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: Icon(Icons.inventory_2, size: 18),
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      p.nombre,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'RD\$${p.precioVenta.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _productoId = v),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Selecciona un producto'
                          : null,
                    );
                  },
                  error: (_, __) =>
                      const Text('No se pudieron cargar productos.'),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: LinearProgressIndicator(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _problemCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del problema',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Describe el problema'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _supplierCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Proveedor (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ticketCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ticket (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('Crear'),
        ),
      ],
    );
  }
}
