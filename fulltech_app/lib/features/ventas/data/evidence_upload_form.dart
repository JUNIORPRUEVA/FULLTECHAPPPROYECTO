import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'evidence_upload_form_io.dart'
    if (dart.library.html) 'evidence_upload_form_web.dart' as impl;

Future<FormData> buildSalesEvidenceUploadForm({
  required String filename,
  Uint8List? bytes,
  String? filePath,
  String? mimeType,
}) {
  return impl.buildSalesEvidenceUploadForm(
    filename: filename,
    bytes: bytes,
    filePath: filePath,
    mimeType: mimeType,
  );
}

