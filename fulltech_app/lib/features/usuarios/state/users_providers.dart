import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../../../core/services/offline_http_queue.dart';
import '../../../core/storage/local_db.dart';
import '../data/datasources/users_remote_datasource.dart';
import '../data/repositories/users_repository.dart';
import '../models/registered_user.dart';
import 'users_controller.dart';
import 'users_state.dart';

final usersRemoteDataSourceProvider = Provider<UsersRemoteDataSource>((ref) {
  return UsersRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(
    ref.watch(usersRemoteDataSourceProvider),
    db: ref.watch(localDbProvider),
  );
});

final usersControllerProvider = StateNotifierProvider<UsersController, UsersState>((ref) {
  return UsersController(repo: ref.watch(usersRepositoryProvider));
});

final isAdminProvider = Provider<bool>((ref) {
  final auth = ref.watch(authControllerProvider);
  final role = (auth is AuthAuthenticated) ? auth.user.role : null;
  return role == 'admin' || role == 'administrador';
});

/// Compatibility layer for legacy `screens/*` that still expect an API-like
/// surface returning `RegisteredUser`.
///
/// New code should prefer `usersRepositoryProvider`.
final usersApiProvider = Provider<UsersApiCompat>((ref) {
  return UsersApiCompat(ref.watch(apiClientProvider).dio, ref.watch(localDbProvider));
});

class UsersApiCompat {
  final Dio _dio;
  final LocalDb _db;

  static const _uuid = Uuid();

  static final Options _noOfflineQueue = Options(
    extra: const {'offlineQueue': false},
  );

  UsersApiCompat(this._dio, this._db);

