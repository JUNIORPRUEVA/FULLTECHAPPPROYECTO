import 'package:flutter/material.dart';

import '../../../constants/crm_statuses.dart';
import '../../../../catalogo/models/producto.dart';

enum FollowupMessageType { text, image }

class CrmFollowupScheduleConfig {
  final DateTime runAtLocal;
  final int repeatCount;
  final int intervalDays;
  final String? onlyStatus;
  final String? onlyProductId;
  final FollowupMessageType messageType;
  final String text;
  final String? mediaUrl;

  const CrmFollowupScheduleConfig({
    required this.runAtLocal,
    required this.repeatCount,
    required this.intervalDays,
    required this.onlyStatus,
    required this.onlyProductId,
    required this.messageType,
    required this.text,
    required this.mediaUrl,
  });

  int get intervalMinutes => intervalDays * 24 * 60;

  Map<String, dynamic> toPayloadJson() {
    if (messageType == FollowupMessageType.image) {
      return {
        'type': 'image',
        'text': text.trim().isEmpty ? null : text.trim(),
        'mediaUrl': (mediaUrl ?? '').trim(),
      };
    }
    return {'type': 'text', 'text': text.trim()};
  }

  Map<String, dynamic>? toConstraintsJson() {
    final s = (onlyStatus ?? '').trim();
    final p = (onlyProductId ?? '').trim();
    if (s.isEmpty && p.isEmpty) return null;
    return {
      if (s.isNotEmpty) 'status': s,
      if (p.isNotEmpty) 'productId': p,
    };
  }
}

Future<CrmFollowupScheduleConfig?> showCrmFollowupScheduleDialog(
  BuildContext context, {
  required String chatDisplayName,
  required List<Producto> products,
  String? initialStatus,
  String? initialProductId,
}) {
  return showDialog<CrmFollowupScheduleConfig?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CrmFollowupScheduleDialog(
      chatDisplayName: chatDisplayName,
      products: products,
      initialStatus: initialStatus,
      initialProductId: initialProductId,
    ),
  );
}

class _CrmFollowupScheduleDialog extends StatefulWidget {
  final String chatDisplayName;
  final List<Producto> products;
  final String? initialStatus;
  final String? initialProductId;

  const _CrmFollowupScheduleDialog({
    required this.chatDisplayName,
    required this.products,
    required this.initialStatus,
    required this.initialProductId,
  });

  @override
  State<_CrmFollowupScheduleDialog> createState() =>
      _CrmFollowupScheduleDialogState();
}

class _CrmFollowupScheduleDialogState extends State<_CrmFollowupScheduleDialog> {
  DateTime _runAtLocal = DateTime.now().add(const Duration(hours: 2));
  int _repeatCount = 1;
  int _intervalDays = 1;

  bool _filterByStatus = false;
  bool _filterByProduct = false;
  String? _onlyStatus;
  String? _onlyProductId;

  FollowupMessageType _type = FollowupMessageType.text;
  final _textCtrl = TextEditingController();
  final _mediaUrlCtrl = TextEditingController();

  String? _error;

  @override
  void initState() {
    super.initState();
    _onlyStatus = widget.initialStatus;
    _onlyProductId = widget.initialProductId;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _mediaUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _runAtLocal,
    );
    if (!mounted) return;
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_runAtLocal),
    );
    if (!mounted) return;
    if (time == null) return;

    setState(() {
      _runAtLocal = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    setState(() => _error = null);

    final runAt = _runAtLocal;
    if (runAt.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      setState(() => _error = 'La fecha/hora debe ser futura.');
      return;
    }

    final text = _textCtrl.text.trim();
    if (_type == FollowupMessageType.text && text.isEmpty) {
      setState(() => _error = 'Escribe el mensaje.');
      return;
    }

    final mediaUrl = _mediaUrlCtrl.text.trim();
    if (_type == FollowupMessageType.image && mediaUrl.isEmpty) {
      setState(() => _error = 'Coloca una URL de imagen.');
      return;
    }

    Navigator.of(context).pop(
      CrmFollowupScheduleConfig(
        runAtLocal: _runAtLocal,
        repeatCount: _repeatCount,
        intervalDays: _intervalDays,
        onlyStatus: _filterByStatus ? _onlyStatus : null,
        onlyProductId: _filterByProduct ? _onlyProductId : null,
        messageType: _type,
        text: _textCtrl.text,
        mediaUrl: _type == FollowupMessageType.image ? mediaUrl : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final products = widget.products.where((p) => p.isActive).toList();

    String fmtDateTime(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.alarm, color: cs.primary),
          const SizedBox(width: 10),
          const Expanded(child: Text('Programar seguimiento')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.chatDisplayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // When
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Cuándo enviar',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickDateTime,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(fmtDateTime(_runAtLocal)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _repeatCount,
                              decoration: const InputDecoration(
                                labelText: 'Repeticiones',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: const [1, 2, 3, 5, 10, 20]
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text('$v'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _repeatCount = v ?? 1;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _intervalDays,
                              decoration: const InputDecoration(
                                labelText: 'Cada (días)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: const [1, 2, 3, 7, 14]
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text('$v'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _intervalDays = v ?? 1;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Conditions
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Condiciones (opcional)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _filterByStatus,
                        onChanged: (v) => setState(() => _filterByStatus = v),
                        title: const Text('Solo si el chat está en este estado'),
                      ),
                      if (_filterByStatus)
                        DropdownButtonFormField<String?>(
                          value: _onlyStatus,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Selecciona...'),
                            ),
                            ...CrmStatuses.ordered.map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(CrmStatuses.getLabel(s)),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _onlyStatus = v),
                        ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _filterByProduct,
                        onChanged: (v) => setState(() => _filterByProduct = v),
                        title:
                            const Text('Solo si el chat tiene este producto'),
                      ),
                      if (_filterByProduct)
                        DropdownButtonFormField<String?>(
                          value: _onlyProductId,
                          decoration: const InputDecoration(
                            labelText: 'Producto',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Selecciona...'),
                            ),
                            ...products.map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  p.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _onlyProductId = v),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Message
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Contenido',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<FollowupMessageType>(
                        segments: const [
                          ButtonSegment(
                            value: FollowupMessageType.text,
                            label: Text('Texto'),
                            icon: Icon(Icons.sms),
                          ),
                          ButtonSegment(
                            value: FollowupMessageType.image,
                            label: Text('Imagen'),
                            icon: Icon(Icons.image),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (set) {
                          setState(() => _type = set.first);
                        },
                      ),
                      const SizedBox(height: 10),
                      if (_type == FollowupMessageType.image) ...[
                        TextField(
                          controller: _mediaUrlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'URL de imagen',
                            hintText: 'https://...',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextField(
                        controller: _textCtrl,
                        minLines: 3,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: _type == FollowupMessageType.image
                              ? 'Texto (caption opcional)'
                              : 'Mensaje',
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save),
          label: const Text('Programar'),
        ),
      ],
    );
  }
}
