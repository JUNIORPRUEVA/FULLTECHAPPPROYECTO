import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_providers.dart';
import '../../cotizaciones/data/company_settings_api.dart';
import '../models/company_profile.dart';

String _publicUrl({required String baseUrl, required String path}) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final root = baseUrl.endsWith('/api') ? baseUrl.substring(0, baseUrl.length - 4) : baseUrl;
  return '$root$path';
}

final companySettingsApiProvider = Provider<CompanySettingsApi>((ref) {
  return CompanySettingsApi(ref.watch(apiClientProvider).dio);
});

final companyProfileProvider = FutureProvider<CompanyProfile>((ref) async {
  final api = ref.watch(companySettingsApiProvider);
  final data = await api.getCompanySettings();
  final item = (data['item'] is Map)
      ? (data['item'] as Map).cast<String, dynamic>()
      : <String, dynamic>{};

  final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;
  final raw = CompanyProfile.fromJson(item);

  final logoUrl = (raw.logoUrl != null && raw.logoUrl!.trim().isNotEmpty)
      ? _publicUrl(baseUrl: baseUrl, path: raw.logoUrl!.trim())
      : null;

  return CompanyProfile(
    nombreEmpresa: raw.nombreEmpresa,
    direccion: raw.direccion,
    telefono: raw.telefono,
    email: raw.email,
    rnc: raw.rnc,
    logoUrl: logoUrl,
    validityDays: raw.validityDays <= 0 ? 7 : raw.validityDays,
  );
});
