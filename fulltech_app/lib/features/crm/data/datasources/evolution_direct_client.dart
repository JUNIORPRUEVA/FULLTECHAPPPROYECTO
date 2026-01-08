import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/app_config.dart';

class EvolutionDirectSendResult {
  final String? messageId;
  final dynamic raw;

  const EvolutionDirectSendResult({required this.messageId, required this.raw});
}

class EvolutionDirectClient {
  final Dio _dio;
  final String _instance;
  final String _defaultCountryCode;

  EvolutionDirectClient._({
    required Dio dio,
    required String instance,
    required String defaultCountryCode,
  }) : _dio = dio,
       _instance = instance,
       _defaultCountryCode = defaultCountryCode;

  factory EvolutionDirectClient.create({
    String? baseUrl,
    String? apiKey,
    String? instance,
    String? defaultCountryCode,
  }) {
    final resolvedBaseUrl = (baseUrl ?? AppConfig.evolutionApiBaseUrl).trim();
    final resolvedApiKey = (apiKey ?? AppConfig.evolutionApiKey).trim();
    final resolvedInstance = (instance ?? AppConfig.evolutionInstance).trim();
    final resolvedDefaultCountry =
        (defaultCountryCode ?? AppConfig.evolutionDefaultCountryCode).trim();

    if (resolvedBaseUrl.isEmpty) throw Exception('Evolution baseUrl is empty');
    if (resolvedApiKey.isEmpty) throw Exception('Evolution apiKey is empty');

    final dio = Dio(
      BaseOptions(
        baseUrl: resolvedBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json', 'apikey': resolvedApiKey},
      ),
    );

    return EvolutionDirectClient._(
      dio: dio,
      instance: resolvedInstance,
      defaultCountryCode: resolvedDefaultCountry.isEmpty
          ? '1'
          : resolvedDefaultCountry,
    );
  }

  String _instanceValue() => _instance;

  String _instancePath(String path) {
    final inst = _instanceValue();
    if (inst.isEmpty) return path;

    if (path.contains('{instance}')) return path.replaceAll('{instance}', inst);
    if (path.endsWith('/')) return '$path$inst';
    return '$path/$inst';
  }

  Future<Response<dynamic>> _postWithInstanceFallback(
    String path,
    dynamic payload,
  ) async {
    final inst = _instanceValue();
    final candidates = inst.isNotEmpty
        ? <String>[_instancePath(path), path]
        : <String>[path];

    Object? lastErr;
    for (var i = 0; i < candidates.length; i++) {
      final url = candidates[i];
      try {
        return await _dio.post(url, data: payload);
      } catch (e) {
        lastErr = e;
        if (e is DioException) {
          final status = e.response?.statusCode;
          if (status == 404 && i < candidates.length - 1) continue;
        }
        break;
      }
    }

    throw lastErr ?? Exception('Evolution request failed');
  }

  static String _digitsOnly(String raw) => raw.replaceAll(RegExp(r'\D+'), '');

  String _applyDefaultCountryCode(String digits) {
    final d = _digitsOnly(digits);
    if (d.length == 10) {
      final cc = _digitsOnly(_defaultCountryCode);
      return '${cc.isEmpty ? '1' : cc}$d';
    }
    return d;
  }

