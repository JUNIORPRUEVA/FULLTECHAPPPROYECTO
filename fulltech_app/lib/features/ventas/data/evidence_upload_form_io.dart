import 'dart:typed_data';

import 'package:dio/dio.dart';

Future<FormData> buildSalesEvidenceUploadForm({
  required String filename,
  Uint8List? bytes,
  String? filePath,
  String? mimeType,
}) async {
  final path = filePath?.trim();
  if (path != null && path.isNotEmpty) {
    final file = await MultipartFile.fromFile(path, filename: filename);
    return FormData.fromMap({'file': file});
  }

  if (bytes == null) {
    throw ArgumentError('bytes or filePath is required');
  }

  return FormData.fromMap({
    'file': MultipartFile.fromBytes(bytes, filename: filename),
  });
}

