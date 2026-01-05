class AiSettingsPublic {
  final bool enabled;
  final bool quickRepliesEnabled;
  final String tone;
  final int promptVersion;

  const AiSettingsPublic({
    required this.enabled,
    required this.quickRepliesEnabled,
    required this.tone,
    required this.promptVersion,
  });

  factory AiSettingsPublic.fromJson(Map<String, dynamic> json) {
    return AiSettingsPublic(
      enabled: (json['enabled'] ?? true) as bool,
      quickRepliesEnabled: (json['quickRepliesEnabled'] ?? true) as bool,
      tone: (json['tone'] ?? 'Ejecutivo') as String,
      promptVersion: (json['promptVersion'] as num? ?? 1).toInt(),
    );
  }
}

class AiSettings extends AiSettingsPublic {
  final String? systemPrompt;
  final String? rules;
  final Map<String, dynamic> businessData;

  const AiSettings({
    required super.enabled,
    required super.quickRepliesEnabled,
    required super.tone,
    required super.promptVersion,
    required this.systemPrompt,
    required this.rules,
    required this.businessData,
  });

  factory AiSettings.fromJson(Map<String, dynamic> json) {
    return AiSettings(
      enabled: (json['enabled'] ?? true) as bool,
      quickRepliesEnabled: (json['quickRepliesEnabled'] ?? true) as bool,
      tone: (json['tone'] ?? 'Ejecutivo') as String,
      promptVersion: (json['promptVersion'] as num? ?? 1).toInt(),
      systemPrompt: json['systemPrompt'] as String?,
      rules: json['rules'] as String?,
      businessData: (json['businessData'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }
}
