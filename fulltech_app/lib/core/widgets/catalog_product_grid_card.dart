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

    if (qty <= 0) {
      return (
        bg: cs.errorContainer,
        fg: cs.onErrorContainer,
        text: 'Stock: ${qty.toStringAsFixed(0)}',
      );
    }

    if (qty <= min) {
      return (
        bg: cs.tertiaryContainer,
        fg: cs.onTertiaryContainer,
        text: 'Stock: ${qty.toStringAsFixed(0)}',
      );
    }

    return (
      bg: cs.primaryContainer,
      fg: cs.onPrimaryContainer,
      text: 'Stock: ${qty.toStringAsFixed(0)}',
    );
  }

  String _publicUrlFromMaybeRelative(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api$'), '');
    if (v.startsWith('/')) return '$base$v';
    return '$base/$v';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final stockBadge = _stockBadge(context);

    final normalizedImageRaw = imageRaw.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (normalizedImageRaw.isNotEmpty)
              Image.network(
                _publicUrlFromMaybeRelative(normalizedImageRaw),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              )
            else
              Container(
                color: cs.surfaceContainerHighest,
                child: Icon(Icons.photo_outlined, color: cs.onSurfaceVariant),
              ),
            if (stockBadge != null)
              Positioned(
                left: 8,
                top: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: stockBadge.bg.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      stockBadge.text,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: stockBadge.fg,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.88),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
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
