import 'package:flutter/material.dart';

Widget adaptiveImage(
  String source, {
  BoxFit? fit,
  double? width,
  double? height,
  BorderRadius? borderRadius,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  final s = source.trim();
  final uri = Uri.tryParse(s);
  final isRemote =
      uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

  final child = isRemote
      ? Image.network(
          s,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder,
        )
      : Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined),
        );

  if (borderRadius == null) return child;
  return ClipRRect(borderRadius: borderRadius, child: child);
}
