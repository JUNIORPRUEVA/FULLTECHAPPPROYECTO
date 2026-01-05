class CompanyProfile {
  final String nombreEmpresa;
  final String direccion;
  final String telefono;
  final String? email;
  final String? rnc;
  final String? logoUrl;
  final int validityDays;

  const CompanyProfile({
    required this.nombreEmpresa,
    required this.direccion,
    required this.telefono,
    required this.email,
    required this.rnc,
    required this.logoUrl,
    required this.validityDays,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString().trim();

    int intOr(int fallback, dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      final parsed = int.tryParse((v ?? '').toString().trim());
      return parsed ?? fallback;
    }

    return CompanyProfile(
      nombreEmpresa: s(json['nombre_empresa']),
      direccion: s(json['direccion']),
      telefono: s(json['telefono']),
      email: s(json['email']).isEmpty ? null : s(json['email']),
      rnc: s(json['rnc']).isEmpty ? null : s(json['rnc']),
      logoUrl: s(json['logo_url']).isEmpty ? null : s(json['logo_url']),
      validityDays: intOr(7, json['validez_dias']),
    );
  }
}
