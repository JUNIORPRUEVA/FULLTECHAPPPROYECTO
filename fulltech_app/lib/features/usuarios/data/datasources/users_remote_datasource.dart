import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/user_model.dart';

class UsersRemoteDataSource {
  final Dio _dio;

  static final Options _noOfflineQueue = Options(
    extra: const {'offlineQueue': false},
  );

  UsersRemoteDataSource(this._dio);

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
        .map(UserSummary.fromJson)
        .toList();

    return UsersPage(
      page: (data['page'] as num).toInt(),
      pageSize: (data['page_size'] as num).toInt(),
      total: (data['total'] as num).toInt(),
      items: items,
    );
  }

  Future<UserModel> getUser(String id) async {
    final res = await _dio.get('/users/$id');
    final data = res.data as Map<String, dynamic>;
    return UserModel.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<UserModel> createUser(Map<String, dynamic> payload) async {
    final normalized = Map<String, dynamic>.from(payload);

    // Normalize dates to YYYY-MM-DD when provided as DateTime.
    void convertDate(String key) {
      final v = normalized[key];
      if (v is DateTime) normalized[key] = _dateOnly(v);
    }

    convertDate('fecha_nacimiento');
    convertDate('fecha_ingreso_empresa');
    convertDate('licencia_conducir_fecha_vencimiento');

    final res = await _dio.post('/users', data: normalized, options: _noOfflineQueue);
    final data = res.data as Map<String, dynamic>;
    return UserModel.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<UserModel> updateUser(String id, Map<String, dynamic> patch) async {
    final normalized = Map<String, dynamic>.from(patch);

    void convertDate(String key) {
      final v = normalized[key];
      if (v is DateTime) normalized[key] = _dateOnly(v);
    }

    convertDate('fecha_nacimiento');
    convertDate('fecha_ingreso_empresa');
    convertDate('licencia_conducir_fecha_vencimiento');

    final res = await _dio.put(
      '/users/$id',
      data: normalized,
      options: _noOfflineQueue,
    );
    final data = res.data as Map<String, dynamic>;
    return UserModel.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete('/users/$id', options: _noOfflineQueue);
  }

  Future<UserModel> blockUser(String id) async {
    final res = await _dio.patch('/users/$id/block', options: _noOfflineQueue);
    final data = res.data as Map<String, dynamic>;
    return UserModel.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<UserModel> unblockUser(String id) async {
    final res = await _dio.patch('/users/$id/unblock', options: _noOfflineQueue);
    final data = res.data as Map<String, dynamic>;
    return UserModel.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> uploadUserDocuments({
    List<MultipartFile>? otrosDocumentos,
    MultipartFile? fotoPerfil,
    MultipartFile? cedulaFrontal,
    MultipartFile? cedulaPosterior,
    MultipartFile? licenciaConducir,
    MultipartFile? cartaTrabajo,
    MultipartFile? curriculumVitae,
  }) async {
    final form = FormData();

    if (fotoPerfil != null) form.files.add(MapEntry('foto_perfil', fotoPerfil));
    if (cedulaFrontal != null) form.files.add(MapEntry('cedula_frontal', cedulaFrontal));
    if (cedulaPosterior != null) form.files.add(MapEntry('cedula_posterior', cedulaPosterior));
    if (licenciaConducir != null) form.files.add(MapEntry('licencia_conducir', licenciaConducir));
    if (cartaTrabajo != null) form.files.add(MapEntry('carta_trabajo', cartaTrabajo));
    if (curriculumVitae != null) form.files.add(MapEntry('curriculum_vitae', curriculumVitae));
    for (final f in (otrosDocumentos ?? const <MultipartFile>[])) {
      form.files.add(MapEntry('otros_documentos', f));
    }

    final res = await _dio.post('/uploads/users', data: form);
    final data = res.data as Map<String, dynamic>;

    // Accept both camelCase and snake_case response keys.
    String? pickString(List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v is String && v.trim().isNotEmpty) return v;
      }
      return null;
    }

    List<String> pickList(List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v is List) {
          return v.whereType<String>().toList();
        }
      }
      return const [];
    }

    return {
      'foto_perfil_url': pickString(['foto_perfil_url', 'fotoPerfilUrl']),
      'cedula_frontal_url': pickString(['cedula_frontal_url', 'cedulaFrontalUrl']),
      'cedula_posterior_url': pickString(['cedula_posterior_url', 'cedulaPosteriorUrl']),
      'licencia_conducir_url': pickString(['licencia_conducir_url', 'licenciaConducirUrl']),
      'carta_trabajo_url': pickString(['carta_trabajo_url', 'cartaTrabajoUrl', 'cartaUltimoTrabajoUrl']),
      'curriculum_vitae_url': pickString(['curriculum_vitae_url', 'curriculumVitaeUrl']),
      'otros_documentos': pickList(['otros_documentos', 'otrosDocumentos']),
    };
  }

  Future<List<int>> downloadUserPdfBytes({required String id, required String kind}) async {
    final res = await _dio.get<List<int>>(
      '/users/$id/$kind',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const <int>[];
  }

  Future<String> downloadUserPdfToTempFile({required String id, required String kind}) async {
    final bytes = await downloadUserPdfBytes(id: id, kind: kind);
    if (bytes.isEmpty) throw Exception('No PDF bytes returned');

    final dir = await getTemporaryDirectory();
    final folder = Directory(p.join(dir.path, 'fulltech_cache', 'pdfs'));
    if (!await folder.exists()) await folder.create(recursive: true);

    final file = File(p.join(folder.path, 'user_${id}_$kind.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _sanitizeFileName(String name) {
    // Windows reserved characters: <>:"/\|?* and control chars.
    return name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
  }

  Future<String> downloadUserPdfToDownloadsFile({required String id, required String kind, String? fileName}) async {
    final bytes = await downloadUserPdfBytes(id: id, kind: kind);
    if (bytes.isEmpty) throw Exception('No PDF bytes returned');

    final downloads = await getDownloadsDirectory();
    final baseDir = downloads ?? await getApplicationDocumentsDirectory();

    final safeName = _sanitizeFileName(fileName ?? 'user_${id}_$kind.pdf');
    final file = File(p.join(baseDir.path, safeName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Map<String, dynamic>> extractFromCedula({required MultipartFile cedulaFrontal}) async {
    final form = FormData();
    form.files.add(MapEntry('cedula_frontal', cedulaFrontal));

    final res = await _dio.post('/users/ia/extraer-desde-cedula', data: form);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }

  Future<Map<String, dynamic>> extractFromLicencia({required MultipartFile licenciaFrontal}) async {
    final form = FormData();
    form.files.add(MapEntry('licencia_frontal', licenciaFrontal));

    final res = await _dio.post('/users/ia/extraer-desde-licencia', data: form);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
  }
}
