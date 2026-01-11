import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/letter_models.dart';

class CartaResponse {
  final Letter item;
  final String pdfUrl;

  const CartaResponse({required this.item, required this.pdfUrl});

  factory CartaResponse.fromJson(Map<String, dynamic> json) {
    return CartaResponse(
      item: Letter.fromJson((json['item'] as Map).cast<String, dynamic>()),
      pdfUrl: (json['pdfUrl'] ?? '').toString(),
    );
  }
}

class CartasApi {
  final Dio _dio;

  CartasApi(this._dio);

  Future<List<Letter>> listCartas({
    String? presupuestoId,
    String? clienteId,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/cartas',
      queryParameters: {
        if (presupuestoId != null) 'presupuestoId': presupuestoId,
        if (clienteId != null) 'clienteId': clienteId,
        'limit': limit,
        'offset': offset,
      },
    );

    final items = (res.data['items'] as List)
        .map((e) => Letter.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);

    return items;
  }

  Future<CartaResponse> getCarta(String id) async {
    final res = await _dio.get('/cartas/$id');
    return CartaResponse.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<CartaResponse> generateCarta(GenerateCartaRequest request) async {
    final res = await _dio.post('/cartas/generate', data: request.toJson());
    return CartaResponse.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<void> deleteCarta(String id) async {
    await _dio.delete('/cartas/$id');
  }

  Future<Map<String, dynamic>> sendWhatsApp(
    String id, {
    String? toPhone,
  }) async {
    final res = await _dio.post(
      '/cartas/$id/send-whatsapp',
      data: {
        if (toPhone != null && toPhone.trim().isNotEmpty) 'toPhone': toPhone,
      },
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  String pdfPath(String id) => '/cartas/$id/pdf';

  Future<Uint8List> downloadPdfBytes(String id) async {
    final res = await _dio.get<List<int>>(
      pdfPath(id),
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }
}
