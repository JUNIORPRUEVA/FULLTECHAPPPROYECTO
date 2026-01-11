import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/app_config.dart';

class CatalogProductGridCard extends StatelessWidget {
  final String nombre;
  final String priceText;
  final String costText;
  final bool canSeeCost;
  final String imageRaw;
  final double? stockQty;
  final double? minStock;
  final VoidCallback onTap;

  const CatalogProductGridCard({
    super.key,
    required this.nombre,
    required this.priceText,
    required this.costText,
    required this.canSeeCost,
    required this.imageRaw,
    this.stockQty,
    this.minStock,
    required this.onTap,
  });

  ({Color bg, Color fg, String text})? _stockBadge(BuildContext context) {
    final qty = stockQty;
    if (qty == null) return null;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final min = minStock ?? 0;
    final label = qty.toStringAsFixed(0);

    // 3 colores: rojo (0 o menos), ámbar (bajo), verde (ok)
    if (qty <= 0) {
      return (bg: cs.errorContainer, fg: cs.onErrorContainer, text: label);
    }

    if (qty <= min) {
      return (
        bg: cs.tertiaryContainer,
        fg: cs.onTertiaryContainer,
        text: label,
      );
    }

    return (bg: cs.primaryContainer, fg: cs.onPrimaryContainer, text: label);
  }

  String _publicUrlFromMaybeRelative(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api$'), '');
    if (v.startsWith('/')) return '$base$v';
    return '$base/$v';
  }

  bool _isLikelyLocalPath(String value) {
    // Treat backend-served paths like /uploads/... as remote (not local).
    if (value.startsWith('/uploads/')) return false;

    // Windows: C:\... or C:/...
    if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(value)) return true;
    // file://...
    if (value.startsWith('file://')) return true;
    return false;
  }

  String _normalizeFilePath(String raw) {
    if (raw.startsWith('file://')) {
      final uri = Uri.tryParse(raw);
      if (uri != null) return uri.toFilePath();
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final stockBadge = _stockBadge(context);

    final normalizedImageRaw = imageRaw.trim();

    Widget buildImage() {
      if (normalizedImageRaw.isEmpty) {
        return Container(
          color: cs.surfaceContainerHighest,
          child: Icon(Icons.photo_outlined, color: cs.onSurfaceVariant),
        );
      }

      if (_isLikelyLocalPath(normalizedImageRaw)) {
        if (kIsWeb) {
          return Container(
            color: cs.surfaceContainerHighest,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: cs.onSurfaceVariant,
            ),
          );
        }

        final path = _normalizeFilePath(normalizedImageRaw);
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: cs.surfaceContainerHighest,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: cs.onSurfaceVariant,
            ),
          ),
        );
      }

      final url = _publicUrlFromMaybeRelative(normalizedImageRaw);
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.hasScheme && uri.hasAuthority)) {
        return Container(
          color: cs.surfaceContainerHighest,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: cs.onSurfaceVariant,
          ),
        );
      }

      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: cs.surfaceContainerHighest,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            buildImage(),
            if (stockBadge != null)
              Positioned(
                right: 8,
                top: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: stockBadge.bg.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: stockBadge.fg,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          stockBadge.text,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: stockBadge.fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.90),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'RD\$ $priceText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (canSeeCost)
                          Expanded(
                            child: Text(
                              'RD\$ $costText',
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.error,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
