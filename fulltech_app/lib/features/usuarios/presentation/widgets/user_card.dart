import 'package:flutter/material.dart';

import '../../../../core/services/app_config.dart';
import '../../data/models/user_model.dart';

class UserCard extends StatelessWidget {
  final UserSummary user;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggleBlock;
  final VoidCallback onDelete;
  final VoidCallback onDownloadProfilePdf;
  final VoidCallback onDownloadContractPdf;

  const UserCard({
    super.key,
    required this.user,
    required this.onView,
    required this.onEdit,
    required this.onToggleBlock,
    required this.onDelete,
    required this.onDownloadProfilePdf,
    required this.onDownloadContractPdf,
  });

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

  @override
  Widget build(BuildContext context) {
    final photo = resolvePublicUrl(user.fotoPerfilUrl);
    final isBlocked = user.estado == 'bloqueado';

    return Card(
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null ? const Icon(Icons.person_outline) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Pill(text: user.rol),
                        _Pill(text: user.estado),
                        if ((user.telefono ?? '').trim().isNotEmpty) _Pill(text: user.telefono!),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Acciones',
                onSelected: (v) {
                  switch (v) {
                    case 'view':
                      onView();
                      break;
                    case 'edit':
                      onEdit();
                      break;
                    case 'toggle':
                      onToggleBlock();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                    case 'pdf_profile':
                      onDownloadProfilePdf();
                      break;
                    case 'pdf_contract':
                      onDownloadContractPdf();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'view', child: Text('Ver')),
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'toggle', child: Text(isBlocked ? 'Desbloquear' : 'Bloquear')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'pdf_profile', child: Text('Descargar ficha PDF')),
                  const PopupMenuItem(value: 'pdf_contract', child: Text('Descargar contrato PDF')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