  String _normalizeNumber({String? toWaId, String? toPhone}) {
    final wa = (toWaId ?? '').trim();
    final phone = (toPhone ?? '').trim();

    if (kDebugMode) {
      debugPrint('[EVO_CLIENT][NORMALIZE] wa=$wa phone=$phone');
    }

    // Groups: keep JID as-is (Evolution commonly accepts @g.us)
    if (wa.endsWith('@g.us')) {
      if (kDebugMode) {
        debugPrint('[EVO_CLIENT][NORMALIZE] Group chat detected: $wa');
      }
      return wa;
    }

    // If waId already has @s.whatsapp.net or @c.us, extract number and re-add
    if (wa.contains('@s.whatsapp.net') || wa.contains('@c.us')) {
      final at = wa.indexOf('@');
      final base = at >= 0 ? wa.substring(0, at) : wa;
      final normalized = _applyDefaultCountryCode(_digitsOnly(base));
      final result = '$normalized@s.whatsapp.net';
      if (kDebugMode) {
        debugPrint(
          '[EVO_CLIENT][NORMALIZE] waId has domain, extracted base=$base normalized=$normalized result=$result',
        );
      }
      return result;
    }

    // LID is not routable for sending; prefer phone if available
    if (wa.endsWith('@lid') && phone.isNotEmpty) {
      final normalized = _applyDefaultCountryCode(_digitsOnly(phone));
      final result = '$normalized@s.whatsapp.net';
      if (kDebugMode) {
        debugPrint(
          '[EVO_CLIENT][NORMALIZE] LID detected, using phone instead: $result',
        );
      }
      return result;
    }

    if (wa.isNotEmpty) {
      final at = wa.indexOf('@');
      final base = at >= 0 ? wa.substring(0, at) : wa;
      final normalized = _applyDefaultCountryCode(_digitsOnly(base));
      final result = '$normalized@s.whatsapp.net';
      if (kDebugMode) {
        debugPrint(
          '[EVO_CLIENT][NORMALIZE] Using waId, base=$base normalized=$normalized result=$result',
        );
      }
      return result;
    }

    if (phone.isEmpty) {
      if (kDebugMode) {
        debugPrint('[EVO_CLIENT][NORMALIZE] ERROR: No destination provided');
      }
      throw Exception('Missing destination (toPhone or toWaId)');
    }

    final normalized = _applyDefaultCountryCode(_digitsOnly(phone));
    final result = '$normalized@s.whatsapp.net';
    if (kDebugMode) {
      debugPrint(
        '[EVO_CLIENT][NORMALIZE] Using phone, normalized=$normalized result=$result',
      );
    }
    return result;
  }

  static String _normalizeMediaType(String? mediaType) {
    final raw = (mediaType ?? '').trim();
    if (raw.isEmpty) return 'image';

    final lower = raw.toLowerCase();
    if (lower == 'image' ||
        lower == 'video' ||
        lower == 'audio' ||
        lower == 'document') {
      return lower;
    }

    // Sometimes callers pass MIME types like "image/jpeg".
    if (lower.startsWith('image/')) return 'image';
    if (lower.startsWith('video/')) return 'video';
    if (lower.startsWith('audio/')) return 'audio';
    if (lower == 'application/pdf') return 'document';

    return 'document';
  }

