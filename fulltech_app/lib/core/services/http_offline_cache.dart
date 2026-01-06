import 'dart:convert';

import 'package:dio/dio.dart';

import '../storage/local_db_interface.dart';

class HttpOfflineCache {
  static const String store = 'http_cache';

  static bool shouldCache(RequestOptions options) {
    final extra = options.extra;
    final enabled = extra['offlineCache'] != false;
    if (!enabled) return false;

    final method = options.method.toUpperCase();
    if (method != 'GET') return false;

    // Only cache JSON-like responses.
    final rt = options.responseType;
    if (rt != ResponseType.json) return false;

    return true;
  }

  static String _normalizeQuery(Map<String, dynamic> qp) {
    if (qp.isEmpty) return '';

    final entries = qp.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final parts = <String>[];
    for (final e in entries) {
      final k = e.key;
      final v = e.value;
      if (v == null) continue;
      if (v is Iterable) {
        final list = v.map((x) => x.toString()).toList()..sort();
        parts.add('$k=${list.join(',')}');
      } else {
        parts.add('$k=${v.toString()}');
      }
    }
    return parts.join('&');
  }

  static String _cacheKey(RequestOptions o) {
    final base = o.baseUrl;
    final path = o.path;
    final qp = _normalizeQuery(o.queryParameters);
    return qp.isEmpty ? '$base|$path' : '$base|$path?$qp';
  }

  // Deterministic small hash (FNV-1a 32-bit) to keep IDs short.
  static String _fnv1a32Hex(String input) {
    const int fnvOffset = 0x811C9DC5;
    const int fnvPrime = 0x01000193;

    var hash = fnvOffset;
    final bytes = utf8.encode(input);
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String cacheIdFor(RequestOptions o) => _fnv1a32Hex(_cacheKey(o));

  static Future<void> put(LocalDb db, RequestOptions o, dynamic data) async {
    if (!shouldCache(o)) return;

    // Best-effort: only cache JSON encodable payloads.
    try {
      final encoded = jsonEncode(data);
      final key = _cacheKey(o);
      final id = _fnv1a32Hex(key);

      await db.upsertEntity(
        store: store,
        id: id,
        json: jsonEncode({
          'key': key,
          'cached_at_ms': DateTime.now().millisecondsSinceEpoch,
          'data': jsonDecode(encoded),
        }),
      );
    } catch (_) {
      // Ignore cache failures.
    }
  }

  static Future<dynamic> get(LocalDb db, RequestOptions o) async {
    if (!shouldCache(o)) return null;

    final key = _cacheKey(o);
    final id = _fnv1a32Hex(key);

    final raw = await db.getEntityJson(store: store, id: id);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw);
      if (map is Map && map['key'] == key) {
        return map['data'];
      }
    } catch (_) {
      // Ignore decode errors.
    }

    return null;
  }
}
