import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_config.dart';
import '../../../core/widgets/module_page.dart';
import '../../../core/widgets/pdf_viewer_page.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../../usuarios/data/models/user_model.dart';
import '../../usuarios/presentation/widgets/document_preview.dart';
import '../../usuarios/state/users_providers.dart';
import '../../nomina/screens/my_payroll_screen.dart';

final _perfilUserByIdProvider = FutureProvider.autoDispose
    .family<UserModel, String>((ref, userId) async {
      return ref.read(usersRepositoryProvider).getUser(userId);
    });

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _editing = false;
  bool _saving = false;
  String? _initializedUserId;

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _password2Ctrl;

  _PickedDoc? _newFotoPerfil;

  static String _publicBase() {
    final base = AppConfig.apiBaseUrl;
    return base.replaceFirst(RegExp(r'/api/?$'), '');
  }

  static String? _resolvePublicUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) return '${_publicBase()}$trimmed';
    return '${_publicBase()}/$trimmed';
  }

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _password2Ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    super.dispose();
  }

  void _initControllersFromUser(UserModel user, {required String userId}) {
    if (_initializedUserId == userId) return;
    _initializedUserId = userId;
    _nombreCtrl.text = user.nombre;
    _emailCtrl.text = user.email;
    _passwordCtrl.clear();
    _password2Ctrl.clear();
    _newFotoPerfil = null;
  }

  String _formatDateOrNA(DateTime? d) {
    if (d == null) return 'N/A';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  String _formatMoneyOrNA(num? value) {
    if (value == null) return 'N/A';
    return 'RD\$ ${value.toDouble().toStringAsFixed(2)}';
  }

  Future<_PickedDoc?> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );
    final f = res?.files.single;
    if (f == null) return null;
    if (f.bytes == null && (f.path == null || f.path!.trim().isEmpty)) {
      return null;
    }
    return _PickedDoc(path: f.path, bytes: f.bytes);
  }

  MultipartFile _toMultipart(_PickedDoc doc) {
    if (doc.bytes != null) {
      return MultipartFile.fromBytes(doc.bytes!, filename: 'perfil.jpg');
    }
    return MultipartFile.fromFileSync(doc.path!);
  }

  void _viewPdfInApp({
    required String userId,
    required String title,
    required String kind,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          title: title,
          loadFilePath: () => ref
              .read(usersRepositoryProvider)
              .downloadUserPdfToTempFile(id: userId, kind: kind),
        ),
      ),
    );
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

  Future<void> _downloadPdfToDownloads({
    required String userId,
    required String kind,
    required String fileName,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await ref
          .read(usersRepositoryProvider)
          .downloadUserPdfToDownloadsFile(
            id: userId,
            kind: kind,
            fileName: fileName,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('PDF guardado en: $path'),
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () => _openFile(path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo descargar el PDF: $e')),
      );
    }
  }

  void _viewImageFullScreen({required String title, required String url}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImagePage(title: title, url: url),
      ),
    );
  }

  Future<void> _saveEdits({required String userId}) async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);

    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;
    final pass2 = _password2Ctrl.text;

    if (nombre.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('El nombre es requerido.')),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      messenger.showSnackBar(const SnackBar(content: Text('Email inválido.')));
      return;
    }
    final wantsPassword = pass.trim().isNotEmpty || pass2.trim().isNotEmpty;
    if (wantsPassword) {
      if (pass.trim().length < 6) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('La contraseña debe tener al menos 6 caracteres.'),
          ),
        );
        return;
      }
      if (pass != pass2) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden.')),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      String? fotoPerfilUrl;
      if (_newFotoPerfil != null) {
        final upload = await ref
            .read(usersRepositoryProvider)
            .uploadUserDocuments(fotoPerfil: _toMultipart(_newFotoPerfil!));
        final raw = upload['foto_perfil_url'];
        if (raw is String && raw.trim().isNotEmpty) {
          fotoPerfilUrl = raw.trim();
        }
      }

      final patch = <String, dynamic>{
        'nombre_completo': nombre,
        'email': email,
      };
      if (fotoPerfilUrl != null) patch['foto_perfil_url'] = fotoPerfilUrl;
      if (wantsPassword) patch['password'] = pass;

      await ref.read(usersRepositoryProvider).updateUser(userId, patch);

      if (!mounted) return;
      ref.invalidate(_perfilUserByIdProvider(userId));

      setState(() {
        _editing = false;
        _saving = false;
      });

      if (wantsPassword) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Contraseña actualizada. Debes iniciar sesión de nuevo.',
            ),
          ),
        );
        ref.read(authControllerProvider.notifier).logout();
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Perfil actualizado.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    if (auth is! AuthAuthenticated) {
      return const ModulePage(
        title: 'Perfil',
        child: Center(child: Text('No autenticado')),
      );
    }

    final userId = auth.user.id;
    final userFuture = ref.watch(_perfilUserByIdProvider(userId));

    return ModulePage(
      title: 'Mi Perfil',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () => ref.invalidate(_perfilUserByIdProvider(userId)),
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: _editing ? 'Cancelar edición' : 'Editar',
          onPressed: () => setState(() => _editing = !_editing),
          icon: Icon(_editing ? Icons.close : Icons.edit),
        ),
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          icon: const Icon(Icons.logout),
        ),
      ],
      child: userFuture.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (user) {
          _initControllersFromUser(user, userId: userId);
          return _buildProfileContent(context, userId: userId, user: user);
        },
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context, {
    required String userId,
    required UserModel user,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final fotoUrl = _resolvePublicUrl(user.fotoPerfilUrl);
    final cedulaFrontalUrl = _resolvePublicUrl(user.cedulaFrontalUrl);
    final cedulaPosteriorUrl = _resolvePublicUrl(user.cedulaPosteriorUrl);
    final licenciaConducirUrl = _resolvePublicUrl(user.licenciaConducirUrl);
    final cartaTrabajoUrl = _resolvePublicUrl(user.cartaTrabajoUrl);
    final curriculumUrl = _resolvePublicUrl(user.curriculumVitaeUrl);

    final otrosDocs = user.otrosDocumentos
        .map(_resolvePublicUrl)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final ImageProvider? previewFoto = _newFotoPerfil != null
        ? (_newFotoPerfil!.bytes != null
              ? MemoryImage(Uint8List.fromList(_newFotoPerfil!.bytes!))
              : FileImage(File(_newFotoPerfil!.path!)) as ImageProvider)
        : (fotoUrl != null ? NetworkImage(fotoUrl) : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 54,
                  backgroundImage: previewFoto,
                  child: previewFoto == null
                      ? const Icon(Icons.person_outline, size: 54)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Mis Nóminas'),
                  subtitle: const Text('Historial, detalles y recibos PDF'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyPayrollScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.nombre,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(user.rol),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text(user.estado),
                      visualDensity: VisualDensity.compact,
                    ),
                    if ((user.posicion ?? '').trim().isNotEmpty)
                      Chip(
                        label: Text(user.posicion!),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_editing) ...[
                const Divider(height: 18),
                Text(
                  'Editar (solo nombre, email, contraseña y foto de perfil)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  runSpacing: 12,
                  spacing: 12,
                  children: [
                    SizedBox(
                      width: 420,
                      child: TextField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                    ),
                    SizedBox(
                      width: 420,
                      child: TextField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    SizedBox(
                      width: 420,
                      child: TextField(
                        controller: _passwordCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nueva contraseña',
                        ),
                        obscureText: true,
                      ),
                    ),
                    SizedBox(
                      width: 420,
                      child: TextField(
                        controller: _password2Ctrl,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña',
                        ),
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () async {
                              final picked = await _pickImage();
                              if (!mounted) return;
                              setState(() => _newFotoPerfil = picked);
                            },
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Cambiar foto de perfil'),
                    ),
                    FilledButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _saveEdits(userId: userId),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Guardar cambios'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              Wrap(
                runSpacing: 10,
                spacing: 24,
                children: [
                  SizedBox(width: 520, child: _KV('Email', user.email)),
                  SizedBox(
                    width: 360,
                    child: _KV('Teléfono', user.telefono ?? 'N/A'),
                  ),
                  SizedBox(
                    width: 360,
                    child: _KV(
                      'Fecha ingreso',
                      _formatDateOrNA(user.fechaIngreso),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => _viewPdfInApp(
                      userId: userId,
                      title: 'Ficha (PDF)',
                      kind: 'profile-pdf',
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Ficha PDF'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _viewPdfInApp(
                      userId: userId,
                      title: 'Contrato (PDF)',
                      kind: 'contract-pdf',
                    ),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver contrato PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _downloadPdfToDownloads(
                      userId: userId,
                      kind: 'contract-pdf',
                      fileName: 'Contrato_$userId.pdf',
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar contrato PDF'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),

              _Section(
                title: 'Información personal',
                isDesktop: isDesktop,
                children: [
                  _KV('Nombre', user.nombre),
                  _KV('Cédula', user.cedulaNumero ?? 'N/A'),
                  _KV(
                    'Fecha nacimiento',
                    _formatDateOrNA(user.fechaNacimiento),
                  ),
                  _KV('Edad', user.edad != null ? '${user.edad}' : 'N/A'),
                  _KV('Lugar nacimiento', user.lugarNacimiento ?? 'N/A'),
                ],
              ),

              _Section(
                title: 'Contacto',
                isDesktop: isDesktop,
                children: [
                  _KV('Dirección', user.direccion ?? 'N/A'),
                  _KV('Ubicación mapa', user.ubicacionMapa ?? 'N/A'),
                ],
              ),

              _Section(
                title: 'Familiar / Patrimonio',
                isDesktop: isDesktop,
                children: [
                  _KV('Casado', user.esCasado ? 'Sí' : 'No'),
                  _KV('Cantidad hijos', '${user.cantidadHijos}'),
                  _KV('Casa propia', user.tieneCasa ? 'Sí' : 'No'),
                  _KV('Vehículo', user.tieneVehiculo ? 'Sí' : 'No'),
                  _KV('Tipo vehículo', user.tipoVehiculo ?? 'N/A'),
                  _KV('Placa', user.placa ?? 'N/A'),
                ],
              ),

              _Section(
                title: 'Información laboral',
                isDesktop: isDesktop,
                children: [
                  _KV('Rol', user.rol),
                  _KV('Posición', user.posicion ?? user.rol),
                  _KV('Área', user.areaManeja ?? 'N/A'),
                  _KV('Salario mensual', _formatMoneyOrNA(user.salarioMensual)),
                  _KV('Beneficios', user.beneficios ?? 'N/A'),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                'Galería de documentos',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, c) {
                  final itemWidth = isDesktop ? 170.0 : c.maxWidth;
                  const thumbHeight = 84.0;

                  Widget item(String label, String? url) {
                    return SizedBox(
                      width: itemWidth,
                      child: DocumentPreview(
                        label: label,
                        imageUrl: url,
                        previewHeight: thumbHeight,
                        onTapPreview: url != null
                            ? () => _viewImageFullScreen(title: label, url: url)
                            : null,
                      ),
                    );
                  }

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      item('Foto perfil', fotoUrl),
                      item('Cédula frontal', cedulaFrontalUrl),
                      item('Cédula posterior', cedulaPosteriorUrl),
                      item('Licencia conducir', licenciaConducirUrl),
                      item('Carta trabajo', cartaTrabajoUrl),
                      item('Currículum', curriculumUrl),
                      for (var i = 0; i < otrosDocs.length; i++)
                        item('Otro ${i + 1}', otrosDocs[i]),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),
              _Section(
                title: 'Sistema',
                isDesktop: isDesktop,
                children: [
                  _KV('Creado', _formatDateOrNA(user.createdAt)),
                  _KV('Actualizado', _formatDateOrNA(user.updatedAt)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final bool isDesktop;
  final List<_KV> children;

  const _Section({
    required this.title,
    required this.isDesktop,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (isDesktop)
            Wrap(
              runSpacing: 10,
              spacing: 24,
              children: children
                  .map((kv) => SizedBox(width: 360, child: kv))
                  .toList(),
            )
          else
            Column(
              children: children
                  .map(
                    (kv) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: kv,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String k;
  final String v;

  const _KV(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            k,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(v)),
      ],
    );
  }
}

class _FullScreenImagePage extends StatelessWidget {
  final String title;
  final String url;

  const _FullScreenImagePage({required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InteractiveViewer(
        minScale: 0.6,
        maxScale: 5,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudo abrir la imagen.\nEs posible que el archivo no sea una imagen.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PickedDoc {
  final String? path;
  final List<int>? bytes;

  const _PickedDoc({required this.path, required this.bytes});
}
