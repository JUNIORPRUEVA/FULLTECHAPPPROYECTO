import 'package:dio/dio.dart';

class AiLettersApi {
  final Dio _dio;

  AiLettersApi(this._dio);

  Future<Map<String, dynamic>> generateLetter({
    required Map<String, dynamic> companyProfile,
    required String letterType,
    Map<String, dynamic>? quotation,
    Map<String, dynamic>? manualCustomer,
    String? manualContext,
    String action = 'generate',
    String? subject,
    String? body,
    String? tone,
  }) async {
    final res = await _dio.post(
      '/ai/generate-letter',
      data: {
        'companyProfile': companyProfile,
        'letterType': letterType,
        if (quotation != null) 'quotation': quotation,
        if (manualCustomer != null) 'manualCustomer': manualCustomer,
        if (manualContext != null) 'manualContext': manualContext,
        'action': action,
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
        if (tone != null) 'tone': tone,
      },
    );

    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }
}
