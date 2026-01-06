import 'dart:io';

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
  final isFileUri = uri != null && uri.scheme == 'file';

  final Widget child;
  if (isRemote) {
    child = Image.network(
      s,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  } else if (isFileUri) {
    child = Image.file(
      File(uri.toFilePath()),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  } else {
    // Treat as a local path (Windows/macOS/Linux)
    child = Image.file(
      File(s),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }

  if (borderRadius == null) return child;
  return ClipRRect(borderRadius: borderRadius, child: child);
}
