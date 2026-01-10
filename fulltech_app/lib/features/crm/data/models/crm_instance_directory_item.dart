class CrmInstanceDirectoryItem {
  final String id;
  final String instanceName;
  final String? label;
  final String? phoneE164;
  final String? ownerUserId;
  final bool isActive;

  const CrmInstanceDirectoryItem({
    required this.id,
    required this.instanceName,
    this.label,
    this.phoneE164,
    this.ownerUserId,
    required this.isActive,
  });

  factory CrmInstanceDirectoryItem.fromJson(Map<String, dynamic> json) {
    String? pickStr(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v == null) continue;
        return v.toString();
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

    return CrmInstanceDirectoryItem(
      id: (pickStr(['id']) ?? '').toString(),
      instanceName: (pickStr(['instance_name', 'instanceName']) ?? '').trim(),
      label: pickStr(['label'])?.trim(),
      phoneE164: pickStr(['phone_e164', 'phoneE164', 'phone'])?.trim(),
      ownerUserId: pickStr(['owner_user_id', 'ownerUserId'])?.trim(),
      isActive: pickBool(['is_active', 'isActive'], fallback: true),
    );
  }
}

