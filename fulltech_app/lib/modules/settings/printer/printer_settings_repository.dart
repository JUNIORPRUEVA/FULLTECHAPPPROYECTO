import 'package:dio/dio.dart';

class PrinterSettings {
  final String strategy;
  final String? printerName;
  final int paperWidthMm;
  final int copies;

  const PrinterSettings({
    required this.strategy,
    required this.printerName,
    required this.paperWidthMm,
    required this.copies,
  });

  factory PrinterSettings.fromJson(Map<String, dynamic> json) {
    return PrinterSettings(
      strategy: (json['strategy'] ?? 'PDF_FALLBACK').toString(),
      printerName: (json['printer_name'] ?? json['printerName'])?.toString(),
      paperWidthMm: (json['paper_width_mm'] ?? json['paperWidthMm'] ?? 80) as int,
      copies: (json['copies'] ?? 1) as int,
    );
  }
}

class PrinterSettingsRepository {
  final Dio dio;

  PrinterSettingsRepository(this.dio);

  Future<PrinterSettings> getSettings() async {
    final res = await dio.get(
      '/settings/printer',
      options: Options(extra: {'offlineCache': false, 'offlineQueue': false}),
    );
    final data = res.data as Map<String, dynamic>;
    final item = (data['item'] as Map).cast<String, dynamic>();
    return PrinterSettings.fromJson(item);
  }

  Future<void> saveSettings(PrinterSettings s) async {
    await dio.put(
      '/settings/printer',
      data: {
        'strategy': s.strategy,
        'printerName': s.printerName,
        'paperWidthMm': s.paperWidthMm,
        'copies': s.copies,
      },
      options: Options(extra: {'offlineCache': false, 'offlineQueue': false}),
    );
  }

  Future<void> testConnection() async {
    await dio.get(
      '/print/test',
      options: Options(extra: {'offlineCache': false, 'offlineQueue': false}),
    );
  }
}
