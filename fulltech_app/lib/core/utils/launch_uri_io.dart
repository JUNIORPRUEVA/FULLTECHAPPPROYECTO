Uri? toLaunchUri(String value) {
  final v = value.trim();
  if (v.isEmpty) return null;

  final uri = Uri.tryParse(v);
  if (uri != null && uri.scheme.isNotEmpty) {
    final scheme = uri.scheme.toLowerCase();
    final looksLikeWindowsDrive =
        scheme.length == 1 && v.length >= 2 && v[1] == ':';

    // Treat "C:\..." as a local path (Uri.tryParse sees scheme "c").
    if (!looksLikeWindowsDrive) return uri;
  }

  // Local path.
  return Uri.file(v);
}
