class AppUser {
  final String id;
  final String empresaId;
  final String email;
  final String name;
  final String role;

  const AppUser({
    required this.id,
    required this.empresaId,
    required this.email,
    required this.name,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      empresaId: (json['empresa_id'] ?? json['empresaId']) as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'email': email,
      'name': name,
      'role': role,
    };
  }
}
