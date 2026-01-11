import 'package:flutter/material.dart';

import '../../../constants/crm_statuses.dart';
import '../../../../catalogo/models/producto.dart';
import 'crm_followup_schedule_dialog.dart';

class CrmBulkFollowupConfig {
  final DateTime runAtLocal;
  final int repeatCount;
  final int intervalDays;
  final DateTime? lastMessageFromLocal;
  final DateTime? lastMessageToLocal;
  final String? status;
  final String? productId;
  final String? onlyStatusConstraint;
  final String? onlyProductConstraint;
  final FollowupMessageType messageType;
  final String text;
  final String? mediaUrl;

  const CrmBulkFollowupConfig({
    required this.runAtLocal,
    required this.repeatCount,
    required this.intervalDays,
    required this.lastMessageFromLocal,
    required this.lastMessageToLocal,
    required this.status,
    required this.productId,
    required this.onlyStatusConstraint,
    required this.onlyProductConstraint,
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

  Map<String, dynamic> toFilterJson() {
    return {
      if (status != null && status!.trim().isNotEmpty) 'status': status!.trim(),
      if (productId != null && productId!.trim().isNotEmpty) 'productId': productId!.trim(),
      if (lastMessageFromLocal != null)
        'lastMessageFrom': lastMessageFromLocal!.toUtc().toIso8601String(),
      if (lastMessageToLocal != null)
        'lastMessageTo': lastMessageToLocal!.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic>? toConstraintsJson() {
    final s = (onlyStatusConstraint ?? '').trim();
    final p = (onlyProductConstraint ?? '').trim();
    if (s.isEmpty && p.isEmpty) return null;
    return {
      if (s.isNotEmpty) 'status': s,
      if (p.isNotEmpty) 'productId': p,
    };
  }
}

Future<CrmBulkFollowupConfig?> showCrmBulkFollowupDialog(
  BuildContext context, {
  required List<Producto> products,
  String? currentStatus,
  String? currentProductId,
}) {
  return showDialog<CrmBulkFollowupConfig?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CrmBulkFollowupDialog(
      products: products,
      currentStatus: currentStatus,
      currentProductId: currentProductId,
    ),
  );
}

class _CrmBulkFollowupDialog extends StatefulWidget {
  final List<Producto> products;
  final String? currentStatus;
  final String? currentProductId;

  const _CrmBulkFollowupDialog({
    required this.products,
    required this.currentStatus,
    required this.currentProductId,
  });

  @override
  State<_CrmBulkFollowupDialog> createState() => _CrmBulkFollowupDialogState();
}

class _CrmBulkFollowupDialogState extends State<_CrmBulkFollowupDialog> {
  DateTime _runAtLocal = DateTime.now().add(const Duration(hours: 2));
  int _repeatCount = 1;
  int _intervalDays = 1;

  DateTime? _lastFrom;
  DateTime? _lastTo;
  String? _status;
  String? _productId;

  bool _constraintByStatus = false;
  bool _constraintByProduct = false;
  String? _onlyStatus;
  String? _onlyProductId;

  FollowupMessageType _type = FollowupMessageType.text;
  final _textCtrl = TextEditingController();
  final _mediaUrlCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
    _productId = widget.currentProductId;
    _onlyStatus = widget.currentStatus;
    _onlyProductId = widget.currentProductId;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _mediaUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRunAt() async {
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

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _lastFrom ?? now.subtract(const Duration(days: 7)),
    );
    if (!mounted) return;
    if (date == null) return;
    setState(() => _lastFrom = DateTime(date.year, date.month, date.day));
  }

  Future<void> _pickTo() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _lastTo ?? now,
    );
    if (!mounted) return;
    if (date == null) return;
    setState(() => _lastTo = DateTime(date.year, date.month, date.day, 23, 59));
  }

  void _submit() {
    setState(() => _error = null);

    if (_runAtLocal.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      setState(() => _error = 'La fecha/hora de envío debe ser futura.');
      return;
    }

    if (_lastFrom != null && _lastTo != null && _lastFrom!.isAfter(_lastTo!)) {
      setState(() => _error = 'Rango de fechas inválido (desde > hasta).');
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
      CrmBulkFollowupConfig(
        runAtLocal: _runAtLocal,
        repeatCount: _repeatCount,
        intervalDays: _intervalDays,
        lastMessageFromLocal: _lastFrom,
        lastMessageToLocal: _lastTo,
        status: _status,
        productId: _productId,
        onlyStatusConstraint: _constraintByStatus ? _onlyStatus : null,
        onlyProductConstraint: _constraintByProduct ? _onlyProductId : null,
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

    String fmtDate(DateTime? d) {
      if (d == null) return 'No';
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    String fmtDateTime(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.campaign, color: cs.primary),
          const SizedBox(width: 10),
          const Expanded(child: Text('Seguimientos generales')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Filtro de clientes',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickFrom,
                              icon: const Icon(Icons.date_range),
                              label: Text('Desde: ${fmtDate(_lastFrom)}'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickTo,
                              icon: const Icon(Icons.date_range),
                              label: Text('Hasta: ${fmtDate(_lastTo)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'Estado',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Todos'),
                                ),
                                ...CrmStatuses.ordered.map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(CrmStatuses.getLabel(s)),
                                  ),
                                ),
                              ],
                              onChanged: (v) => setState(() => _status = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _productId,
                              decoration: const InputDecoration(
                                labelText: 'Producto',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Todos'),
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
                              onChanged: (v) => setState(() => _productId = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                        onPressed: _pickRunAt,
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
                              items: const [1, 2, 3, 5, 10]
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _intervalDays,
                              decoration: const InputDecoration(
                                labelText: 'Cada (días)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: const [1, 2, 3, 7]
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
                        value: _constraintByStatus,
                        onChanged: (v) => setState(() => _constraintByStatus = v),
                        title: const Text('Solo enviar si el chat sigue en este estado'),
                      ),
                      if (_constraintByStatus)
                        DropdownButtonFormField<String?>(
                          value: _onlyStatus,
                          decoration: const InputDecoration(
                            labelText: 'Estado requerido',
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
                        value: _constraintByProduct,
                        onChanged: (v) => setState(() => _constraintByProduct = v),
                        title: const Text('Solo enviar si el chat sigue con este producto'),
                      ),
                      if (_constraintByProduct)
                        DropdownButtonFormField<String?>(
                          value: _onlyProductId,
                          decoration: const InputDecoration(
                            labelText: 'Producto requerido',
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
                        onSelectionChanged: (set) => setState(() => _type = set.first),
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
