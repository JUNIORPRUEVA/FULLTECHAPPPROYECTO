import '../datasources/usuarios_remote_datasource.dart';
import '../../models/usuario_model.dart';

class UsuariosRepository {
  final UsuariosRemoteDataSource _remoteDataSource;

  UsuariosRepository(this._remoteDataSource);

  /// Obtener lista paginada de usuarios
  Future<Map<String, dynamic>> listUsuarios({
    int page = 1,
    int limit = 20,
    String? rol,
    String? estado,
    String? search,
  }) =>
      _remoteDataSource.listUsuarios(
        page: page,
        limit: limit,
        rol: rol,
        estado: estado,
        search: search,
      );

  /// Obtener usuario por ID
  Future<UsuarioModel> getUsuario(String id) =>
      _remoteDataSource.getUsuario(id);

  /// Crear nuevo usuario
  Future<UsuarioModel> createUsuario(Map<String, dynamic> data) =>
      _remoteDataSource.createUsuario(data);

  /// Actualizar usuario
  Future<UsuarioModel> updateUsuario(String id, Map<String, dynamic> data) =>
      _remoteDataSource.updateUsuario(id, data);

  /// Bloquear/desbloquear usuario
  Future<Map<String, dynamic>> blockUsuario(String id, bool bloqueado) =>
      _remoteDataSource.blockUsuario(id, bloqueado);

  /// Eliminar usuario
  Future<void> deleteUsuario(String id) =>
      _remoteDataSource.deleteUsuario(id);

  /// Subir documentos
  Future<Map<String, dynamic>> uploadUserDocuments({
    String? fotoPerfil,
    String? cedulaFoto,
    String? cartaUltimoTrabajo,
  }) =>
      _remoteDataSource.uploadUserDocuments(
        fotoPerfil: fotoPerfil,
        cedulaFoto: cedulaFoto,
        cartaUltimoTrabajo: cartaUltimoTrabajo,
      );

  /// Extraer datos de cédula con IA
  Future<Map<String, dynamic>> extractCedulaData(String imagenUrl) =>
      _remoteDataSource.extractCedulaData(imagenUrl);

  /// Descargar PDF de ficha
  Future<List<int>> downloadProfilePDF(String usuarioId) =>
      _remoteDataSource.downloadProfilePDF(usuarioId);

  /// Descargar PDF de contrato
  Future<List<int>> downloadContractPDF(String usuarioId) =>
      _remoteDataSource.downloadContractPDF(usuarioId);
}
