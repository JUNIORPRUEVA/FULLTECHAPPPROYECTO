import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/app_config.dart';
import '../../../core/widgets/module_page.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../models/registered_user.dart';
import '../state/users_providers.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  Future<RegisteredUser>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(usersApiProvider).getUser(widget.userId);
  }

  void _reload() {
    setState(() {
      _future = ref.read(usersApiProvider).getUser(widget.userId);
    });
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
    throw Exception('Unsupported platform to open files');
  }

  Future<String?> _pickAndCacheFile({
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) return null;

    final dir = await getTemporaryDirectory();
    final folder = Directory(p.join(dir.path, 'fulltech_cache', 'user_docs'));
    if (!await folder.exists()) await folder.create(recursive: true);

    final filename = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(path)}';
    final cached = File(p.join(folder.path, filename));
    await File(path).copy(cached.path);
    return cached.path;
  }

  Future<void> _downloadAndOpenPdf({required String id, required String kind}) async {
    try {
      final filePath = await ref.read(usersApiProvider).downloadUserPdfToTempFile(id: id, kind: kind);
      await _openFile(filePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _toggleBlock({required bool block}) async {
    try {
      if (block) {
        await ref.read(usersApiProvider).blockUser(widget.userId);
      } else {
        await ref.read(usersApiProvider).unblockUser(widget.userId);
      }
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: const Text('Esto marcará el usuario como eliminado. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(usersApiProvider).deleteUser(widget.userId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _uploadDocs({required bool isAdmin, required bool isSelf}) async {
    String? foto;
    String? cedula;
    String? carta;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Subir documentos'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Foto perfil (imagen)'),
                      subtitle: Text(foto == null ? 'No seleccionado' : p.basename(foto!)),
                      trailing: OutlinedButton(
                        onPressed: () async {
                          final f = await _pickAndCacheFile(type: FileType.image);
                          if (f == null) return;
                          setLocal(() => foto = f);
                        },
                        child: const Text('Elegir'),
                      ),
                    ),
                    ListTile(
                      title: const Text('Cédula (imagen)'),
                      subtitle: Text(cedula == null ? 'No seleccionado' : p.basename(cedula!)),
                      trailing: OutlinedButton(
                        onPressed: !isAdmin
                            ? null
                            : () async {
                                final f = await _pickAndCacheFile(type: FileType.image);
                                if (f == null) return;
                                setLocal(() => cedula = f);
                              },
                        child: const Text('Elegir'),
                      ),
                    ),
                    ListTile(
                      title: const Text('Carta último trabajo (PDF o imagen)'),
                      subtitle: Text(carta == null ? 'No seleccionado' : p.basename(carta!)),
                      trailing: OutlinedButton(
                        onPressed: !isAdmin
                            ? null
                            : () async {
                                final f = await _pickAndCacheFile(
                                  type: FileType.custom,
                                  allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
                                );
                                if (f == null) return;
                                setLocal(() => carta = f);
                              },
                        child: const Text('Elegir'),
                      ),
                    ),
                    if (!isAdmin && isSelf)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Nota: solo puedes subir/actualizar tu foto de perfil.'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Subir')),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;

    try {
      final upload = await ref.read(usersApiProvider).uploadUserDocs(
            fotoPerfilPath: foto,
            cedulaFotoPath: isAdmin ? cedula : null,
            cartaUltimoTrabajoPath: isAdmin ? carta : null,
          );

      final patch = <String, dynamic>{};
      if (upload.fotoPerfilUrl != null) patch['foto_perfil_url'] = upload.fotoPerfilUrl;
      if (isAdmin && upload.cedulaFotoUrl != null) patch['cedula_foto_url'] = upload.cedulaFotoUrl;
      if (isAdmin && upload.cartaUltimoTrabajoUrl != null) {
        patch['carta_ultimo_trabajo_url'] = upload.cartaUltimoTrabajoUrl;
      }
      if (patch.isNotEmpty) {
        await ref.read(usersApiProvider).updateUser(widget.userId, patch);
      }
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final auth = ref.watch(authControllerProvider);
    final selfId = (auth is AuthAuthenticated) ? auth.user.id : null;
    final isSelf = selfId == widget.userId;

    return ModulePage(
      title: 'Usuario',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: FutureBuilder<RegisteredUser>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }
          final user = snap.data!;
          final fotoUrl = resolvePublicUrl(user.fotoPerfilUrl);

          final canAdminActions = isAdmin;
          final canEdit = isAdmin || isSelf;

          return ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                            child: fotoUrl == null ? const Icon(Icons.person_outline, size: 28) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.nombreCompleto,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text('${user.email} • ${user.rol} • ${user.estado ?? '-'}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: canEdit
                                ? () async {
                                    final changed = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => _UserEditDialog(user: user, isAdmin: isAdmin, isSelf: isSelf),
                                    );
                                    if (changed == true) _reload();
                                  }
                                : null,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _uploadDocs(isAdmin: isAdmin, isSelf: isSelf),
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Subir docs'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _downloadAndOpenPdf(id: user.id, kind: 'profile-pdf'),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Ficha PDF'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _downloadAndOpenPdf(id: user.id, kind: 'contract-pdf'),
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('Contrato PDF'),
                          ),
                          if (canAdminActions)
                            OutlinedButton.icon(
                              onPressed: (user.estado == 'bloqueado')
                                  ? () => _toggleBlock(block: false)
                                  : () => _toggleBlock(block: true),
                              icon: Icon(user.estado == 'bloqueado' ? Icons.lock_open_outlined : Icons.lock_outline),
                              label: Text(user.estado == 'bloqueado' ? 'Desbloquear' : 'Bloquear'),
                            ),
                          if (canAdminActions)
                            OutlinedButton.icon(
                              onPressed: _deleteUser,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Eliminar'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Datos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _kv('Teléfono', user.telefono),
                      _kv('Dirección', user.direccion),
                      _kv('Cédula', user.cedulaNumero ?? '-'),
                      _kv('Fecha nacimiento', user.fechaNacimiento?.toIso8601String().substring(0, 10) ?? '-'),
                      _kv('Edad', user.edad?.toString() ?? '-'),
                      _kv('Fecha ingreso', user.fechaIngresoEmpresa?.toIso8601String().substring(0, 10) ?? '-'),
                      _kv('Salario mensual', user.salarioMensual?.toString() ?? '-'),
                      const SizedBox(height: 12),
                      Text(
                        'Documentos (URLs públicas):',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      _docLine('Foto perfil', user.fotoPerfilUrl),
                      _docLine('Cédula', user.cedulaFotoUrl),
                      _docLine('Carta', user.cartaUltimoTrabajoUrl),
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

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 170, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Widget _docLine(String label, String? url) {
    final resolved = resolvePublicUrl(url);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: ${resolved ?? '-'}'),
    );
  }
}

class _UserEditDialog extends ConsumerStatefulWidget {
  final RegisteredUser user;
  final bool isAdmin;
  final bool isSelf;

  const _UserEditDialog({
    required this.user,
    required this.isAdmin,
    required this.isSelf,
  });

  @override
  ConsumerState<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends ConsumerState<_UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _direccionCtrl;

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _salarioCtrl;

  String? _rol;
  String? _estado;
  DateTime? _fechaNacimiento;
  DateTime? _fechaIngreso;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _telefonoCtrl = TextEditingController(text: widget.user.telefono);
    _direccionCtrl = TextEditingController(text: widget.user.direccion);

    _nombreCtrl = TextEditingController(text: widget.user.nombreCompleto);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _cedulaCtrl = TextEditingController(text: widget.user.cedulaNumero ?? '');
    _salarioCtrl = TextEditingController(text: widget.user.salarioMensual?.toString() ?? '');

    _rol = widget.user.rol;
    _estado = widget.user.estado;
    _fechaNacimiento = widget.user.fechaNacimiento;
    _fechaIngreso = widget.user.fechaIngresoEmpresa;
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
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

  static String _dateOnly(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final patch = <String, dynamic>{
        'telefono': _telefonoCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
      };

      if (widget.isAdmin) {
        patch['nombre_completo'] = _nombreCtrl.text.trim();
        patch['email'] = _emailCtrl.text.trim();
        patch['rol'] = _rol;
        if (_estado != null) patch['estado'] = _estado;
        if (_cedulaCtrl.text.trim().isNotEmpty) patch['cedula_numero'] = _cedulaCtrl.text.trim();
        final salario = num.tryParse(_salarioCtrl.text.trim());
        if (salario != null) patch['salario_mensual'] = salario;
        if (_fechaNacimiento != null) patch['fecha_nacimiento'] = _dateOnly(_fechaNacimiento!);
        if (_fechaIngreso != null) patch['fecha_ingreso_empresa'] = _dateOnly(_fechaIngreso!);
      }

      await ref.read(usersApiProvider).updateUser(widget.user.id, patch);
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
      title: const Text('Editar usuario'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (widget.isAdmin) ...[
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
                  DropdownButtonFormField<String>(
                    initialValue: _rol,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: const [
                      DropdownMenuItem(value: 'vendedor', child: Text('vendedor')),
                      DropdownMenuItem(value: 'tecnico_fijo', child: Text('tecnico_fijo')),
                      DropdownMenuItem(value: 'contratista', child: Text('contratista')),
                      DropdownMenuItem(value: 'administrador', child: Text('administrador')),
                      DropdownMenuItem(value: 'asistente_administrativo', child: Text('asistente_administrativo')),
                      DropdownMenuItem(value: 'admin', child: Text('admin (legacy)')),
                      DropdownMenuItem(value: 'tecnico', child: Text('tecnico (legacy)')),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _rol = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(value: 'activo', child: Text('activo')),
                      DropdownMenuItem(value: 'bloqueado', child: Text('bloqueado')),
                      DropdownMenuItem(value: 'eliminado', child: Text('eliminado')),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _estado = v),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _cedulaCtrl,
                    decoration: const InputDecoration(labelText: 'Cédula'),
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
                  ),
                  const Divider(height: 24),
                ],
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
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Guardar')),
      ],
    );
  }
}
