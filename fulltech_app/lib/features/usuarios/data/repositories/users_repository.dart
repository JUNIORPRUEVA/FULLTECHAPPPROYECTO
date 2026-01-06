import 'package:dio/dio.dart';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../datasources/users_remote_datasource.dart';
import '../models/user_model.dart';
import '../../../../core/storage/local_db.dart';
import '../../../../core/services/offline_http_queue.dart';

class UsersRepository {
  final UsersRemoteDataSource _remote;
  final LocalDb? _db;

  static const _uuid = Uuid();

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty) return null;
      return DateTime.tryParse(t);
    }
    return null;
  }

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

  UserModel _placeholderUser({required String id, required Map<String, dynamic> payload}) {
    return UserModel(
      id: id,
      empresaId: (payload['empresa_id'] ?? payload['empresaId'] ?? '') as String,
      email: (payload['email'] ?? '') as String,
      nombre: (payload['nombre_completo'] ?? payload['nombre'] ?? '') as String,
      rol: (payload['rol'] ?? payload['role'] ?? 'usuario') as String,
      estado: (payload['estado'] ?? 'pendiente') as String,
      esCasado: false,
      cantidadHijos: 0,
      tieneCasa: false,
      tieneVehiculo: false,
      otrosDocumentos: const [],
      telefono: payload['telefono']?.toString(),
      direccion: payload['direccion']?.toString(),
      fechaIngreso: _parseDate(payload['fecha_ingreso_empresa'] ?? payload['fecha_ingreso']),
      salarioMensual: payload['salario_mensual'] as num?,
    );
  }

  Future<UserModel> createUser(Map<String, dynamic> payload) async {
    try {
      return await _remote.createUser(payload);
    } catch (e) {
      final db = _db;
      if (db != null && _isNetworkError(e)) {
        final localId = _uuid.v4();
        await OfflineHttpQueue.enqueue(
          db,
          method: 'POST',
          path: '/users',
          data: payload,
          requestId: localId,
        );

        final json = jsonEncode({
          'id': localId,
          'email': payload['email'],
          'nombre_completo': payload['nombre_completo'] ?? payload['nombre'],
          'rol': payload['rol'] ?? payload['role'],
          'estado': 'pendiente',
          'telefono': payload['telefono'],
          'fecha_ingreso_empresa': payload['fecha_ingreso_empresa']?.toString(),
          'foto_perfil_url': payload['foto_perfil_url'],
        });
        await db.upsertEntity(store: _cacheStore, id: localId, json: json);

        return _placeholderUser(id: localId, payload: payload);
      }
      rethrow;
    }
  }

  Future<UserModel> updateUser(String id, Map<String, dynamic> patch) async {
    try {
      return await _remote.updateUser(id, patch);
    } catch (e) {
      final db = _db;
      if (db != null && _isNetworkError(e)) {
        await OfflineHttpQueue.enqueue(
          db,
          method: 'PUT',
          path: '/users/$id',
          data: patch,
        );

        // Update cached summary snapshot best-effort.
        final rows = await db.listEntitiesJson(store: _cacheStore);
        for (final s in rows) {
          final map = jsonDecode(s);
          if (map is Map && map['id'] == id) {
            final next = Map<String, dynamic>.from(map);
            for (final entry in patch.entries) {
              next[entry.key] = entry.value;
            }
            await db.upsertEntity(store: _cacheStore, id: id, json: jsonEncode(next));
            break;
          }
        }

        return _placeholderUser(id: id, payload: patch);
      }
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _remote.deleteUser(id);
    } catch (e) {
      final db = _db;
      if (db != null && _isNetworkError(e)) {
        await OfflineHttpQueue.enqueue(
          db,
          method: 'DELETE',
          path: '/users/$id',
        );
        await db.deleteEntity(store: _cacheStore, id: id);
        return;
      }
      rethrow;
    }
  }

  Future<UserModel> blockUser(String id) async {
    try {
      return await _remote.blockUser(id);
    } catch (e) {
      final db = _db;
      if (db != null && _isNetworkError(e)) {
        await OfflineHttpQueue.enqueue(
          db,
          method: 'PATCH',
          path: '/users/$id/block',
        );
        return _placeholderUser(id: id, payload: const {'estado': 'bloqueado'});
      }
      rethrow;
    }
  }

  Future<UserModel> unblockUser(String id) async {
    try {
      return await _remote.unblockUser(id);
    } catch (e) {
      final db = _db;
      if (db != null && _isNetworkError(e)) {
        await OfflineHttpQueue.enqueue(
          db,
          method: 'PATCH',
          path: '/users/$id/unblock',
        );
        return _placeholderUser(id: id, payload: const {'estado': 'activo'});
      }
      rethrow;
    }
  }

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
