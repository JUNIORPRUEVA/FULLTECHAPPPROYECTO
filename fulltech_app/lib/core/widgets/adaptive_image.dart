import 'package:flutter/widgets.dart';

import 'adaptive_image_impl_stub.dart'
    if (dart.library.io) 'adaptive_image_impl_io.dart'
    as impl;

/// Renders an image from either a remote URL (http/https) or a local file path.
///
/// On web, local file paths are not supported; a small placeholder widget is
/// returned instead.
Widget adaptiveImage(
  String source, {
  BoxFit? fit,
  double? width,
  double? height,
  BorderRadius? borderRadius,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return impl.adaptiveImage(
    source,
    fit: fit,
    width: width,
    height: height,
    borderRadius: borderRadius,
    errorBuilder: errorBuilder,
  );
}
