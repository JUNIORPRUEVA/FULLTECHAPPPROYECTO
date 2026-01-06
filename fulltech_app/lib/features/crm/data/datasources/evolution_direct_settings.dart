import 'package:shared_preferences/shared_preferences.dart';

class EvolutionDirectSettingsData {
  final bool enabled;
  final String baseUrl;
  final String apiKey;
  final String instance;
  final String defaultCountryCode;

  const EvolutionDirectSettingsData({
    required this.enabled,
    required this.baseUrl,
    required this.apiKey,
    required this.instance,
    required this.defaultCountryCode,
  });

  EvolutionDirectSettingsData copyWith({
    bool? enabled,
    String? baseUrl,
    String? apiKey,
    String? instance,
    String? defaultCountryCode,
  }) {
    return EvolutionDirectSettingsData(
      enabled: enabled ?? this.enabled,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      instance: instance ?? this.instance,
      defaultCountryCode: defaultCountryCode ?? this.defaultCountryCode,
    );
  }
}

class EvolutionDirectSettings {
  EvolutionDirectSettings._();

  static const _kEnabled = 'crm.directEvolution.enabled';
  static const _kBaseUrl = 'crm.directEvolution.baseUrl';
  static const _kApiKey = 'crm.directEvolution.apiKey';
  static const _kInstance = 'crm.directEvolution.instance';
  static const _kDefaultCountryCode = 'crm.directEvolution.defaultCountryCode';

  static Future<EvolutionDirectSettingsData> load() async {
    final prefs = await SharedPreferences.getInstance();
    return EvolutionDirectSettingsData(
      enabled: prefs.getBool(_kEnabled) ?? false,
      baseUrl: (prefs.getString(_kBaseUrl) ?? '').trim(),
      apiKey: (prefs.getString(_kApiKey) ?? '').trim(),
      instance: (prefs.getString(_kInstance) ?? '').trim(),
      defaultCountryCode:
          (prefs.getString(_kDefaultCountryCode) ?? '1').trim(),
    );
  }

  static Future<void> save(EvolutionDirectSettingsData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, data.enabled);
    await prefs.setString(_kBaseUrl, data.baseUrl.trim());
    await prefs.setString(_kApiKey, data.apiKey.trim());
    await prefs.setString(_kInstance, data.instance.trim());
    await prefs.setString(
      _kDefaultCountryCode,
      data.defaultCountryCode.trim().isEmpty ? '1' : data.defaultCountryCode.trim(),
    );
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, enabled);
  }
}
