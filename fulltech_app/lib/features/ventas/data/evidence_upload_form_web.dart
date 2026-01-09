import 'dart:typed_data';

import 'package:dio/dio.dart';

Future<FormData> buildSalesEvidenceUploadForm({
  required String filename,
  Uint8List? bytes,
  String? filePath,
  String? mimeType,
}) async {
  if (bytes == null) {
    throw ArgumentError('bytes is required on web');
  }

  return FormData.fromMap({
    'file': MultipartFile.fromBytes(bytes, filename: filename),
  });
}

