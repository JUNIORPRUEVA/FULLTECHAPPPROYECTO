import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/module_page.dart';

class OperacionesJobDetailScreen extends ConsumerWidget {
  final String jobId;

  const OperacionesJobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModulePage(
      title: 'Operación',
      actions: [
        IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      child: Center(
        child: Text('Detalle de operación pendiente. ID: $jobId'),
      ),
    );
  }
}
