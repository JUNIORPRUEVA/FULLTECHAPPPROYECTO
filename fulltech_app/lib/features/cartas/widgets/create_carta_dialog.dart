import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/letter_models.dart';
import '../state/cartas_providers.dart';

class CreateCartaDialog extends ConsumerStatefulWidget {
  final String presupuestoId;
  final String? defaultCotizacionId;
  final String? defaultClienteId;
  final String? defaultCustomerName;
  final String? defaultCustomerPhone;

  const CreateCartaDialog({
    super.key,
    required this.presupuestoId,
    required this.defaultCotizacionId,
    required this.defaultClienteId,
    required this.defaultCustomerName,
    required this.defaultCustomerPhone,
  });

  @override
  ConsumerState<CreateCartaDialog> createState() => _CreateCartaDialogState();
}

class _CartaTypeOption {
  final String value;
  final String label;

  const _CartaTypeOption(this.value, this.label);
}

const _cartaTypes = <_CartaTypeOption>[
  _CartaTypeOption('GARANTIA', 'Garantía'),
  _CartaTypeOption('AGRADECIMIENTO', 'Agradecimiento'),
  _CartaTypeOption('SEGUIMIENTO', 'Seguimiento'),
  _CartaTypeOption('COTIZACION_FORMAL', 'Cotización formal'),
  _CartaTypeOption('DISCULPA_INCIDENCIA', 'Disculpa / Incidencia'),
  _CartaTypeOption('CONFIRMACION_SERVICIO', 'Confirmación de servicio'),
];

class _CreateCartaDialogState extends ConsumerState<CreateCartaDialog> {
  final _formKey = GlobalKey<FormState>();

  final _subjectCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();

  bool _attachQuotation = true;
  String _letterType = _cartaTypes.first.value;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _customerNameCtrl.text = (widget.defaultCustomerName ?? '').trim();
    _customerPhoneCtrl.text = (widget.defaultCustomerPhone ?? '').trim();

    // Provide a sane default subject to reduce friction
    _subjectCtrl.text = 'Carta';
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _instructionsCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final attach = _attachQuotation;
    final cotizacionId = (widget.defaultCotizacionId ?? '').trim();

    if (attach && cotizacionId.isEmpty) {
      _toast('Esta pantalla no tiene cotización para adjuntar.');
      return;
    }

    setState(() => _loading = true);
    try {
      final api = ref.read(cartasApiProvider);
      final req = GenerateCartaRequest(
        presupuestoId: widget.presupuestoId,
        attachQuotation: attach,
        cotizacionId: attach ? cotizacionId : null,
        clienteId: widget.defaultClienteId,
        customerName: _customerNameCtrl.text.trim().isEmpty
            ? null
            : _customerNameCtrl.text.trim(),
        customerPhone: _customerPhoneCtrl.text.trim().isEmpty
            ? null
            : _customerPhoneCtrl.text.trim(),
        letterType: _letterType,
        subject: _subjectCtrl.text.trim(),
        userInstructions: _instructionsCtrl.text.trim(),
      );

      final res = await api.generateCarta(req);
      if (!mounted) return;

      Navigator.of(context).pop(res.item.id);
    } catch (e) {
      if (!mounted) return;
      _toast('❌ No se pudo crear la carta: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAttach = (widget.defaultCotizacionId ?? '').trim().isNotEmpty;

    return AlertDialog(
      title: const Text('Crear carta'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _letterType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de carta',
                    isDense: true,
                  ),
                  items: [
                    for (final t in _cartaTypes)
                      DropdownMenuItem(value: t.value, child: Text(t.label)),
                  ],
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => _letterType = v ?? _letterType),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subjectCtrl,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: 'Asunto',
                    isDense: true,
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Requerido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instructionsCtrl,
                  enabled: !_loading,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Instrucciones para la IA',
                    helperText:
                        'Describe el contexto, lo que quieres lograr y cualquier detalle clave.',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Requerido';
                    if (s.length < 10) return 'Agrega más detalle';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _attachQuotation && canAttach,
                  onChanged: (!_loading && canAttach)
                      ? (v) => setState(() => _attachQuotation = v)
                      : null,
                  title: const Text('Adjuntar esta cotización'),
                  subtitle: Text(
                    canAttach
                        ? 'Incluye un resumen de la cotización en el PDF.'
                        : 'No hay cotización guardada para adjuntar.',
                  ),
                ),
                const SizedBox(height: 8),
                if (!(_attachQuotation && canAttach)) ...[
                  TextFormField(
                    controller: _customerNameCtrl,
                    enabled: !_loading,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del cliente',
                      isDense: true,
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Requerido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customerPhoneCtrl,
                    enabled: !_loading,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono del cliente',
                      hintText: 'Ej: 18095551234',
                      isDense: true,
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Requerido';
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_outlined),
          label: const Text('Generar'),
        ),
      ],
    );
  }
}
