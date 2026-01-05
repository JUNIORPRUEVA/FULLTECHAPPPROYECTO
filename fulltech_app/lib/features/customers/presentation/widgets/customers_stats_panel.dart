import 'package:flutter/material.dart';
import 'package:fulltech_app/features/customers/data/models/customer_response.dart';

class CustomersStatsPanel extends StatelessWidget {
  final CustomerStats? stats;

  const CustomersStatsPanel({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          _buildStatCard(
            'Total Clientes',
            stats!.totalCustomers.toString(),
            Icons.people,
            Colors.blue,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'Clientes Activos',
            stats!.activeCustomers.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(width: 16),
          if (stats!.byStatus.isNotEmpty) ...[
            ...stats!.byStatus.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: _buildSmallStat(entry.key, entry.value),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String status, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
