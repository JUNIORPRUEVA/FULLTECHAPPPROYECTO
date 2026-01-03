import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/registered_user.dart';

class UsersApi {
  final Dio _dio;

  UsersApi(this._dio);

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
    String? posicion,
    required String telefono,
    required String direccion,
    required DateTime fechaNacimiento,
    required String cedulaNumero,
    required DateTime fechaIngresoEmpresa,
    required num salarioMensual,
    String? fotoPerfilUrl,
    String? cedulaFotoUrl,
    String? cartaUltimoTrabajoUrl,
  }) async {
    final res = await _dio.post('/users', data: {
      'nombre_completo': nombreCompleto,
      'email': email,
      'password': password,
      'rol': rol,
      if (posicion != null && posicion.trim().isNotEmpty) 'posicion': posicion.trim(),
      'telefono': telefono,
      'direccion': direccion,
      'fecha_nacimiento': _dateOnly(fechaNacimiento),
      'cedula_numero': cedulaNumero,
      'fecha_ingreso_empresa': _dateOnly(fechaIngresoEmpresa),
      'salario_mensual': salarioMensual,
      if (fotoPerfilUrl != null) 'foto_perfil_url': fotoPerfilUrl,
      if (cedulaFotoUrl != null) 'cedula_foto_url': cedulaFotoUrl,
      if (cartaUltimoTrabajoUrl != null) 'carta_ultimo_trabajo_url': cartaUltimoTrabajoUrl,
    });
    final data = res.data as Map<String, dynamic>;
    return RegisteredUser.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<RegisteredUser> updateUser(String id, Map<String, dynamic> patch) async {
    final res = await _dio.put('/users/$id', data: patch);
    final data = res.data as Map<String, dynamic>;
    return RegisteredUser.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete('/users/$id');
  }

  Future<RegisteredUser> blockUser(String id) async {
    final res = await _dio.patch('/users/$id/block');
    final data = res.data as Map<String, dynamic>;
    return RegisteredUser.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<RegisteredUser> unblockUser(String id) async {
    final res = await _dio.patch('/users/$id/unblock');
    final data = res.data as Map<String, dynamic>;
    return RegisteredUser.fromJson(data['item'] as Map<String, dynamic>);
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
    if (cedulaFotoPath != null) {
      form.files.add(MapEntry('cedula_foto', await MultipartFile.fromFile(cedulaFotoPath)));
    }
    if (cartaUltimoTrabajoPath != null) {
      form.files.add(MapEntry('carta_ultimo_trabajo', await MultipartFile.fromFile(cartaUltimoTrabajoPath)));
    }

    final res = await _dio.post('/uploads/users', data: form);
    return UserDocsUploadResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<String> downloadUserPdfToTempFile({
    required String id,
    required String kind,
  }) async {
    final res = await _dio.get<List<int>>(
      '/users/$id/$kind',
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = res.data;
    if (bytes == null) throw Exception('No PDF bytes returned');

    final dir = await getTemporaryDirectory();
    final folder = Directory(p.join(dir.path, 'fulltech_cache', 'pdfs'));
    if (!await folder.exists()) await folder.create(recursive: true);

    final file = File(p.join(folder.path, 'user_${id}_$kind.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
