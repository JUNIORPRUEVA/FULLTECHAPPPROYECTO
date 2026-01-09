import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/module_page.dart';
import '../../data/models/user_model.dart';
import '../../state/users_providers.dart';
import '../../state/users_state.dart';

class UsuariosListPage extends ConsumerStatefulWidget {
  const UsuariosListPage({super.key});

  @override
  ConsumerState<UsuariosListPage> createState() => _UsuariosListPageState();
}

class _UsuariosListPageState extends ConsumerState<UsuariosListPage> {
  late TextEditingController _searchCtrl;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final isAdmin = ref.read(isAdminProvider);
    if (!isAdmin) {
      if (mounted) context.go(AppRoutes.crm);
      return;
    }
    await ref.read(usersControllerProvider.notifier).load(reset: true);
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(usersControllerProvider.notifier).setQuery(query);
      ref.read(usersControllerProvider.notifier).search();
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterModal(
        onApply: (filters) {
          final notifier = ref.read(usersControllerProvider.notifier);
          notifier.setRol(filters['rol']);
          notifier.setEstado(filters['estado']);
          notifier.search();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _blockUser(UserSummary user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bloquear Usuario'),
        content: Text('¿Bloquear a ${user.nombre}? Perderá acceso inmediato.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bloquear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(usersRepositoryProvider).blockUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.nombre} bloqueado')),
        );
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unblockUser(UserSummary user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desbloquear Usuario'),
        content: Text('¿Desbloquear a ${user.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desbloquear', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(usersRepositoryProvider).unblockUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.nombre} desbloqueado')),
        );
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(UserSummary user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Eliminar a ${user.nombre}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '⚠️ El usuario será eliminado y perderá acceso inmediato.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(usersRepositoryProvider).deleteUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.nombre} eliminado')),
        );
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersControllerProvider);

    return ModulePage(
      title: 'Usuarios',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: _loadUsers,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          final header = Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: isMobile
                ? Column(
                    children: [
                      _SearchBar(controller: _searchCtrl, onChanged: _onSearchChanged),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _showFilterModal,
                            icon: const Icon(Icons.filter_list),
                            label: const Text('Filtros'),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () => context.go('${AppRoutes.usuarios}/new'),
                            icon: const Icon(Icons.add),
                            label: const Text('Nuevo'),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _SearchBar(controller: _searchCtrl, onChanged: _onSearchChanged),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        onPressed: _showFilterModal,
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Filtros'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => context.go('${AppRoutes.usuarios}/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo Usuario'),
                      ),
                    ],
                  ),
          );

          final list = _UsersList(
            state: state,
            onBlockUser: _blockUser,
            onUnblockUser: _unblockUser,
            onDeleteUser: _deleteUser,
          );

          final metrics = _MetricsPanel(state: state);

          if (isMobile) {
            return Column(
              children: [
                header,
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: const Text('Resumen'),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: [
                      SizedBox(height: 240, child: metrics),
                    ],
                  ),
                ),
                Expanded(child: list),
              ],
            );
          }

          return Column(
            children: [
              header,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: list),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 320,
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: metrics,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: (val) {
        widget.onChanged(val);
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, email, teléfono...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _UsersList extends ConsumerWidget {
  final UsersState state;
  final Function(UserSummary) onBlockUser;
  final Function(UserSummary) onUnblockUser;
  final Function(UserSummary) onDeleteUser;

  const _UsersList({
    required this.state,
    required this.onBlockUser,
    required this.onUnblockUser,
    required this.onDeleteUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      final raw = state.error ?? '';
      final isOffline = raw.contains('SocketException') ||
          raw.contains('Failed host lookup') ||
          raw.contains('Network is unreachable') ||
          raw.contains('Connection refused');

      final title = isOffline ? 'Sin conexión' : 'No se pudieron cargar los usuarios';
      final subtitle = isOffline
          ? 'Verifica tu internet e intenta de nuevo.'
          : 'Intenta nuevamente en unos segundos.';

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isOffline ? Icons.wifi_off : Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.read(usersControllerProvider.notifier).load(reset: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48),
            SizedBox(height: 16),
            Text('No hay usuarios'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(0),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (ctx, idx) {
        if (idx == state.items.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => ref.read(usersControllerProvider.notifier).loadMore(),
                child: const Text('Cargar más'),
              ),
            ),
          );
        }

        final user = state.items[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => context.go('${AppRoutes.usuarios}/${user.id}'),
            leading: CircleAvatar(
              backgroundImage: user.fotoPerfilUrl != null
                  ? NetworkImage(user.fotoPerfilUrl!)
                  : null,
              child: user.fotoPerfilUrl == null
                  ? Text(user.nombre.isNotEmpty ? user.nombre[0] : '?')
                  : null,
            ),
            title: Text(user.nombre),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.email, style: const TextStyle(fontSize: 12)),
                if (user.telefono != null)
                  Text(user.telefono!, style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, size: 16),
                      SizedBox(width: 8),
                      Text('Ver'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                if (user.estado == 'activo')
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Bloquear', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                if (user.estado == 'bloqueado')
                  const PopupMenuItem(
                    value: 'unblock',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Desbloquear', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'view') {
                  context.go('${AppRoutes.usuarios}/${user.id}');
                } else if (value == 'edit') {
                  context.go('${AppRoutes.usuarios}/${user.id}');
                } else if (value == 'block') {
                  onBlockUser(user);
                } else if (value == 'unblock') {
                  onUnblockUser(user);
                } else if (value == 'delete') {
                  onDeleteUser(user);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  final UsersState state;

  const _MetricsPanel({required this.state});

  int _countByEstado(String estado) {
    return state.items.where((u) => u.estado == estado).length;
  }

  int _countByRol(String rol) {
    return state.items.where((u) => u.rol == rol).length;
  }

  @override
  Widget build(BuildContext context) {
    final total = state.total;
    final activos = _countByEstado('activo');
    final bloqueados = _countByEstado('bloqueado');

    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Resumen',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        _MetricTile(
          label: 'Total',
          value: total.toString(),
          icon: Icons.people,
          color: Colors.blue,
        ),
        const SizedBox(height: 4),
        _MetricTile(
          label: 'Activos',
          value: activos.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        const SizedBox(height: 4),
        _MetricTile(
          label: 'Bloqueados',
          value: bloqueados.toString(),
          icon: Icons.block,
          color: Colors.red,
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Por Rol',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _RoleChip(
                label: 'Vendedor',
                count: _countByRol('vendedor'),
                color: Colors.blue,
              ),
              _RoleChip(
                label: 'Técnico',
                count: _countByRol('tecnico_fijo'),
                color: Colors.green,
              ),
              _RoleChip(
                label: 'Contratista',
                count: _countByRol('contratista'),
                color: Colors.purple,
              ),
              _RoleChip(
                label: 'Admin',
                count: _countByRol('administrador'),
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _RoleChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        '$label ($count)',
        style: const TextStyle(fontSize: 10),
      ),
      onSelected: (_) {},
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontSize: 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color, width: 0.5),
      ),
    );
  }
}

class _FilterModal extends StatefulWidget {
  final Function(Map<String, String?>) onApply;

  const _FilterModal({required this.onApply});

  @override
  State<_FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<_FilterModal> {
  String? selectedRol;
  String? selectedEstado;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (ctx, controller) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          controller: controller,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Rol'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  'vendedor',
                  'tecnico_fijo',
                  'contratista',
                  'administrador',
                  'asistente_administrativo',
                  'marketings',
                ].map((rol) {
                  final labels = {
                    'vendedor': 'Vendedor',
                    'tecnico_fijo': 'Técnico Fijo',
                    'contratista': 'Contratista',
                    'administrador': 'Administrador',
                    'asistente_administrativo': 'Asistente Admin',
                    'marketings': 'Marketing',
                  };
                  return FilterChip(
                    label: Text(labels[rol] ?? rol),
                    selected: selectedRol == rol,
                    onSelected: (_) {
                      setState(() {
                        selectedRol = selectedRol == rol ? null : rol;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Estado'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['activo', 'bloqueado', 'eliminado']
                    .map((estado) {
                      final labels = {
                        'activo': 'Activo',
                        'bloqueado': 'Bloqueado',
                        'eliminado': 'Eliminado',
                      };
                      return FilterChip(
                        label: Text(labels[estado] ?? estado),
                        selected: selectedEstado == estado,
                        onSelected: (_) {
                          setState(() {
                            selectedEstado = selectedEstado == estado ? null : estado;
                          });
                        },
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedRol = null;
                        selectedEstado = null;
                      });
                    },
                    child: const Text('Limpiar'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      widget.onApply({
                        'rol': selectedRol,
                        'estado': selectedEstado,
                      });
                    },
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
