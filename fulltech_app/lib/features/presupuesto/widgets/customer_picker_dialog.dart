import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customers/data/models/customer_response.dart';
import '../../customers/providers/customers_provider.dart';
import '../models/quotation_models.dart';

class CustomerPickerDialog extends ConsumerStatefulWidget {
  const CustomerPickerDialog({super.key});

  @override
  ConsumerState<CustomerPickerDialog> createState() =>
      _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends ConsumerState<CustomerPickerDialog> {
  final _qCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  String? _error;
  List<CustomerItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load('');
    _qCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _load(_qCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(customersRepositoryProvider);
      final res = await repo.getCustomers(q: q, limit: 20, offset: 0);
      setState(() {
        _items = res.items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  QuotationCustomerDraft _map(CustomerItem c) {
    return QuotationCustomerDraft(
      id: c.id,
      nombre: c.fullName,
      telefono: c.phone,
      email: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar cliente'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _qCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = _items[i];
                  return ListTile(
                    title: Text(c.fullName),
                    subtitle: Text(
                      [c.phone]
                          .whereType<String>()
                          .where((s) => s.trim().isNotEmpty)
                          .join(' • '),
                    ),
                    onTap: () => Navigator.of(context).pop(_map(c)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
