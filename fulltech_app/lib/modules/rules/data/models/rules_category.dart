enum RulesCategory {
  vision('VISION'),
  mission('MISSION'),
  coreValues('VALUES'),
  policy('POLICY'),
  roleResponsibilities('ROLE_RESPONSIBILITIES'),
  procedure('PROCEDURE'),
  general('GENERAL');

  final String apiValue;
  const RulesCategory(this.apiValue);

  static RulesCategory fromApi(String raw) {
    return RulesCategory.values.firstWhere(
      (e) => e.apiValue == raw,
      orElse: () => RulesCategory.general,
    );
  }

  String get label {
    switch (this) {
      case RulesCategory.vision:
        return 'Visión';
      case RulesCategory.mission:
        return 'Misión';
      case RulesCategory.coreValues:
        return 'Valores';
      case RulesCategory.policy:
        return 'Política / Norma';
      case RulesCategory.roleResponsibilities:
        return 'Responsabilidades por Rol';
      case RulesCategory.procedure:
        return 'Procedimiento / Guía';
      case RulesCategory.general:
        return 'General';
    }
  }
}
