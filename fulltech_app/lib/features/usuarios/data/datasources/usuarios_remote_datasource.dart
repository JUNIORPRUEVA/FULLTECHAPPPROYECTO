import 'package:dio/dio.dart';
import '../../models/usuario_model.dart';
import '../../../../core/services/app_config.dart';

class UsuariosRemoteDataSource {
  final Dio _dio;
  static String get baseUrl => AppConfig.apiBaseUrl;

  UsuariosRemoteDataSource(this._dio);

  /// Obtener lista paginada de usuarios
  Future<Map<String, dynamic>> listUsuarios({
    int page = 1,
    int limit = 20,
    String? rol,
    String? estado,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/usuarios',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (rol != null) 'rol': rol,
          if (estado != null) 'estado': estado,
          if (search != null) 'search': search,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener usuario por ID
  Future<UsuarioModel> getUsuario(String id) async {
    try {
      final response = await _dio.get('$baseUrl/usuarios/$id');
      return UsuarioModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Crear nuevo usuario
  Future<UsuarioModel> createUsuario(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('$baseUrl/usuarios', data: data);
      return UsuarioModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar usuario
  Future<UsuarioModel> updateUsuario(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('$baseUrl/usuarios/$id', data: data);
      return UsuarioModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Bloquear/desbloquear usuario
  Future<Map<String, dynamic>> blockUsuario(String id, bool bloqueado) async {
    try {
      final response = await _dio.patch(
        '$baseUrl/usuarios/$id/block',
        data: {'bloqueado': bloqueado},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar usuario (soft delete)
  Future<void> deleteUsuario(String id) async {
    try {
      await _dio.delete('$baseUrl/usuarios/$id');
    } catch (e) {
      rethrow;
    }
  }

  /// Subir documentos del usuario
  Future<Map<String, dynamic>> uploadUserDocuments({
    String? fotoPerfil,
    String? cedulaFoto,
    String? cartaUltimoTrabajo,
  }) async {
    try {
      final formData = FormData();

      if (fotoPerfil != null) {
        formData.files.add(
          MapEntry('foto_perfil', await MultipartFile.fromFile(fotoPerfil)),
        );
      }

      if (cedulaFoto != null) {
        formData.files.add(
          MapEntry('cedula_foto', await MultipartFile.fromFile(cedulaFoto)),
        );
      }

      if (cartaUltimoTrabajo != null) {
        formData.files.add(
          MapEntry(
            'carta_ultimo_trabajo',
            await MultipartFile.fromFile(cartaUltimoTrabajo),
          ),
        );
      }

      final response = await _dio.post(
        '$baseUrl/uploads/users',
        data: formData,
      );
      return response.data['urls'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Extraer datos de cédula usando IA
  Future<Map<String, dynamic>> extractCedulaData(String imagenUrl) async {
    try {
      final response = await _dio.post(
        '$baseUrl/usuarios/ia/cedula',
        data: {'imagenUrl': imagenUrl},
      );
      return response.data['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Descargar PDF de ficha de empleado
  Future<List<int>> downloadProfilePDF(String usuarioId) async {
    try {
      final response = await _dio.get<List<int>>(
        '$baseUrl/usuarios/$usuarioId/profile-pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }

  /// Descargar PDF de contrato
  Future<List<int>> downloadContractPDF(String usuarioId) async {
    try {
      final response = await _dio.get<List<int>>(
        '$baseUrl/usuarios/$usuarioId/contract-pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }
}