  static String? _extractMessageId(dynamic raw) {
    try {
      if (raw is Map) {
        final v =
            raw['messageId'] ??
            raw['message_id'] ??
            (raw['key'] is Map ? (raw['key'] as Map)['id'] : null) ??
            (raw['data'] is Map
                ? ((raw['data'] as Map)['key'] is Map
                      ? ((raw['data'] as Map)['key'] as Map)['id']
                      : null)
                : null);
        if (v != null) return v.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<EvolutionDirectSendResult> sendText({
    required String text,
    String? toWaId,
    String? toPhone,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw Exception('Text message is empty');

    // Add detailed logging
    if (kDebugMode) {
      debugPrint('[EVO_CLIENT] ===== SEND TEXT START =====');
      debugPrint('[EVO_CLIENT] Input toWaId: $toWaId');
      debugPrint('[EVO_CLIENT] Input toPhone: $toPhone');
      debugPrint('[EVO_CLIENT] Instance: $_instance');
      debugPrint('[EVO_CLIENT] Default Country Code: $_defaultCountryCode');
    }

    final number = _normalizeNumber(toWaId: toWaId, toPhone: toPhone);

    if (kDebugMode) {
      debugPrint('[EVO_CLIENT] Normalized number for Evolution: $number');
      debugPrint('[EVO_CLIENT] Text length: ${trimmed.length}');
    }

    final payload = {'number': number, 'text': trimmed};

    if (kDebugMode) {
      debugPrint('[EVO_CLIENT] Payload: $payload');
      debugPrint('[EVO_CLIENT] Sending to Evolution API...');
    }

    final res = await _postWithInstanceFallback('/message/sendText', payload);
    final raw = res.data;

    final msgId = _extractMessageId(raw);
    if (kDebugMode) {
      debugPrint('[EVO_CLIENT] Response received - MessageId: $msgId');
      debugPrint('[EVO_CLIENT] ===== SEND TEXT END =====');
    }

    return EvolutionDirectSendResult(messageId: msgId, raw: raw);
  }

  Future<EvolutionDirectSendResult> sendMedia({
    required String mediaUrl,
    String? caption,
    String? mediaType,
    String? toWaId,
    String? toPhone,
  }) async {
    final url = mediaUrl.trim();
    if (url.isEmpty) throw Exception('Media URL is empty');

    final number = _normalizeNumber(toWaId: toWaId, toPhone: toPhone);

    final resolvedMediaType = _normalizeMediaType(mediaType);

    // Evolution deployments vary:
    // - Some expect { number, mediaMessage: { mediatype, media, caption } }
    // - Others expect { number, mediatype, media, caption }
    // We'll try the common nested form first, then fall back if the server says
    // the payload is missing `mediatype`.

    final payload = {
      'number': number,
      'mediaMessage': {
        'mediatype': resolvedMediaType,
        'media': url,
        'caption': (caption ?? '').toString(),
      },
    };

    Response<dynamic> res;
    try {
      res = await _postWithInstanceFallback('/message/sendMedia', payload);
    } catch (e) {
      // Some Evolution deployments validate the payload schema differently.
      // If we get a 400 from the nested form, try the root-level form too.
      if (e is DioException && (e.response?.statusCode ?? 0) == 400) {
        final altPayload = {
          'number': number,
          'mediatype': resolvedMediaType,
          'media': url,
          'caption': (caption ?? '').toString(),
        };

        res = await _postWithInstanceFallback('/message/sendMedia', altPayload);
      } else {
        rethrow;
      }
    }

    final raw = res.data;

    return EvolutionDirectSendResult(
      messageId: _extractMessageId(raw),
      raw: raw,
    );
  }

  Future<EvolutionDirectSendResult> sendLocation({
    required double latitude,
    required double longitude,
    String? name,
    String? address,
    String? toWaId,
    String? toPhone,
  }) async {
    final number = _normalizeNumber(toWaId: toWaId, toPhone: toPhone);

    final lat = latitude;
    final lng = longitude;
    if (lat.isNaN || lng.isNaN) throw Exception('Invalid coordinates');

    final safeName = (name ?? '').trim();
    final safeAddress = (address ?? '').trim();

    // Evolution payloads vary by version. We'll try a few common shapes.
    final candidates = <Map<String, dynamic>>[
      {
        'number': number,
        'locationMessage': {
          'degreesLatitude': lat,
          'degreesLongitude': lng,
          if (safeName.isNotEmpty) 'name': safeName,
          if (safeAddress.isNotEmpty) 'address': safeAddress,
        },
      },
      {
        'number': number,
        'location': {
          'degreesLatitude': lat,
          'degreesLongitude': lng,
          if (safeName.isNotEmpty) 'name': safeName,
          if (safeAddress.isNotEmpty) 'address': safeAddress,
        },
      },
      {
        'number': number,
        'latitude': lat,
        'longitude': lng,
        if (safeName.isNotEmpty) 'name': safeName,
        if (safeAddress.isNotEmpty) 'address': safeAddress,
      },
      {
        'number': number,
        'lat': lat,
        'lng': lng,
        if (safeName.isNotEmpty) 'name': safeName,
        if (safeAddress.isNotEmpty) 'address': safeAddress,
      },
    ];

    Object? lastErr;
    for (final payload in candidates) {
      try {
        final res = await _postWithInstanceFallback(
          '/message/sendLocation',
          payload,
        );
        final raw = res.data;
        return EvolutionDirectSendResult(
          messageId: _extractMessageId(raw),
          raw: raw,
        );
      } catch (e) {
        lastErr = e;
        if (e is DioException) {
          final status = e.response?.statusCode ?? 0;
          // Try the next candidate on schema/validation errors.
          if (status == 400 || status == 422) continue;
        }
        break;
      }
    }

    throw lastErr ?? Exception('Evolution location send failed');
  }
}
