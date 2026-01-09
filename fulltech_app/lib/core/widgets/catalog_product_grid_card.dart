import 'package:flutter/material.dart';

import '../services/app_config.dart';

class CatalogProductGridCard extends StatelessWidget {
  final String nombre;
  final String priceText;
  final String costText;
  final bool canSeeCost;
  final String imageRaw;
  final VoidCallback onTap;

  const CatalogProductGridCard({
    super.key,
    required this.nombre,
    required this.priceText,
    required this.costText,
    required this.canSeeCost,
    required this.imageRaw,
    required this.onTap,
  });

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
                child: Icon(
                  Icons.photo_outlined,
                  color: cs.onSurfaceVariant,
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
