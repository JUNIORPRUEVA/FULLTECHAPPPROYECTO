class EvolutionConfig {
  final String instanceName;
  final String evolutionBaseUrl;
  final String? expectedPhoneNumber;
  final DateTime? lastVerified;

  EvolutionConfig({
    required this.instanceName,
    required this.evolutionBaseUrl,
    this.expectedPhoneNumber,
    this.lastVerified,
  });

  factory EvolutionConfig.fromJson(Map<String, dynamic> json) {
    return EvolutionConfig(
      instanceName: json['instanceName'] ?? '',
      evolutionBaseUrl: json['evolutionBaseUrl'] ?? '',
      expectedPhoneNumber: json['expectedPhoneNumber'],
      lastVerified: json['lastVerified'] != null
          ? DateTime.parse(json['lastVerified'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instanceName': instanceName,
      'evolutionBaseUrl': evolutionBaseUrl,
      'expectedPhoneNumber': expectedPhoneNumber,
      'lastVerified': lastVerified?.toIso8601String(),
    };
  }
}
