import 'dart:typed_data';

import 'package:flutter/material.dart';

class DocumentPreview extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final VoidCallback? onPick;
  final VoidCallback? onTapPreview;
  final double previewHeight;

  const DocumentPreview({
    super.key,
    required this.label,
    this.imageUrl,
    this.imageBytes,
    this.onPick,
    this.onTapPreview,
    this.previewHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        (imageBytes != null) ||
        (imageUrl != null && imageUrl!.trim().isNotEmpty);

    Widget preview;
    if (hasImage) {
      final img = imageBytes != null
          ? Image.memory(imageBytes!, fit: BoxFit.cover)
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );

      preview = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: previewHeight,
          width: double.infinity,
          child: img,
        ),
      );
    } else {
      preview = Container(
        height: previewHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (onTapPreview != null)
          InkWell(
            onTap: onTapPreview,
            borderRadius: BorderRadius.circular(12),
            child: preview,
          )
        else
          preview,
        if (onPick != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Seleccionar'),
            ),
          ),
        ],
      ],
    );
  }
}
