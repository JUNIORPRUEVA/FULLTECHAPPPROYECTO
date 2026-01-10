class CrmInstanceSettings {
  final String instanceName;
  final String apiKey;
  final String? serverUrl;
  final String? phoneE164;
  final String? displayName;
  final bool isActive;

  const CrmInstanceSettings({
    required this.instanceName,
    required this.apiKey,
    this.serverUrl,
    this.phoneE164,
    this.displayName,
    this.isActive = true,
  });

  factory CrmInstanceSettings.fromJson(Map<String, dynamic> json) {
    String? pickStr(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v == null) continue;
        final s = v.toString();
        return s;
      }
      return null;
    }

    bool pickBool(List<String> keys, {required bool fallback}) {
      for (final k in keys) {
        final v = json[k];
        if (v is bool) return v;
        if (v is num) return v != 0;
        if (v is String) {
          final s = v.trim().toLowerCase();
          if (s == 'true' || s == '1' || s == 'yes') return true;
          if (s == 'false' || s == '0' || s == 'no') return false;
        }
      }
      return fallback;
    }

    return CrmInstanceSettings(
      instanceName:
          (pickStr(['instance_name', 'instanceName']) ?? '').trim(),
      apiKey: (pickStr(['api_key', 'apiKey']) ?? '').trim(),
      serverUrl: pickStr(['server_url', 'serverUrl'])?.trim(),
      phoneE164: pickStr(['phone_e164', 'phoneE164', 'phone'])?.trim(),
      displayName: pickStr(['display_name', 'displayName', 'label'])?.trim(),
      isActive: pickBool(['is_active', 'isActive'], fallback: true),
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'instance_name': instanceName.trim(),
      'api_key': apiKey.trim(),
      'server_url': (serverUrl ?? '').trim().isEmpty ? null : serverUrl!.trim(),
      'phone_e164': (phoneE164 ?? '').trim().isEmpty ? null : phoneE164!.trim(),
      'display_name':
          (displayName ?? '').trim().isEmpty ? null : displayName!.trim(),
      'is_active': isActive,
    };
  }
}

