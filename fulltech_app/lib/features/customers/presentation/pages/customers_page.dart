import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/core/widgets/module_page.dart';
import 'package:fulltech_app/core/widgets/compact_error_widget.dart';
import 'package:go_router/go_router.dart';

import 'package:fulltech_app/core/routing/app_routes.dart';
import 'package:fulltech_app/features/crm/providers/purchased_clients_provider.dart';
import 'package:fulltech_app/features/crm/data/models/purchased_client.dart';

class CustomersPage extends ConsumerStatefulWidget {
  final bool onlyActiveCustomers; // Kept for backward compatibility, but now shows purchased clients

  const CustomersPage({super.key, this.onlyActiveCustomers = false});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  String? _selectedClientId;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load purchased clients on init
    Future.microtask(() {
      ref.read(purchasedClientsControllerProvider.notifier).loadClients(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchasedClientsControllerProvider);
    final controller = ref.read(purchasedClientsControllerProvider.notifier);

    return ModulePage(
      title: 'Clientes Comprados', // Changed title to be more specific
      child: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar cliente comprado',
                      hintText: 'Nombre, teléfono o WhatsApp ID...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Debounce search
                      Future.delayed(const Duration(milliseconds: 400), () {
                        if (_searchController.text == value) {
                          controller.search(value);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => controller.refresh(),
                  tooltip: 'Actualizar lista',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    context.go(AppRoutes.crm);
                  },
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Ir a CRM'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Stats Panel
          if (state.totalClients > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Total Clientes Comprados: ${state.totalClients}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  if (state.searchQuery.isNotEmpty) ...[
                    const Icon(Icons.filter_list, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Filtrado: "${state.searchQuery}"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Main Content
          Expanded(
            child: _buildMainContent(state, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(PurchasedClientsState state, PurchasedClientsController controller) {
    if (state.isLoading && state.clients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando clientes comprados...'),
          ],
        ),
      );
    }

    if (state.error != null && state.clients.isEmpty) {
      return Center(
        child: CompactErrorWidget(
          error: state.error!,
          onRetry: () => controller.refresh(),
        ),
      );
    }

    if (state.clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isEmpty
                  ? 'No hay clientes comprados'
                  : 'No se encontraron clientes',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.searchQuery.isEmpty
                  ? 'Los clientes aparecerán aquí cuando marquen un chat como "Compró" en el CRM'
                  : 'Intenta con una búsqueda diferente',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.crm),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Ir al CRM'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Clients List (left side)
        Expanded(
          flex: 2,
          child: _buildClientsList(state, controller),
        ),

        // Client Detail Panel (right side)
        if (_selectedClientId != null)
          Expanded(
            flex: 1,
            child: _buildDetailPanel(_selectedClientId!),
          ),
      ],
    );
  }

  Widget _buildClientsList(PurchasedClientsState state, PurchasedClientsController controller) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // List Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Lista de Clientes (${state.clients.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (state.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Clients List
          Expanded(
            child: ListView.builder(
              itemCount: state.clients.length + (state.hasMorePages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.clients.length) {
                  // Load more indicator
                  if (!state.isLoading) {
                    // Auto-trigger load more when user scrolls to end
                    Future.microtask(() => controller.loadMore());
                  }
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final client = state.clients[index];
                final isSelected = client.id == _selectedClientId;

                return _buildClientTile(client, isSelected, controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientTile(PurchasedClient client, bool isSelected, PurchasedClientsController controller) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : null,
        border: Border(
          left: BorderSide(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: client.isImportant ? Colors.red[100] : Colors.blue[100],
          child: client.isImportant
              ? const Icon(Icons.star, color: Colors.red, size: 20)
              : Text(
                  client.initials,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          client.displayNameOrPhone,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client.phoneE164 != null && client.displayName != null)
              Text(
                client.phoneE164!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            if (client.lastMessageText != null)
              Text(
                client.lastMessageText!,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (client.lastMessageAt != null)
              Text(
                _formatDateTime(client.lastMessageAt!),
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleClientAction(value, client, controller),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Ver Detalles'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Editar'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'chat',
              child: ListTile(
                leading: Icon(Icons.chat),
                title: Text('Ir a Chat'),
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                dense: true,
              ),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _selectedClientId = client.id;
          });
        },
      ),
    );
  }

  void _handleClientAction(String action, PurchasedClient client, PurchasedClientsController controller) {
    switch (action) {
      case 'view':
        setState(() {
          _selectedClientId = client.id;
        });
        break;
      case 'edit':
        _showEditClientDialog(client, controller);
        break;
      case 'chat':
        // Navigate to CRM and open this specific chat
        context.go('${AppRoutes.crm}/chats/${client.id}');
        break;
      case 'delete':
        _showDeleteConfirmation(client, controller);
        break;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Hoy ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildDetailPanel(String clientId) {
    final clientDetailAsync = ref.watch(purchasedClientDetailProvider(clientId));

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: clientDetailAsync.when(
        data: (client) => _buildClientDetails(client),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: CompactErrorWidget(
            error: error.toString(),
            onRetry: () => ref.invalidate(purchasedClientDetailProvider(clientId)),
          ),
        ),
      ),
    );
  }

  Widget _buildClientDetails(PurchasedClient client) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            children: [
              Expanded(
                child: Text(
                  client.displayNameOrPhone,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedClientId = null;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                const SizedBox(width: 4),
                Text(
                  'Cliente Comprado',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contact Information
          _buildInfoCard('Información de Contacto', [
            if (client.phoneE164 != null) _buildInfoRow('Teléfono', client.phoneE164!),
            _buildInfoRow('WhatsApp ID', client.waId),
            if (client.displayName != null) _buildInfoRow('Nombre', client.displayName!),
          ]),

          const SizedBox(height: 16),

          // CRM Information
          _buildInfoCard('Información CRM', [
            _buildInfoRow('Estado', client.status),
            if (client.isImportant) 
              const Chip(
                label: Text('Importante'),
                backgroundColor: Colors.red,
                labelStyle: TextStyle(color: Colors.white),
              ),
            if (client.followUp)
              const Chip(
                label: Text('Seguimiento'),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white),
              ),
            if (client.productId != null) _buildInfoRow('Producto ID', client.productId!),
            if (client.assignedToUserId != null) _buildInfoRow('Asignado a', client.assignedToUserId!),
          ]),

          const SizedBox(height: 16),

          // Last Message
          if (client.lastMessageText != null)
            _buildInfoCard('Último Mensaje', [
              Text(client.lastMessageText!),
              if (client.lastMessageAt != null)
                Text(
                  'Recibido: ${_formatDateTime(client.lastMessageAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ]),

          const SizedBox(height: 16),

          // Notes
          if (client.note != null && client.note!.isNotEmpty)
            _buildInfoCard('Notas', [
              Text(client.note!),
            ]),

          const SizedBox(height: 16),

          // Audit Info
          _buildInfoCard('Información de Auditoría', [
            if (client.createdAt != null) _buildInfoRow('Creado', _formatDateTime(client.createdAt!)),
            if (client.updatedAt != null) _buildInfoRow('Actualizado', _formatDateTime(client.updatedAt!)),
          ]),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('${AppRoutes.crm}/chats/${client.id}');
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Ir a Chat'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final controller = ref.read(purchasedClientsControllerProvider.notifier);
                    _showEditClientDialog(client, controller);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Delete Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final controller = ref.read(purchasedClientsControllerProvider.notifier);
                _showDeleteConfirmation(client, controller);
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Eliminar Cliente', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showEditClientDialog(PurchasedClient client, PurchasedClientsController controller) {
    final nameController = TextEditingController(text: client.displayName ?? '');
    final phoneController = TextEditingController(text: client.phoneE164 ?? '');
    final noteController = TextEditingController(text: client.note ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Cliente'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await controller.updateClient(
                  client.id,
                  displayName: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                  phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                );
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cliente actualizado correctamente')),
                  );
                  // Refresh details panel
                  ref.invalidate(purchasedClientDetailProvider(client.id));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(PurchasedClient client, PurchasedClientsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres eliminar a ${client.displayNameOrPhone}?'),
            const SizedBox(height: 16),
            const Text(
              'Opciones de eliminación:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Eliminación suave: Cambia el estado a "eliminado"'),
            const Text('• Eliminación permanente: Elimina completamente el registro'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () async {
              try {
                final message = await controller.deleteClient(client.id, hardDelete: false);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedClientId = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Eliminación Suave'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final message = await controller.deleteClient(client.id, hardDelete: true);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedClientId = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar Permanente'),
          ),
        ],
      ),
    );
  }
}
