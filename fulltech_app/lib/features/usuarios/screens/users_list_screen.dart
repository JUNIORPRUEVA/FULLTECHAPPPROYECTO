import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/app_config.dart';
import '../../../core/widgets/module_page.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../state/users_providers.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final isAdmin = ref.read(isAdminProvider);
      if (isAdmin) {
        await ref.read(usersControllerProvider.notifier).load(reset: true);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static String _publicBase() {
    final base = AppConfig.apiBaseUrl;
    return base.replaceFirst(RegExp(r'/api/?$'), '');
  }

  static String? resolvePublicUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('/')) return '${_publicBase()}$trimmed';
    return '${_publicBase()}/$trimmed';
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _UserCreateDialog(),
    );
    if (created == true) {
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
                : () {
                    context.go('${AppRoutes.usuarios}/$id');
                  },
            icon: const Icon(Icons.person_outline),
            label: const Text('Ver mi perfil'),
          ),
        ),
      );
    }

    return ModulePage(
      title: 'Usuarios',
      actions: [
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: state.isLoading ? null : _openCreateDialog,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Nuevo'),
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
                    width: 320,
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Buscar (nombre, email, teléfono, cédula)',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => ref.read(usersControllerProvider.notifier).setQuery(v),
                      onSubmitted: (_) => ref.read(usersControllerProvider.notifier).search(),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: state.rol,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(value: 'administrador', child: Text('administrador')),
                        DropdownMenuItem(value: 'asistente_administrativo', child: Text('asistente_administrativo')),
                        DropdownMenuItem(value: 'vendedor', child: Text('vendedor')),
                        DropdownMenuItem(value: 'tecnico_fijo', child: Text('tecnico_fijo')),
                        DropdownMenuItem(value: 'contratista', child: Text('contratista')),
                        DropdownMenuItem(value: 'admin', child: Text('admin (legacy)')),
                        DropdownMenuItem(value: 'tecnico', child: Text('tecnico (legacy)')),
                      ],
                      onChanged: (v) => ref.read(usersControllerProvider.notifier).setRol(v),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: state.estado,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(value: 'activo', child: Text('activo')),
                        DropdownMenuItem(value: 'bloqueado', child: Text('bloqueado')),
                        DropdownMenuItem(value: 'eliminado', child: Text('eliminado')),
                      ],
                      onChanged: (v) => ref.read(usersControllerProvider.notifier).setEstado(v),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: state.isLoading ? null : () => ref.read(usersControllerProvider.notifier).search(),
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
              child: Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                        ],
                        rows: state.items.map((u) {
                          return DataRow(
                            onSelectChanged: (_) => context.go('${AppRoutes.usuarios}/${u.id}'),
                            cells: [
                              DataCell(Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: resolvePublicUrl(u.fotoPerfilUrl) != null
                                        ? NetworkImage(resolvePublicUrl(u.fotoPerfilUrl)!)
                                        : null,
                                    child: resolvePublicUrl(u.fotoPerfilUrl) == null
                                        ? const Icon(Icons.person_outline, size: 18)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(u.nombre, overflow: TextOverflow.ellipsis),
                                        Text(
                                          u.email,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )),
                              DataCell(Text(u.rol)),
                              DataCell(Text(u.telefono ?? '-')),
                              DataCell(Text(u.estado)),
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
                                : () => ref.read(usersControllerProvider.notifier).loadMore(),
                            icon: state.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.expand_more),
                            label: const Text('Cargar más'),
                          ),
                        );
                      }

                      final u = state.items[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: resolvePublicUrl(u.fotoPerfilUrl) != null
                              ? NetworkImage(resolvePublicUrl(u.fotoPerfilUrl)!)
                              : null,
                          child: resolvePublicUrl(u.fotoPerfilUrl) == null ? const Icon(Icons.person_outline) : null,
                        ),
                        title: Text(u.nombre),
                        subtitle: Text('${u.email}\n${u.rol} • ${u.estado}'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('${AppRoutes.usuarios}/${u.id}'),
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

class _UserCreateDialog extends ConsumerStatefulWidget {
  const _UserCreateDialog();

  @override
  ConsumerState<_UserCreateDialog> createState() => _UserCreateDialogState();
}

class _UserCreateDialogState extends ConsumerState<_UserCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _salarioCtrl = TextEditingController();

  String _rol = 'vendedor';
  DateTime? _fechaNacimiento;
  DateTime? _fechaIngreso;
  bool _saving = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _cedulaCtrl.dispose();
    _salarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFechaNacimiento() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() => _fechaNacimiento = picked);
  }

  Future<void> _pickFechaIngreso() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() => _fechaIngreso = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null || _fechaIngreso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione fecha de nacimiento e ingreso')),
      );
      return;
    }

    final salario = num.tryParse(_salarioCtrl.text.trim());
    if (salario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salario inválido')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(usersApiProvider).createUser(
            nombreCompleto: _nombreCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            rol: _rol,
            telefono: _telefonoCtrl.text.trim(),
            direccion: _direccionCtrl.text.trim(),
            fechaNacimiento: _fechaNacimiento!,
            cedulaNumero: _cedulaCtrl.text.trim(),
            fechaIngresoEmpresa: _fechaIngreso!,
            salarioMensual: salario,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo usuario'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password (mín 6)'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _rol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'vendedor', child: Text('vendedor')),
                    DropdownMenuItem(value: 'tecnico_fijo', child: Text('tecnico_fijo')),
                    DropdownMenuItem(value: 'contratista', child: Text('contratista')),
                    DropdownMenuItem(value: 'administrador', child: Text('administrador')),
                    DropdownMenuItem(value: 'asistente_administrativo', child: Text('asistente_administrativo')),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _rol = v ?? _rol),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _telefonoCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  validator: (v) => (v == null || v.trim().length < 5) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _pickFechaNacimiento,
                        icon: const Icon(Icons.cake_outlined),
                        label: Text(
                          _fechaNacimiento == null
                              ? 'Fecha nacimiento'
                              : 'Nacimiento: ${_fechaNacimiento!.toIso8601String().substring(0, 10)}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cedulaCtrl,
                  decoration: const InputDecoration(labelText: 'Cédula'),
                  validator: (v) => (v == null || v.trim().length < 5) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _pickFechaIngreso,
                        icon: const Icon(Icons.event_available_outlined),
                        label: Text(
                          _fechaIngreso == null
                              ? 'Fecha ingreso'
                              : 'Ingreso: ${_fechaIngreso!.toIso8601String().substring(0, 10)}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _salarioCtrl,
                  decoration: const InputDecoration(labelText: 'Salario mensual'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (num.tryParse((v ?? '').trim()) == null) ? 'Número requerido' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Crear')),
      ],
    );
  }
}
