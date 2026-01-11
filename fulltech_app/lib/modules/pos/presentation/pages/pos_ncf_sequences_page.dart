import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/module_page.dart';
import '../../state/pos_providers.dart';

class PosNcfSequencesPage extends ConsumerStatefulWidget {
  const PosNcfSequencesPage({super.key});

  @override
  ConsumerState<PosNcfSequencesPage> createState() => _PosNcfSequencesPageState();
}

class _PosNcfSequencesPageState extends ConsumerState<PosNcfSequencesPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _items = const [];
  String? _error;

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(posRepositoryProvider);
      final rows = await repo.listNcfSequences();
      if (!mounted) return;
      setState(() {
        _items = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _create() async {
    final res = await showDialog<_NcfSeqDraft>(
      context: context,
      builder: (_) => const _NcfSeqDialog(),
    );
    if (res == null) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(posRepositoryProvider);
      await repo.createNcfSequence(res.toPayload());
      await _refresh();
      _toast('Secuencia creada');
    } catch (e) {
      _toast('Error creando: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final res = await showDialog<_NcfSeqDraft>(
      context: context,
      builder: (_) => _NcfSeqDialog(initial: row),
    );
    if (res == null) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(posRepositoryProvider);
      await repo.updateNcfSequence(row['id'].toString(), res.toPayload());
      await _refresh();
      _toast('Secuencia actualizada');
    } catch (e) {
      _toast('Error actualizando: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar secuencia'),
        content: Text('Eliminar ${row['doc_type']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(posRepositoryProvider);
      await repo.deleteNcfSequence(row['id'].toString());
      await _refresh();
      _toast('Secuencia eliminada');
    } catch (e) {
      _toast('Error eliminando: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'POS / NCF',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Agregar',
          onPressed: _create,
          icon: const Icon(Icons.add),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Sin secuencias configuradas'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = _items[i];
                      final doc = (r['doc_type'] ?? '').toString();
                      final current = _asInt(r['current_number']);
                      final max = r['max_number'] == null ? null : _asInt(r['max_number']);
                      final active = r['active'] == true;
                      final series = (r['series'] ?? '').toString();
                      final prefix = (r['prefix'] ?? '').toString();
                      return ListTile(
                        title: Text('$doc${active ? '' : ' (inactiva)'}'),
                        subtitle: Text(
                          'Actual: $current${max == null ? '' : ' / $max'}  Serie: ${series.isEmpty ? '-' : series}  Prefijo: ${prefix.isEmpty ? '-' : prefix}',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: _loading ? null : () => _edit(r),
                              child: const Text('Editar'),
                            ),
                            OutlinedButton(
                              onPressed: _loading ? null : () => _delete(r),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nota: el NCF se asigna automáticamente al cobrar una venta fiscal.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NcfSeqDraft {
  final String docType;
  final String? series;
  final String? prefix;
  final int currentNumber;
  final int? maxNumber;
  final bool active;

  const _NcfSeqDraft({
    required this.docType,
    required this.series,
    required this.prefix,
    required this.currentNumber,
    required this.maxNumber,
    required this.active,
  });

  Map<String, dynamic> toPayload() => {
        'doc_type': docType,
        'series': series,
        'prefix': prefix,
        'current_number': currentNumber,
        'max_number': maxNumber,
        'active': active,
      };
}

class _NcfSeqDialog extends StatefulWidget {
  const _NcfSeqDialog({this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<_NcfSeqDialog> createState() => _NcfSeqDialogState();
}

class _NcfSeqDialogState extends State<_NcfSeqDialog> {
  late final TextEditingController _docType;
  late final TextEditingController _series;
  late final TextEditingController _prefix;
  late final TextEditingController _current;
  late final TextEditingController _max;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final init = widget.initial ?? const {};
    _docType = TextEditingController(text: (init['doc_type'] ?? '').toString().trim().isEmpty ? 'B01' : init['doc_type'].toString());
    _series = TextEditingController(text: (init['series'] ?? '').toString());
    _prefix = TextEditingController(text: (init['prefix'] ?? '').toString());
    _current = TextEditingController(text: (init['current_number'] ?? 0).toString());
    _max = TextEditingController(text: (init['max_number'] ?? '').toString());
    _active = init['active'] == null ? true : init['active'] == true;
  }

  @override
  void dispose() {
    _docType.dispose();
    _series.dispose();
    _prefix.dispose();
    _current.dispose();
    _max.dispose();
    super.dispose();
  }

  int _parseInt(String s) => int.tryParse(s.trim()) ?? 0;
  int? _parseNullableInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nueva secuencia NCF' : 'Editar secuencia NCF'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _docType,
              decoration: const InputDecoration(labelText: 'Tipo (B01/B02/etc)', isDense: true),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _series,
                    decoration: const InputDecoration(labelText: 'Serie (opcional)', isDense: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _prefix,
                    decoration: const InputDecoration(labelText: 'Prefijo (opcional)', isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _current,
                    decoration: const InputDecoration(labelText: 'Actual', isDense: true),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _max,
                    decoration: const InputDecoration(labelText: 'Hasta (opcional)', isDense: true),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const Text('Activa'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final doc = _docType.text.trim();
            if (doc.isEmpty) return;
            Navigator.pop(
              context,
              _NcfSeqDraft(
                docType: doc,
                series: _series.text.trim().isEmpty ? null : _series.text.trim(),
                prefix: _prefix.text.trim().isEmpty ? null : _prefix.text.trim(),
                currentNumber: _parseInt(_current.text),
                maxNumber: _parseNullableInt(_max.text),
                active: _active,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
