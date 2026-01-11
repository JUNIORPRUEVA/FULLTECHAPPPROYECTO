import 'package:dio/dio.dart';
import 'package:fulltech_app/features/cartas/models/letter_models.dart';

class LettersApi {
  final Dio _dio;

  LettersApi(this._dio);

  Future<List<Letter>> listLetters({
    String? status,
    String? letterType,
    String? q,
    String? from,
    String? to,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/letters',
      queryParameters: {
        if (status != null) 'status': status,
        if (letterType != null) 'letterType': letterType,
        if (q != null && q.isNotEmpty) 'q': q,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        'limit': limit,
        'offset': offset,
      },
    );

    final items = (response.data['items'] as List)
        .map((json) => Letter.fromJson(json as Map<String, dynamic>))
        .toList();

    return items;
  }

  Future<Letter> getLetter(String id) async {
    final response = await _dio.get('/letters/$id');
    return Letter.fromJson(response.data['item'] as Map<String, dynamic>);
  }

  Future<GenerateLetterResponse> generateWithAI(
    GenerateLetterRequest request,
  ) async {
    final response = await _dio.post(
      '/letters/generate-ai',
      data: request.toJson(),
    );

    return GenerateLetterResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<Letter> createLetter(CreateLetterRequest request) async {
    final response = await _dio.post('/letters', data: request.toJson());

    return Letter.fromJson(response.data['item'] as Map<String, dynamic>);
  }

  Future<Letter> updateLetter(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/letters/$id', data: data);
    return Letter.fromJson(response.data['item'] as Map<String, dynamic>);
  }

  Future<void> deleteLetter(String id) async {
    await _dio.delete('/letters/$id');
  }

  Future<Map<String, dynamic>> sendWhatsApp(
    String letterId,
    String chatId,
  ) async {
    final response = await _dio.post(
      '/letters/$letterId/send-whatsapp',
      data: {'chatId': chatId},
    );
    return response.data as Map<String, dynamic>;
  }

  String getPdfUrl(String letterId) {
    return '/letters/$letterId/pdf';
  }
}