  bool _isNetworkError(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
    }
    return OfflineHttpQueue.isNetworkError(e);
  }

  static String _dateOnly(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<UsersPage> listUsers({
    int page = 1,
    int pageSize = 20,
    String? q,
    String? rol,
    String? estado,
  }) async {
    final res = await _dio.get(
      '/users',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (rol != null && rol.trim().isNotEmpty) 'rol': rol.trim(),
        if (estado != null && estado.trim().isNotEmpty) 'estado': estado.trim(),
      },
    );

    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(RegisteredUserSummary.fromJson)
        .toList();

    return UsersPage(
      page: (data['page'] as num).toInt(),
      pageSize: (data['page_size'] as num).toInt(),
      total: (data['total'] as num).toInt(),
      items: items,
    );
  }

  Future<RegisteredUser> getUser(String id) async {
    final res = await _dio.get('/users/$id');
    final data = res.data as Map<String, dynamic>;
    return RegisteredUser.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<RegisteredUser> createUser({
    required String nombreCompleto,
    required String email,
    required String password,
    required String rol,
    required String telefono,
    required String direccion,
    required DateTime fechaNacimiento,
    required String cedulaNumero,
    required DateTime fechaIngresoEmpresa,
    required num salarioMensual,
  }) async {
    final payload = <String, dynamic>{
      'nombre_completo': nombreCompleto,
      'email': email,
      'password': password,
      'rol': rol,
      'telefono': telefono,
      'direccion': direccion,
      'fecha_nacimiento': _dateOnly(fechaNacimiento),
      'cedula_numero': cedulaNumero,
      'fecha_ingreso_empresa': _dateOnly(fechaIngresoEmpresa),
      'salario_mensual': salarioMensual,
    };

    try {
      final res = await _dio.post('/users', data: payload, options: _noOfflineQueue);
      final data = res.data as Map<String, dynamic>;
      return RegisteredUser.fromJson(data['item'] as Map<String, dynamic>);
    } catch (e) {
      if (_isNetworkError(e)) {
        final localId = _uuid.v4();
        await OfflineHttpQueue.enqueue(
          _db,
          method: 'POST',
          path: '/users',
          data: payload,
          requestId: localId,
        );

        // Return a minimal placeholder so callers can continue the flow.
        return RegisteredUser(
          id: localId,
          empresaId: '',
          email: email,
          nombreCompleto: nombreCompleto,
          rol: rol,
          telefono: telefono,
          direccion: direccion,
          fechaNacimiento: fechaNacimiento,
          cedulaNumero: cedulaNumero,
          fechaIngresoEmpresa: fechaIngresoEmpresa,
          salarioMensual: salarioMensual,
          estado: 'pendiente',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  Future<RegisteredUser> updateUser(String id, Map<String, dynamic> patch) async {
    final normalized = Map<String, dynamic>.from(patch);
    void convertDate(String key) {
      final v = normalized[key];
      if (v is DateTime) normalized[key] = _dateOnly(v);
    }

    convertDate('fecha_nacimiento');
    convertDate('fecha_ingreso_empresa');
    convertDate('licencia_conducir_fecha_vencimiento');

    try {
      final res = await _dio.put(
        '/users/$id',
        data: normalized,
        options: _noOfflineQueue,
      );
      final data = res.data as Map<String, dynamic>;
      return RegisteredUser.fromJson(data['item'] as Map<String, dynamic>);
    } catch (e) {
      if (_isNetworkError(e)) {
        await OfflineHttpQueue.enqueue(
          _db,
          method: 'PUT',
          path: '/users/$id',
          data: normalized,
        );

        return RegisteredUser(
          id: id,
          empresaId: '',
          email: (normalized['email'] ?? '') as String,
          nombreCompleto: (normalized['nombre_completo'] ?? normalized['nombreCompleto'] ?? '') as String,
          rol: (normalized['rol'] ?? normalized['role'] ?? 'usuario') as String,
          telefono: (normalized['telefono'] ?? '') as String,
          direccion: (normalized['direccion'] ?? '') as String,
          estado: 'pendiente',
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete('/users/$id', options: _noOfflineQueue);
    } catch (e) {
      if (_isNetworkError(e)) {
        await OfflineHttpQueue.enqueue(
          _db,
          method: 'DELETE',
          path: '/users/$id',
        );
        return;
      }
      rethrow;
    }
  }

  Future<RegisteredUser> blockUser(String id) async {
    try {
      final res = await _dio.patch('/users/$id/block', options: _noOfflineQueue);
      final data = res.data as Map<String, dynamic>;
      return RegisteredUser.fromJson(data['item'] as Map<String, dynamic>);
    } catch (e) {
      if (_isNetworkError(e)) {
        await OfflineHttpQueue.enqueue(
          _db,
          method: 'PATCH',
          path: '/users/$id/block',
        );
        return RegisteredUser(
          id: id,
          empresaId: '',
          email: '',
          nombreCompleto: '',
          rol: 'usuario',
          telefono: '',
          direccion: '',
          estado: 'bloqueado',
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  Future<RegisteredUser> unblockUser(String id) async {
    try {
      final res = await _dio.patch('/users/$id/unblock', options: _noOfflineQueue);
      final data = res.data as Map<String, dynamic>;
      return RegisteredUser.fromJson(data['item'] as Map<String, dynamic>);
    } catch (e) {
      if (_isNetworkError(e)) {
        await OfflineHttpQueue.enqueue(
          _db,
          method: 'PATCH',
          path: '/users/$id/unblock',
        );
        return RegisteredUser(
          id: id,
          empresaId: '',
          email: '',
          nombreCompleto: '',
          rol: 'usuario',
          telefono: '',
          direccion: '',
          estado: 'activo',
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  Future<UserDocsUploadResult> uploadUserDocs({
    String? fotoPerfilPath,
    String? cedulaFotoPath,
    String? cartaUltimoTrabajoPath,
  }) async {
    final form = FormData();

    if (fotoPerfilPath != null) {
      form.files.add(MapEntry('foto_perfil', await MultipartFile.fromFile(fotoPerfilPath)));
    }

    // Legacy single "cedula_foto" maps to the new "cedula_frontal".
    if (cedulaFotoPath != null) {
      form.files.add(MapEntry('cedula_frontal', await MultipartFile.fromFile(cedulaFotoPath)));
    }

    // Legacy "carta_ultimo_trabajo" maps to the new "carta_trabajo".
    if (cartaUltimoTrabajoPath != null) {
      form.files.add(MapEntry('carta_trabajo', await MultipartFile.fromFile(cartaUltimoTrabajoPath)));
    }

    final res = await _dio.post('/uploads/users', data: form);
    final data = res.data as Map<String, dynamic>;

    String? pickString(List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v is String && v.trim().isNotEmpty) return v;
      }
      return null;
    }

    return UserDocsUploadResult(
      fotoPerfilUrl: pickString(['foto_perfil_url', 'fotoPerfilUrl']),
      cedulaFotoUrl: pickString(['cedula_frontal_url', 'cedulaFrontalUrl', 'cedula_foto_url', 'cedulaFotoUrl']),
      cartaUltimoTrabajoUrl: pickString(['carta_trabajo_url', 'cartaTrabajoUrl', 'carta_ultimo_trabajo_url', 'cartaUltimoTrabajoUrl']),
    );
  }

  Future<String> downloadUserPdfToTempFile({required String id, required String kind}) async {
    final res = await _dio.get<List<int>>(
      '/users/$id/$kind',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = res.data ?? const <int>[];
    if (bytes.isEmpty) throw Exception('No PDF bytes returned');

    final dir = await getTemporaryDirectory();
    final folder = Directory(p.join(dir.path, 'fulltech_cache', 'pdfs'));
    if (!await folder.exists()) await folder.create(recursive: true);

    final file = File(p.join(folder.path, 'user_${id}_$kind.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
