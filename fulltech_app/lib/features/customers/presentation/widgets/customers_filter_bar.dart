import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/features/customers/providers/customers_provider.dart';

class CustomersFilterBar extends ConsumerStatefulWidget {
  const CustomersFilterBar({super.key});

  @override
  ConsumerState<CustomersFilterBar> createState() =>
      _CustomersFilterBarState();
}

class _CustomersFilterBarState extends ConsumerState<CustomersFilterBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersControllerProvider);
    final controller = ref.read(customersControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Search Box
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          controller.setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                controller.setSearchQuery(value);
              },
            ),
          ),

          const SizedBox(width: 12),

          // Status Filter
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: state.selectedStatus,
              decoration: InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: 'active', child: Text('Activo')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactivo')),
                DropdownMenuItem(value: 'vip', child: Text('VIP')),
              ],
              onChanged: (value) {
                controller.setSelectedStatus(value);
              },
            ),
          ),

          const SizedBox(width: 12),

          // Clear Filters Button
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            tooltip: 'Limpiar filtros',
            onPressed: () {
              _searchController.clear();
              controller.clearFilters();
            },
          ),

          const SizedBox(width: 12),

          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () {
              controller.loadCustomers();
            },
          ),
        ],
      ),
    );
  }
}
