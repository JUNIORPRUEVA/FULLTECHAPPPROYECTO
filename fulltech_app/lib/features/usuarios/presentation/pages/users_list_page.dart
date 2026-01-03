import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/module_page.dart';
import '../../../auth/state/auth_providers.dart';
import '../../../auth/state/auth_state.dart';
import '../../data/models/user_model.dart';
import '../../state/users_providers.dart';
import '../widgets/user_card.dart';
import 'user_form_page.dart';

class UsersListPage extends ConsumerStatefulWidget {
  const UsersListPage({super.key});

  @override
  ConsumerState<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends ConsumerState<UsersListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(isAdminProvider)) {
        ref.read(usersControllerProvider.notifier).load(reset: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  Future<void> _openFile(String filePath) async {
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', filePath]);
      return;
    }
    if (Platform.isMacOS) {
      await Process.run('open', [filePath]);
      return;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', [filePath]);
      return;
    }
  }

  Future<void> _downloadAndOpenPdf({
    required String id,
    required String kind,
  }) async {
    try {
      final path = await ref
          .read(usersRepositoryProvider)
          .downloadUserPdfToTempFile(id: id, kind: kind);
      await _openFile(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmAndDelete(UserSummary u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          'Esto marcará a "${u.nombre}" como eliminado. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await ref.read(usersRepositoryProvider).deleteUser(u.id);
    await ref.read(usersControllerProvider.notifier).load(reset: true);
  }

  Future<void> _toggleBlock(UserSummary u) async {
    if (u.estado == 'bloqueado') {
      await ref.read(usersRepositoryProvider).unblockUser(u.id);
    } else {
      await ref.read(usersRepositoryProvider).blockUser(u.id);
    }
    await ref.read(usersControllerProvider.notifier).load(reset: true);
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const UserFormPage()));
    if (created == true && mounted) {
      await ref.read(usersControllerProvider.notifier).load(reset: true);
    }
  }

  Future<void> _openEdit(String id) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => UserFormPage(userId: id)));
    if (updated == true && mounted) {
      await ref.read(usersControllerProvider.notifier).load(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final state = ref.watch(usersControllerProvider);

    if (!isAdmin) {
      final auth = ref.watch(authControllerProvider);
      final id = (auth is AuthAuthenticated) ? auth.user.id : null;
      return ModulePage(
        title: 'Usuarios',
        child: Center(
          child: FilledButton.icon(
            onPressed: id == null
                ? null
                : () => context.go('${AppRoutes.usuarios}/$id'),
            icon: const Icon(Icons.person_outline),
            label: const Text('Ver mi perfil'),
          ),
        ),
      );
    }

    return ModulePage(
      title: 'Usuarios',
      actions: [
        FilledButton.icon(
          onPressed: state.isLoading ? null : _openCreate,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Nuevo Usuario'),
        ),
      ],
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 340,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar (nombre, email, teléfono, cédula)',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => ref
                          .read(usersControllerProvider.notifier)
                          .setQuery(v),
                      onSubmitted: (_) =>
                          ref.read(usersControllerProvider.notifier).search(),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      value: state.rol,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Todos', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'administrador',
                          child: Text(
                            'administrador',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'asistente_administrativo',
                          child: Text(
                            'asistente_administrativo',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'vendedor',
                          child: Text(
                            'vendedor',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'tecnico_fijo',
                          child: Text(
                            'tecnico_fijo',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'contratista',
                          child: Text(
                            'contratista',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          ref.read(usersControllerProvider.notifier).setRol(v),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: state.estado,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Todos', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'activo',
                          child: Text(
                            'activo',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'bloqueado',
                          child: Text(
                            'bloqueado',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'eliminado',
                          child: Text(
                            'eliminado',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (v) => ref
                          .read(usersControllerProvider.notifier)
                          .setEstado(v),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                              .read(usersControllerProvider.notifier)
                              .search(),
                    icon: const Icon(Icons.search),
                    label: const Text('Aplicar'),
                  ),
                ],
              ),
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: Card(
              child: LayoutBuilder(
                builder: (context, c) {
                  if (state.items.isEmpty && state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.items.isEmpty) {
                    return const Center(child: Text('Sin resultados.'));
                  }

                  if (c.maxWidth >= 900) {
                    return SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Usuario')),
                          DataColumn(label: Text('Rol')),
                          DataColumn(label: Text('Teléfono')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Ingreso')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: state.items.map((u) {
                          return DataRow(
                            cells: [
                              DataCell(
                                InkWell(
                                  onTap: () => context.go(
                                    '${AppRoutes.usuarios}/${u.id}',
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        u.nombre,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        u.email,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(Text(u.rol)),
                              DataCell(Text(u.telefono ?? '-')),
                              DataCell(Text(u.estado)),
                              DataCell(Text(_formatDate(u.fechaIngreso))),
                              DataCell(
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    IconButton(
                                      tooltip: 'Ver',
                                      onPressed: () => context.go(
                                        '${AppRoutes.usuarios}/${u.id}',
                                      ),
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Editar',
                                      onPressed: () => _openEdit(u.id),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: u.estado == 'bloqueado'
                                          ? 'Desbloquear'
                                          : 'Bloquear',
                                      onPressed: () => _toggleBlock(u),
                                      icon: Icon(
                                        u.estado == 'bloqueado'
                                            ? Icons.lock_open_outlined
                                            : Icons.lock_outline,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Ficha PDF',
                                      onPressed: () => _downloadAndOpenPdf(
                                        id: u.id,
                                        kind: 'profile',
                                      ),
                                      icon: const Icon(
                                        Icons.picture_as_pdf_outlined,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Contrato PDF',
                                      onPressed: () => _downloadAndOpenPdf(
                                        id: u.id,
                                        kind: 'contract',
                                      ),
                                      icon: const Icon(
                                        Icons.description_outlined,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      onPressed: () => _confirmAndDelete(u),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      if (i >= state.items.length) {
                        return Align(
                          alignment: Alignment.center,
                          child: FilledButton.icon(
                            onPressed: state.isLoading
                                ? null
                                : () => ref
                                      .read(usersControllerProvider.notifier)
                                      .loadMore(),
                            icon: state.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.expand_more),
                            label: const Text('Cargar más'),
                          ),
                        );
                      }

                      final u = state.items[i];
                      return UserCard(
                        user: u,
                        onView: () =>
                            context.go('${AppRoutes.usuarios}/${u.id}'),
                        onEdit: () => _openEdit(u.id),
                        onToggleBlock: () => _toggleBlock(u),
                        onDelete: () => _confirmAndDelete(u),
                        onDownloadProfilePdf: () =>
                            _downloadAndOpenPdf(id: u.id, kind: 'profile'),
                        onDownloadContractPdf: () =>
                            _downloadAndOpenPdf(id: u.id, kind: 'contract'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
