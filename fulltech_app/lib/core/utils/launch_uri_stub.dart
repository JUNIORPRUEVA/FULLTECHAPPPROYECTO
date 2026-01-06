Uri? toLaunchUri(String value) {
  final v = value.trim();
  if (v.isEmpty) return null;

  final uri = Uri.tryParse(v);
  if (uri == null) return null;

  if (uri.scheme == 'http' || uri.scheme == 'https') return uri;
  return null;
}
