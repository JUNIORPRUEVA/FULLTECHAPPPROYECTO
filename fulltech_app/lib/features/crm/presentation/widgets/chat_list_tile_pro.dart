import 'package:flutter/material.dart';

import '../../constants/crm_statuses.dart';
import '../../data/models/crm_thread.dart';
import '../../../catalogo/models/producto.dart';
import '../../../../core/services/app_config.dart';

String? _resolvePublicUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
  final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  if (trimmed.startsWith('/')) return '$base$trimmed';
  return '$base/$trimmed';
}

class ChatListTilePro extends StatelessWidget {
  final CrmThread thread;
  final bool selected;
  final VoidCallback onTap;
  final Producto? product;

  const ChatListTilePro({
    super.key,
    required this.thread,
    required this.selected,
    required this.onTap,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = (thread.displayName != null && thread.displayName!.trim().isNotEmpty)
        ? thread.displayName!.trim()
        : (thread.phone ?? thread.waId);

    final secondary = (thread.phone ?? thread.waId).trim();
    final preview = (thread.lastMessagePreview ?? '').trim();

    final hasUnread = thread.unreadCount > 0;

    final containerColor = selected
        ? theme.colorScheme.primaryContainer.withOpacity(0.35)
        : theme.colorScheme.surface;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: containerColor,
          border: Border(
            left: BorderSide(
              width: 3,
              color: selected ? theme.colorScheme.primary : Colors.transparent,
            ),
            bottom: BorderSide(color: theme.dividerColor, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Text(_initials(title)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (thread.lastMessageAt != null)
                        Text(
                          _timeCompact(thread.lastMessageAt!),
                          style: theme.textTheme.labelSmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview.isEmpty ? '—' : preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        _UnreadBadge(count: thread.unreadCount),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _StatusChip(status: thread.status),
                      if (thread.important)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: const Text('Importante'),
                          avatar: const Icon(Icons.star, size: 16),
                        ),
                      if (product != null)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: CircleAvatar(
                            radius: 10,
                            child: () {
                              final url = _resolvePublicUrl(product!.imagenUrl);
                              if (url == null) {
                                return const Icon(Icons.inventory_2, size: 14);
                              }

                              return ClipOval(
                                child: Image.network(
                                  url,
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.inventory_2,
                                      size: 14,
                                    );
                                  },
                                ),
                              );
                            }(),
                          ),
                          label: Text(
                            product!.nombre,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String v) {
    final parts = v.trim().split(RegExp(r'\s+'));
    final a = parts.isNotEmpty ? parts.first : '';
    final b = parts.length > 1 ? parts[1] : '';
    final s = '${a.isNotEmpty ? a[0] : ''}${b.isNotEmpty ? b[0] : ''}'.toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  static String _timeCompact(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = CrmStatuses.normalizeValue(status);

    Color bg;
    Color fg;

    switch (s) {
      case 'primer_contacto':
        bg = theme.colorScheme.tertiaryContainer;
        fg = theme.colorScheme.onTertiaryContainer;
        break;
      case 'interesado':
        bg = theme.colorScheme.secondaryContainer;
        fg = theme.colorScheme.onSecondaryContainer;
        break;
      case 'reserva':
        bg = theme.colorScheme.tertiaryContainer;
        fg = theme.colorScheme.onTertiaryContainer;
        break;
      case 'por_levantamiento':
      case 'pendiente_pago':
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurface;
        break;
      case 'garantia':
      case 'solucion_garantia':
        bg = theme.colorScheme.errorContainer;
        fg = theme.colorScheme.onErrorContainer;
        break;
      case 'compro':
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.onPrimaryContainer;
        break;
      case 'no_interesado':
      case 'cancelado':
        bg = theme.colorScheme.errorContainer;
        fg = theme.colorScheme.onErrorContainer;
        break;
      default:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurface;
        break;
    }

    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: bg,
      label: Text(
        CrmStatuses.getLabel(s),
        style: theme.textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
