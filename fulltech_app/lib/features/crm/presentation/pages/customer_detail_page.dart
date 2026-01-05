import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/module_page.dart';
import '../../../auth/state/auth_providers.dart';
import '../../../auth/state/auth_state.dart';
import '../../../operaciones/state/operations_providers.dart';
import '../../state/crm_providers.dart';

class CustomerDetailPage extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage> {
  bool _creatingJob = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customerDetailControllerProvider(widget.customerId).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerDetailControllerProvider(widget.customerId));

    return ModulePage(
      title: 'Cliente',
      actions: [
        IconButton(
          tooltip: 'Volver',
          onPressed: () => context.go(AppRoutes.crm),
          icon: const Icon(Icons.arrow_back),
        ),
        PopupMenuButton<String>(
          tooltip: 'Operaciones',
          enabled: !_creatingJob,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'to_survey',
              child: Text('Enviar a Levantamiento'),
            ),
            PopupMenuItem(
              value: 'to_scheduling',
              child: Text('Enviar a Agenda (sin levantamiento)'),
            ),
          ],
          onSelected: (value) async {
            final detail = state.detail;
            final auth = ref.read(authControllerProvider);
            if (detail == null) return;
            if (auth is! AuthAuthenticated) return;

            setState(() => _creatingJob = true);
            try {
              final repo = ref.read(operationsRepositoryProvider);
              final initialStatus = value == 'to_scheduling' ? 'pending_scheduling' : 'pending_survey';

              final job = await repo.createJobLocalFirst(
                empresaId: auth.user.empresaId,
                crmCustomerId: detail.id,
                serviceType: 'Instalación',
                priority: 'normal',
                initialStatus: initialStatus,
                createdByUserId: auth.user.id,
                notes: 'Creado desde CRM',
                customerName: detail.displayName,
                customerPhone: detail.phone,
              );

              if (!mounted) return;
              context.go(AppRoutes.operacionesDetail(job.id));
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No se pudo crear el trabajo: $e')),
              );
            } finally {
              if (mounted) setState(() => _creatingJob = false);
            }
          },
          child: _creatingJob
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.playlist_add_check),
        ),
      ],
      child: Builder(
        builder: (context) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text(state.error!));
          }
          final detail = state.detail;
          if (detail == null) {
            return const Center(child: Text('No encontrado'));
          }

          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ListView(
                      children: [
                        Text(
                          detail.displayName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text('Teléfono: ${detail.phone}'),
                        Text('WhatsApp ID: ${detail.waId}'),
                        Text('Estado: ${detail.status}'),
                        const SizedBox(height: 10),
                        Text('Total compras: ${detail.summary.totalPurchases}'),
                        Text('Total gastado: \$${detail.summary.totalSpent.toStringAsFixed(2)}'),
                        if (detail.summary.lastPurchaseAt != null)
                          Text('Última compra: ${detail.summary.lastPurchaseAt}'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Compras recientes',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Refrescar',
                              onPressed: () => ref
                                  .read(customerDetailControllerProvider(widget.customerId).notifier)
                                  .load(),
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: detail.recentPurchases.isEmpty
                            ? const Center(child: Text('Sin compras'))
                            : ListView.separated(
                                itemCount: detail.recentPurchases.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final p = detail.recentPurchases[i];
                                  return ListTile(
                                    title: Text('\$${p.total.toStringAsFixed(2)}'),
                                    subtitle: Text(p.date),
                                    trailing: Text(p.status),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

}
