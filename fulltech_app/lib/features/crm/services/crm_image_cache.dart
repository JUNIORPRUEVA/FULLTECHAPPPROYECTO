import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/app_config.dart';

/// CRM-only image cache.
///
/// Rules:
/// - Never uploads CRM images to the system's persistent/cloud image storage.
/// - Stores CRM images only on-device in a cache directory.
/// - Max lifetime: 7 days (TTL). Old files are cleaned up automatically.
class CrmImageCache {
  CrmImageCache._();

  static final CrmImageCache instance = CrmImageCache._();

  static const Duration maxAge = Duration(days: 7);
  static const Duration _periodicCleanupEvery = Duration(hours: 6);

  Timer? _timer;

  /// Call once (best-effort). Safe to call multiple times.
  void startMaintenance() {
    _timer ??= Timer.periodic(_periodicCleanupEvery, (_) {
      unawaited(cleanupExpired());
    });
  }

  Future<Directory> _rootDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'fulltech_crm_cache', 'images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _fnv1a64Hex(String input) {
    // Deterministic, dependency-free hash for stable filenames.
    const int fnvOffset = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    var hash = fnvOffset;
    final bytes = utf8.encode(input);
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  String _extFromUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      final path = uri?.path ?? url;
      final ext = p.extension(path).toLowerCase();
      if (ext == '.jpg' ||
          ext == '.jpeg' ||
          ext == '.png' ||
          ext == '.webp' ||
          ext == '.gif') {
        return ext;
      }
    } catch (_) {}
    return '.jpg';
  }

  bool _looksEncrypted(String url) {
    try {
      final uri = Uri.tryParse(url);
      final path = (uri?.path ?? url).toLowerCase();
      return path.endsWith('.enc');
    } catch (_) {
      return url.toLowerCase().trim().endsWith('.enc');
    }
  }

  String _resolvePublicUrl(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return v;

    final uri = Uri.tryParse(v);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'file')) {
      return v;
    }

    // Treat as app-relative URL (e.g. /uploads/crm/...).
    // AppConfig.*BaseUrl ends in /api; uploads are mounted outside /api.
    var base = AppConfig.crmApiBaseUrl.trim();
    if (base.endsWith('/api')) {
      base = base.substring(0, base.length - 3);
    }
    if (v.startsWith('/')) return '$base$v';
    return '$base/$v';
  }

  bool _isLocalPath(String s) {
    final v = s.trim();
    if (v.isEmpty) return false;
    final uri = Uri.tryParse(v);
    if (uri != null && uri.scheme == 'file') return true;
    // Heuristic: if it doesn't look like http(s) and contains a path separator.
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) return false;
    return v.contains('/') || v.contains('\\');
  }

  Future<String?> _copyIntoCache(File src, {String? originalName}) async {
    try {
      final root = await _rootDir();
      final ext = p.extension(originalName ?? src.path).toLowerCase();
      final safeExt = (ext.isNotEmpty && ext.length <= 8) ? ext : '.jpg';
      final key = _fnv1a64Hex(src.path);
      final dest = File(p.join(root.path, '${key}_local$safeExt'));
      if (await dest.exists()) {
        // Touch timestamp to extend TTL on access.
        await dest.setLastModified(DateTime.now());
        return dest.path;
      }
      await dest.create(recursive: true);
      await src.copy(dest.path);
      await dest.setLastModified(DateTime.now());
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  /// Resolves a CRM image source to a local cached file path.
  ///
  /// - If [source] is already a local path, it will be copied into the CRM cache
  ///   (so CRM media stays isolated in its own cache directory).
  /// - If [source] is remote, it will be downloaded and cached.
  /// - Returns null if it cannot be resolved; callers should handle gracefully.
  Future<String?> getOrFetchLocalPath(String source) async {
    final raw = source.trim();
    if (raw.isEmpty) return null;

    // Local file path or file:// URI.
    if (_isLocalPath(raw)) {
      if (kIsWeb) return null;
      try {
        final localPath = raw.startsWith('file://') ? Uri.parse(raw).toFilePath() : raw;
        final file = File(localPath);
        if (await file.exists()) {
          // Keep CRM media inside CRM cache dir.
          return await _copyIntoCache(file, originalName: p.basename(localPath));
        }
      } catch (_) {}
      return null;
    }

    final url = _resolvePublicUrl(raw);
    if (_looksEncrypted(url)) return null;

    final root = await _rootDir();
    final ext = _extFromUrl(url);
    final key = _fnv1a64Hex(url);
    final file = File(p.join(root.path, '$key$ext'));

    // Reuse if not expired.
    if (await file.exists()) {
      final stat = await file.stat();
      final age = DateTime.now().difference(stat.modified);
      if (age <= maxAge) {
        return file.path;
      }
      // Expired: delete and re-fetch.
      try {
        await file.delete();
      } catch (_) {}
    }

    // Download.
    try {
      final dio = Dio(
        BaseOptions(
          responseType: ResponseType.bytes,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 40),
          followRedirects: true,
        ),
      );

      final res = await dio.get<List<int>>(url);
      final contentType = res.headers.value('content-type')?.toLowerCase();
      if (contentType != null &&
          contentType.isNotEmpty &&
          !contentType.startsWith('image/')) {
        return null;
      }
      final bytes = res.data;
      if (bytes == null || bytes.isEmpty) return null;

      await file.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      await file.setLastModified(DateTime.now());
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Writes bytes into the CRM cache directory and returns the cached path.
  Future<String?> putBytes(Uint8List bytes, {String? fileNameHint}) async {
    if (bytes.isEmpty) return null;
    try {
      final root = await _rootDir();
      final ext = p.extension(fileNameHint ?? '').toLowerCase();
      final safeExt = (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp') ? ext : '.jpg';
      final key = _fnv1a64Hex(base64Url.encode(bytes.sublist(0, bytes.length.clamp(0, 256))));
      final file = File(p.join(root.path, '${key}_bytes$safeExt'));
      await file.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      await file.setLastModified(DateTime.now());
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Deletes cached CRM images older than 7 days.
  Future<void> cleanupExpired() async {
    if (kIsWeb) return;
    try {
      final root = await _rootDir();
      if (!await root.exists()) return;

      final now = DateTime.now();
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! File) continue;
        try {
          final stat = await entity.stat();
          if (now.difference(stat.modified) > maxAge) {
            await entity.delete();
          }
        } catch (_) {
          // Best-effort.
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CRM][CACHE] cleanupExpired error: $e');
      }
    }
  }
}
