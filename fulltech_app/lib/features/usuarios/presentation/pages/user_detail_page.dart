import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_config.dart';
import '../../../../core/widgets/pdf_viewer_page.dart';
import '../../../../core/widgets/module_page.dart';
import '../../../auth/state/auth_providers.dart';
import '../../data/models/user_model.dart';
import '../../state/users_providers.dart';
import '../widgets/document_preview.dart';
import 'user_form_page.dart';

class UserDetailPage extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage> {
  Future<UserModel>? _future;

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

  void _reload() {
    setState(() {
      _future = ref.read(usersRepositoryProvider).getUser(widget.userId);
    });
  }

  void _viewPdfInApp({required String title, required String kind}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          title: title,
          loadFilePath: () => ref
              .read(usersRepositoryProvider)
              .downloadUserPdfToTempFile(id: widget.userId, kind: kind),
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
    required String kind,
    required String fileName,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await ref
          .read(usersRepositoryProvider)
          .downloadUserPdfToDownloadsFile(
            id: widget.userId,
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

  @override
  void initState() {
    super.initState();
    _future = ref.read(usersRepositoryProvider).getUser(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return ModulePage(
      title: 'Usuario',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Editar',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserFormPage(userId: widget.userId),
              ),
            );
          },
          icon: const Icon(Icons.edit),
        ),
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () {
            ref.read(authControllerProvider.notifier).logout();
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      child: FutureBuilder<UserModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }
          final u = snap.data;
          if (u == null) {
            return const Center(child: Text('Usuario no encontrado'));
          }

          final fotoUrl = _resolvePublicUrl(u.fotoPerfilUrl);
          final cedulaFrontalUrl = _resolvePublicUrl(u.cedulaFrontalUrl);
          final cedulaPosteriorUrl = _resolvePublicUrl(u.cedulaPosteriorUrl);
          final licenciaConducirUrl = _resolvePublicUrl(u.licenciaConducirUrl);
          final cartaTrabajoUrl = _resolvePublicUrl(u.cartaTrabajoUrl);
          final curriculumUrl = _resolvePublicUrl(u.curriculumVitaeUrl);

          final otrosDocs = u.otrosDocumentos
              .map(_resolvePublicUrl)
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .toList();

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
                        backgroundImage: fotoUrl != null
                            ? NetworkImage(fotoUrl)
                            : null,
                        child: fotoUrl == null
                            ? const Icon(Icons.person_outline, size: 54)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        u.nombre,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
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
                            label: Text(u.rol),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(u.estado),
                            visualDensity: VisualDensity.compact,
                          ),
                          if ((u.posicion ?? '').trim().isNotEmpty)
                            Chip(
                              label: Text(u.posicion!),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      runSpacing: 10,
                      spacing: 24,
                      children: [
                        SizedBox(width: 520, child: _KV('Email', u.email)),
                        SizedBox(
                          width: 360,
                          child: _KV('Teléfono', u.telefono ?? 'N/A'),
                        ),
                        SizedBox(
                          width: 360,
                          child: _KV(
                            'Fecha ingreso',
                            _formatDateOrNA(u.fechaIngreso),
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
                            title: 'Ficha (PDF)',
                            kind: 'profile-pdf',
                          ),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Ficha PDF'),
                        ),
                        FilledButton.icon(
                          onPressed: () => _viewPdfInApp(
                            title: 'Contrato (PDF)',
                            kind: 'contract-pdf',
                          ),
                          icon: const Icon(Icons.visibility),
                          label: const Text('Ver contrato PDF'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _downloadPdfToDownloads(
                            kind: 'contract-pdf',
                            fileName: 'Contrato_${widget.userId}.pdf',
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
                        _KV('Nombre', u.nombre),
                        _KV('Cédula', u.cedulaNumero ?? 'N/A'),
                        _KV(
                          'Fecha nacimiento',
                          _formatDateOrNA(u.fechaNacimiento),
                        ),
                        _KV('Edad', u.edad != null ? '${u.edad}' : 'N/A'),
                        _KV('Lugar nacimiento', u.lugarNacimiento ?? 'N/A'),
                      ],
                    ),

                    _Section(
                      title: 'Contacto',
                      isDesktop: isDesktop,
                      children: [
                        _KV('Dirección', u.direccion ?? 'N/A'),
                        _KV('Ubicación mapa', u.ubicacionMapa ?? 'N/A'),
                      ],
                    ),

                    _Section(
                      title: 'Familiar / Patrimonio',
                      isDesktop: isDesktop,
                      children: [
                        _KV('Casado', u.esCasado ? 'Sí' : 'No'),
                        _KV('Cantidad hijos', '${u.cantidadHijos}'),
                        _KV('Casa propia', u.tieneCasa ? 'Sí' : 'No'),
                        _KV('Vehículo', u.tieneVehiculo ? 'Sí' : 'No'),
                        _KV('Tipo vehículo', u.tipoVehiculo ?? 'N/A'),
                        _KV('Placa', u.placa ?? 'N/A'),
                      ],
                    ),

                    _Section(
                      title: 'Información laboral',
                      isDesktop: isDesktop,
                      children: [
                        _KV('Rol', u.rol),
                        _KV('Posición', u.posicion ?? u.rol),
                        _KV('Área', u.areaManeja ?? 'N/A'),
                        _KV(
                          'Salario mensual',
                          _formatMoneyOrNA(u.salarioMensual),
                        ),
                        _KV('Beneficios', u.beneficios ?? 'N/A'),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Galería de documentos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, c) {
                        final itemWidth = isDesktop ? 170.0 : c.maxWidth;
                        const thumbHeight = 84.0;

                        final previews = <Widget>[
                          SizedBox(
                            width: itemWidth,
                            child: DocumentPreview(
                              label: 'Foto perfil',
                              imageUrl: fotoUrl,
                              previewHeight: thumbHeight,
                              onTapPreview: fotoUrl != null
                                  ? () => _viewImageFullScreen(
                                      title: 'Foto perfil',
                                      url: fotoUrl,
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: DocumentPreview(
                              label: 'Cédula frontal',
                              imageUrl: cedulaFrontalUrl,
                              previewHeight: thumbHeight,
                              onTapPreview: cedulaFrontalUrl != null
                                  ? () => _viewImageFullScreen(
                                      title: 'Cédula frontal',
                                      url: cedulaFrontalUrl,
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: DocumentPreview(
                              label: 'Cédula posterior',
                              imageUrl: cedulaPosteriorUrl,
                              previewHeight: thumbHeight,
                              onTapPreview: cedulaPosteriorUrl != null
                                  ? () => _viewImageFullScreen(
                                      title: 'Cédula posterior',
                                      url: cedulaPosteriorUrl,
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: DocumentPreview(
                              label: 'Licencia conducir',
                              imageUrl: licenciaConducirUrl,
                              previewHeight: thumbHeight,
                              onTapPreview: licenciaConducirUrl != null
                                  ? () => _viewImageFullScreen(
                                      title: 'Licencia conducir',
                                      url: licenciaConducirUrl,
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: DocumentPreview(
                              label: 'Carta trabajo',
                              imageUrl: cartaTrabajoUrl,
                              previewHeight: thumbHeight,
                              onTapPreview: cartaTrabajoUrl != null
                                  ? () => _viewImageFullScreen(
                                      title: 'Carta trabajo',
                                      url: cartaTrabajoUrl,
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: DocumentPreview(
                              label: 'Currículum vitae',
                              imageUrl: curriculumUrl,
                              previewHeight: thumbHeight,
                              onTapPreview: curriculumUrl != null
                                  ? () => _viewImageFullScreen(
                                      title: 'Currículum vitae',
                                      url: curriculumUrl,
                                    )
                                  : null,
                            ),
                          ),
                        ];

                        for (var i = 0; i < otrosDocs.length; i++) {
                          previews.add(
                            SizedBox(
                              width: itemWidth,
                              child: DocumentPreview(
                                label: 'Otro documento ${i + 1}',
                                imageUrl: otrosDocs[i],
                                previewHeight: thumbHeight,
                                onTapPreview: () => _viewImageFullScreen(
                                  title: 'Otro documento ${i + 1}',
                                  url: otrosDocs[i],
                                ),
                              ),
                            ),
                          );
                        }

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: previews,
                        );
                      },
                    ),

                    _Section(
                      title: 'Licencias y documentos (resumen)',
                      isDesktop: isDesktop,
                      children: [
                        _KV(
                          'Licencia conducir',
                          u.licenciaConducirNumero ?? 'N/A',
                        ),
                        _KV(
                          'Vence licencia',
                          _formatDateOrNA(u.licenciaConducirVencimiento),
                        ),
                        _KV(
                          'Cédula frontal',
                          u.cedulaFrontalUrl != null ? 'Sí' : 'No',
                        ),
                        _KV(
                          'Cédula posterior',
                          u.cedulaPosteriorUrl != null ? 'Sí' : 'No',
                        ),
                        _KV(
                          'Licencia conducir (foto)',
                          u.licenciaConducirUrl != null ? 'Sí' : 'No',
                        ),
                        _KV(
                          'Carta trabajo',
                          u.cartaTrabajoUrl != null ? 'Sí' : 'No',
                        ),
                        _KV(
                          'Currículum vitae',
                          u.curriculumVitaeUrl != null ? 'Sí' : 'No',
                        ),
                        _KV(
                          'Otros documentos',
                          '${u.otrosDocumentos.length} archivo(s)',
                        ),
                      ],
                    ),

                    _Section(
                      title: 'Sistema',
                      isDesktop: isDesktop,
                      children: [
                        _KV('ID usuario', u.id),
                        _KV('Empresa ID', u.empresaId),
                        _KV('Creado', _formatDateOrNA(u.createdAt)),
                        _KV('Actualizado', _formatDateOrNA(u.updatedAt)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
