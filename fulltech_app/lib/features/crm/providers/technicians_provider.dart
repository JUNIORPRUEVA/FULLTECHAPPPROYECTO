import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/core/providers/dio_provider.dart';
import 'package:dio/dio.dart';

/// Technician model for dropdowns
class TechnicianItem {
  final String id;
  final String nombreCompleto;
  final String? telefono;
  final String rol;

  TechnicianItem({
    required this.id,
    required this.nombreCompleto,
    this.telefono,
    required this.rol,
  });

  factory TechnicianItem.fromJson(Map<String, dynamic> json) {
    return TechnicianItem(
      id: json['id'] as String,
      nombreCompleto: json['nombre_completo'] as String,
      telefono: json['telefono'] as String?,
      rol: json['rol'] as String,
    );
  }

  String get displayName {
    if (telefono != null && telefono!.isNotEmpty) {
      return '$nombreCompleto ($telefono)';
    }
    return nombreCompleto;
  }
}

/// Repository to fetch technicians from users API
class TechniciansRepository {
  final Dio _dio;

  TechniciansRepository(this._dio);

  Future<List<TechnicianItem>> getTechnicians() async {
    try {
      // Fetch users with technician roles
      final response = await _dio.get(
        '/users',
        queryParameters: {
          'page': 1,
          'page_size': 100,
          'estado': 'activo',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;

      // Filter for technician roles
      final technicians = items
          .map((json) => TechnicianItem.fromJson(json as Map<String, dynamic>))
          .where((tech) {
        final role = tech.rol.toLowerCase();
        return role == 'tecnico_fijo' ||
            role == 'contratista' ||
            role == 'tecnico';
      }).toList();

      // Sort by name
      technicians.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

      return technicians;
    } catch (e) {
      print('[Technicians] Error loading technicians: $e');
      rethrow;
    }
  }
}

/// Provider for technicians repository
final techniciansRepositoryProvider = Provider<TechniciansRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TechniciansRepository(dio);
});

/// Provider for loading technicians (cached)
final techniciansProvider = FutureProvider<List<TechnicianItem>>((ref) async {
  final repo = ref.watch(techniciansRepositoryProvider);
  return repo.getTechnicians();
});
