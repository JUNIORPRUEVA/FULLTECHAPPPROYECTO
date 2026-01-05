import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/maintenance_provider.dart';
import '../../data/models/maintenance_models.dart';

class SummaryPanel extends ConsumerWidget {
  final bool compact;

  const SummaryPanel({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(maintenanceSummaryProvider);

    return summaryAsync.when(
      data: (summary) => compact
          ? _buildCompactView(context, summary)
          : _buildFullView(context, summary),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300),
              const SizedBox(height: 8),
              Text(
                'Error al cargar resumen',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.invalidate(maintenanceSummaryProvider);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactView(BuildContext context, MaintenanceSummary summary) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildStatChip(
            'OK',
            '${summary.totalVerificados}',
            Colors.green,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            'Problemas',
            '${summary.totalProductosConProblema}',
            Colors.orange,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            'Garantía',
            '${summary.totalEnGarantia}',
            Colors.blue,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            'Perdidos',
            '${summary.totalPerdidos}',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildFullView(BuildContext context, MaintenanceSummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.dashboard, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Resumen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {
                  // Refresh is handled by the provider
                },
              ),
            ],
          ),
          const Divider(height: 24),

          // Status counts
          const Text(
            'Estado de Productos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusCard('OK', summary.totalVerificados, Colors.green, Icons.check_circle),
          _buildStatusCard('Con Problema', summary.totalProductosConProblema, Colors.orange, Icons.warning),
          _buildStatusCard('En Garantía', summary.totalEnGarantia, Colors.blue, Icons.verified_user),
          _buildStatusCard('Perdidos', summary.totalPerdidos, Colors.red, Icons.cancel),
          _buildStatusCard('Dañados', summary.totalDanadoSinGarantia, Colors.red.shade700, Icons.broken_image),
          _buildStatusCard('Reparados', summary.totalReparados, Colors.teal, Icons.build_circle),
          _buildStatusCard('En Revisión', summary.totalEnRevision, Colors.amber, Icons.search),

          const Divider(height: 24),

          // Warranty status
          const Text(
            'Garantías',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildWarrantyStat('Abiertas', summary.garantiasAbiertas, Colors.blue),

          const Divider(height: 24),

          // Last audit
          const Text(
            'Última Auditoría',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (summary.ultimoAudit != null)
            _buildLastAudit(summary.ultimoAudit!)
          else
            _buildNoAudit(),

          const Divider(height: 24),

          // Top products with issues
          const Text(
            'Productos con Más Incidencias',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (summary.topProductosConIncidencias.isEmpty)
            _buildNoIncidents()
          else
            ...summary.topProductosConIncidencias.map(_buildProductIncident),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String label, int count, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyStat(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastAudit(InventoryAudit audit) {
    final hasDifferences = (audit.totalDiferencias ?? 0) > 0;
    final color = hasDifferences ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasDifferences ? Icons.warning_amber : Icons.check_circle,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  audit.weekLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd/MM/yyyy').format(audit.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Items: ${audit.totalItems ?? 0}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 12),
              Text(
                'Diferencias: ${audit.totalDiferencias ?? 0}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasDifferences ? FontWeight.bold : null,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoAudit() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay auditorías registradas',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductIncident(ProductWithIncidents product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          if (product.imagenUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                product.imagenUrl!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.inventory_2,
                  color: Colors.grey.shade400,
                  size: 32,
                ),
              ),
            )
          else
            Icon(
              Icons.inventory_2,
              color: Colors.grey.shade400,
              size: 32,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nombre,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${product.incidencias} incidencias',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoIncidents() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay incidencias recientes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
