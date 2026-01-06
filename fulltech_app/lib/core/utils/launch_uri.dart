import 'launch_uri_stub.dart' if (dart.library.io) 'launch_uri_io.dart' as impl;

/// Builds a [Uri] suitable for `url_launcher` from either a remote URL
/// (http/https) or a local file path.
///
/// On web, local paths are not supported and will return null.
Uri? toLaunchUri(String value) => impl.toLaunchUri(value);
