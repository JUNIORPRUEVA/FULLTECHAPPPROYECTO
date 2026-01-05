import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/maintenance_provider.dart';
import '../../data/models/maintenance_models.dart';

class AuditsListView extends ConsumerStatefulWidget {
  const AuditsListView({super.key});

  @override
  ConsumerState<AuditsListView> createState() => _AuditsListViewState();
}

class _AuditsListViewState extends ConsumerState<AuditsListView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(auditsControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditsControllerProvider);
    final controller = ref.read(auditsControllerProvider.notifier);

    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              DropdownButton<AuditStatus?>(
                value: controller.statusFilter,
                hint: const Text('Estado'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...AuditStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_getStatusLabel(status)),
                    );
                  }),
                ],
                onChanged: controller.setStatusFilter,
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.filter_alt_off),
                tooltip: 'Limpiar filtros',
                onPressed: controller.clearFilters,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Create new audit dialog
                },
                icon: const Icon(Icons.add),
                label: const Text('Nueva Auditoría'),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: state.error != null
              ? _buildError(state.error!)
              : state.items.isEmpty && !state.isLoading
              ? _buildEmpty()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildAuditCard(state.items[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAuditCard(InventoryAudit audit) {
    final hasDifferences = (audit.totalDiferencias ?? 0) > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Show detail dialog with items
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasDifferences ? Icons.warning_amber : Icons.check_circle,
                    color: hasDifferences ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audit.weekLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildStatusBadge(audit.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(audit.auditFromDate)} - ${DateFormat('dd/MM/yyyy').format(audit.auditToDate)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStat(
                    'Items',
                    '${audit.totalItems ?? 0}',
                    Icons.inventory_2_outlined,
                    Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    'Diferencias',
                    '${audit.totalDiferencias ?? 0}',
                    Icons.compare_arrows,
                    hasDifferences ? Colors.orange : Colors.green,
                  ),
                ],
              ),
              if (audit.notes != null && audit.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  audit.notes!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(AuditStatus status) {
    final data = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: data.color),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          color: data.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error al cargar auditorías',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(auditsControllerProvider.notifier)
                  .loadAudits(reset: true);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay auditorías',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea una nueva auditoría de inventario',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(AuditStatus status) {
    switch (status) {
      case AuditStatus.borrador:
        return 'Borrador';
      case AuditStatus.finalizado:
        return 'Finalizado';
    }
  }

  ({Color color, String label}) _getStatusInfo(AuditStatus status) {
    switch (status) {
      case AuditStatus.borrador:
        return (color: Colors.orange, label: 'Borrador');
      case AuditStatus.finalizado:
        return (color: Colors.green, label: 'Finalizado');
    }
  }
}
