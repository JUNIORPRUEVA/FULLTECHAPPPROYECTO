import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/state/auth_providers.dart';
import '../../../core/widgets/module_page.dart';
import 'permissions_settings_repository.dart';

final _repoProvider = Provider<PermissionsSettingsRepository>((ref) {
  return PermissionsSettingsRepository(ref.read(apiClientProvider).dio);
});

class PermissionsSettingsScreen extends ConsumerStatefulWidget {
  const PermissionsSettingsScreen({super.key});

  @override
  ConsumerState<PermissionsSettingsScreen> createState() => _PermissionsSettingsScreenState();
}

class _PermissionsSettingsScreenState extends ConsumerState<PermissionsSettingsScreen> {
  bool _loading = true;
  String? _error;

  List<PermissionCatalogItem> _catalog = const [];
  List<RbacRoleItem> _roles = const [];
  List<UserPermissionsItem> _users = const [];

  String? _selectedUserId;
  Set<String> _selectedRoleIds = <String>{};
  final Map<String, String> _overrideByCode = {}; // code -> allow|deny|none

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  UserPermissionsItem? get _selectedUser {
    final id = _selectedUserId;
    if (id == null) return null;
    return _users.cast<UserPermissionsItem?>().firstWhere(
          (u) => u?.id == id,
          orElse: () => null,
        );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(_repoProvider);
      final catalog = await repo.getCatalog();
      final roles = await repo.getRoles();
      final users = await repo.getUsers();

      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _roles = roles;
        _users = users;
        _selectedUserId = users.isNotEmpty ? users.first.id : null;
        _loading = false;
      });

      _syncSelectionFromUser();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _syncSelectionFromUser() {
    final u = _selectedUser;
    if (u == null) return;

    _selectedRoleIds = u.roles.map((r) => r.id).toSet();
    _overrideByCode.clear();

    for (final p in _catalog) {
      _overrideByCode[p.code] = 'none';
    }
    for (final o in u.overrides) {
      _overrideByCode[o.code] = o.effect;
    }

    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final u = _selectedUser;
    if (u == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(_repoProvider);
      final overrides = _overrideByCode.entries
          .where((e) => e.value == 'allow' || e.value == 'deny')
          .map((e) => UserPermissionOverride(code: e.key, effect: e.value))
          .toList();

      await repo.updateUser(
        userId: u.id,
        roleIds: _selectedRoleIds.toList(),
        overrides: overrides,
      );

      if (!mounted) return;
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permisos guardados.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedUser;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text(_error!));
    } else if (_users.isEmpty) {
      body = const Center(child: Text('Sin usuarios.'));
    } else {
      body = LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 980;

          final userList = Card(
            child: ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final u = _users[i];
                final selectedRow = u.id == _selectedUserId;
                return ListTile(
                  selected: selectedRow,
                  title: Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${u.email} • ${u.legacyRole}'),
                  onTap: () {
                    setState(() => _selectedUserId = u.id);
                    _syncSelectionFromUser();
                  },
                );
              },
            ),
          );

          final editor = Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: selected == null
                  ? const Text('Seleccione un usuario.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Usuario',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text('${selected.name} • ${selected.email}'),
                        const SizedBox(height: 12),
                        Text(
                          'Roles (RBAC)',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: ListView(
                            children: [
                              for (final r in _roles)
                                CheckboxListTile(
                                  value: _selectedRoleIds.contains(r.id),
                                  title: Text(r.name),
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedRoleIds.add(r.id);
                                      } else {
                                        _selectedRoleIds.remove(r.id);
                                      }
                                    });
                                  },
                                ),
                              const Divider(height: 24),
                              Text(
                                'Overrides por permiso',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              for (final p in _catalog)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.code, style: const TextStyle(fontWeight: FontWeight.w700)),
                                            Text(
                                              p.description,
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 160,
                                        child: DropdownButtonFormField<String>(
                                          value: _overrideByCode[p.code] ?? 'none',
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'none', child: Text('Sin override')),
                                            DropdownMenuItem(value: 'allow', child: Text('Permitir')),
                                            DropdownMenuItem(value: 'deny', child: Text('Denegar')),
                                          ],
                                          onChanged: (v) {
                                            if (v == null) return;
                                            setState(() => _overrideByCode[p.code] = v);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _loading ? null : _save,
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
            ),
          );

          if (!wide) {
            return Column(
              children: [
                SizedBox(height: 260, child: userList),
                const SizedBox(height: 12),
                SizedBox(height: 640, child: editor),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 360, child: userList),
              const SizedBox(width: 12),
              Expanded(child: SizedBox(height: double.infinity, child: editor)),
            ],
          );
        },
      );
    }

    return ModulePage(
      title: 'Permisos de usuarios',
      actions: [
        IconButton(
          tooltip: 'Recargar',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: body,
      ),
    );
  }
}
