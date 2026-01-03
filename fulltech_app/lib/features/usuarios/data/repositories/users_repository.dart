import 'package:dio/dio.dart';
import 'dart:convert';

import '../datasources/users_remote_datasource.dart';
import '../models/user_model.dart';
import '../../../../core/storage/local_db.dart';

class UsersRepository {
  final UsersRemoteDataSource _remote;
  final LocalDb? _db;

  UsersRepository(this._remote, {LocalDb? db}) : _db = db;

  static const _cacheStore = 'users_cache';

  bool _isNetworkError(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return true;
      }
      final msg = e.error?.toString() ?? '';
      if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
        return true;
      }
    }
    final msg = e.toString();
    return msg.contains('SocketException') || msg.contains('Failed host lookup');
  }

  Future<UsersPage> listUsers({
    int page = 1,
    int pageSize = 20,
    String? q,
    String? rol,
    String? estado,
  }) {
    return _listUsersCached(page: page, pageSize: pageSize, q: q, rol: rol, estado: estado);
  }

  Future<UsersPage> _listUsersCached({
    required int page,
    required int pageSize,
    String? q,
    String? rol,
    String? estado,
  }) async {
    try {
      final result = await _remote.listUsers(
        page: page,
        pageSize: pageSize,
        q: q,
        rol: rol,
        estado: estado,
      );

      // Cache only the first page as an offline fallback snapshot.
      if (_db != null && page == 1) {
        for (final u in result.items) {
          final json = jsonEncode({
            'id': u.id,
            'email': u.email,
            'nombre_completo': u.nombre,
            'rol': u.rol,
            'estado': u.estado,
            'telefono': u.telefono,
            'fecha_ingreso_empresa': u.fechaIngreso?.toIso8601String(),
            'foto_perfil_url': u.fotoPerfilUrl,
          });
          await _db.upsertEntity(store: _cacheStore, id: u.id, json: json);
        }
      }

      return result;
    } catch (e) {
      if (_db != null && _isNetworkError(e)) {
        final rows = await _db.listEntitiesJson(store: _cacheStore);
        final cached = rows
            .map((s) => jsonDecode(s))
            .whereType<Map<String, dynamic>>()
            .map(UserSummary.fromJson)
            .toList();

        return UsersPage(
          page: 1,
          pageSize: cached.length,
          total: cached.length,
          items: cached,
        );
      }
      rethrow;
    }
  }

  Future<UserModel> getUser(String id) => _remote.getUser(id);

  Future<UserModel> createUser(Map<String, dynamic> payload) => _remote.createUser(payload);

  Future<UserModel> updateUser(String id, Map<String, dynamic> patch) => _remote.updateUser(id, patch);

  Future<void> deleteUser(String id) => _remote.deleteUser(id);

  Future<UserModel> blockUser(String id) => _remote.blockUser(id);

  Future<UserModel> unblockUser(String id) => _remote.unblockUser(id);

  Future<Map<String, dynamic>> uploadUserDocuments({
    MultipartFile? fotoPerfil,
    MultipartFile? cedulaFrontal,
    MultipartFile? cedulaPosterior,
    MultipartFile? licenciaConducir,
    MultipartFile? cartaTrabajo,
    MultipartFile? curriculumVitae,
    List<MultipartFile>? otrosDocumentos,
  }) {
    return _remote.uploadUserDocuments(
      fotoPerfil: fotoPerfil,
      cedulaFrontal: cedulaFrontal,
      cedulaPosterior: cedulaPosterior,
      licenciaConducir: licenciaConducir,
      cartaTrabajo: cartaTrabajo,
      curriculumVitae: curriculumVitae,
      otrosDocumentos: otrosDocumentos,
    );
  }

  Future<String> downloadUserPdfToTempFile({required String id, required String kind}) {
    return _remote.downloadUserPdfToTempFile(id: id, kind: kind);
  }

  Future<String> downloadUserPdfToDownloadsFile({required String id, required String kind, String? fileName}) {
    return _remote.downloadUserPdfToDownloadsFile(id: id, kind: kind, fileName: fileName);
  }

  Future<Map<String, dynamic>> extractFromCedula({required MultipartFile cedulaFrontal}) {
    return _remote.extractFromCedula(cedulaFrontal: cedulaFrontal);
  }

  Future<Map<String, dynamic>> extractFromLicencia({required MultipartFile licenciaFrontal}) {
    return _remote.extractFromLicencia(licenciaFrontal: licenciaFrontal);
  }
}
