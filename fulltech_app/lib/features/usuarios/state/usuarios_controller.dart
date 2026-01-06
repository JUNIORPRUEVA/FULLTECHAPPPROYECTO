import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/usuarios_remote_datasource.dart';
import '../data/repositories/usuarios_repository.dart';
import '../models/usuario_model.dart';
import '../../auth/state/auth_providers.dart';

// ========== PROVIDERS BÁSICOS ==========

// Proveedor de UsuariosRepository
final usuariosRepositoryProvider = Provider<UsuariosRepository>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return UsuariosRepository(UsuariosRemoteDataSource(dio));
});

// ========== STATE NOTIFIERS ==========

class UsuariosListState {
  final List<UsuarioModel> usuarios;
  final int page;
  final int limit;
  final int total;
  final bool isLoading;
  final String? error;
  final String? rolFilter;
  final String? estadoFilter;
  final String? searchQuery;

  UsuariosListState({
    this.usuarios = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.rolFilter,
    this.estadoFilter,
    this.searchQuery,
  });

  UsuariosListState copyWith({
    List<UsuarioModel>? usuarios,
    int? page,
    int? limit,
    int? total,
    bool? isLoading,
    String? error,
    String? rolFilter,
    String? estadoFilter,
    String? searchQuery,
  }) {
    return UsuariosListState(
      usuarios: usuarios ?? this.usuarios,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      rolFilter: rolFilter ?? this.rolFilter,
      estadoFilter: estadoFilter ?? this.estadoFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  int get totalPages => (total / limit).ceil();
}

class UsuariosListNotifier extends StateNotifier<UsuariosListState> {
  final UsuariosRepository _repository;

  UsuariosListNotifier(this._repository) : super(UsuariosListState());

  /// Cargar usuarios
  Future<void> loadUsuarios({
    int page = 1,
    String? rol,
    String? estado,
    String? search,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.listUsuarios(
        page: page,
        limit: state.limit,
        rol: rol,
        estado: estado,
        search: search,
      );

      final usuarios = (result['data'] as List)
          .map((e) => UsuarioModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        usuarios: usuarios,
        page: page,
        total: result['pagination']['total'] ?? 0,
        isLoading: false,
        rolFilter: rol,
        estadoFilter: estado,
        searchQuery: search,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Buscar/filtrar
  Future<void> search({
    String? query,
    String? rol,
    String? estado,
  }) =>
      loadUsuarios(
        page: 1,
        rol: rol,
        estado: estado,
        search: query,
      );

  /// Ir a siguiente página
  Future<void> nextPage() =>
      loadUsuarios(
        page: state.page + 1,
        rol: state.rolFilter,
        estado: state.estadoFilter,
        search: state.searchQuery,
      );

  /// Ir a página anterior
  Future<void> previousPage() {
    if (state.page > 1) {
      return loadUsuarios(
        page: state.page - 1,
        rol: state.rolFilter,
        estado: state.estadoFilter,
        search: state.searchQuery,
      );
    }
    return Future.value();
  }

  /// Actualizar estado después de crear/eliminar
  Future<void> refresh() => loadUsuarios(
        page: state.page,
        rol: state.rolFilter,
        estado: state.estadoFilter,
        search: state.searchQuery,
      );
}

class UsuarioDetailState {
  final UsuarioModel? usuario;
  final bool isLoading;
  final String? error;

  UsuarioDetailState({
    this.usuario,
    this.isLoading = false,
    this.error,
  });

  UsuarioDetailState copyWith({
    UsuarioModel? usuario,
    bool? isLoading,
    String? error,
  }) {
    return UsuarioDetailState(
      usuario: usuario ?? this.usuario,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UsuarioDetailNotifier extends StateNotifier<UsuarioDetailState> {
  final UsuariosRepository _repository;

  UsuarioDetailNotifier(this._repository) : super(UsuarioDetailState());

  /// Cargar detalle de usuario
  Future<void> loadUsuario(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final usuario = await _repository.getUsuario(id);
      state = state.copyWith(usuario: usuario, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Actualizar usuario
  Future<void> updateUsuario(String id, Map<String, dynamic> data) async {
    try {
      final usuarioActualizado = await _repository.updateUsuario(id, data);
      state = state.copyWith(usuario: usuarioActualizado);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Bloquear usuario
  Future<void> blockUsuario(String id, bool bloqueado) async {
    try {
      await _repository.blockUsuario(id, bloqueado);
      if (state.usuario != null) {
        state = state.copyWith(
          usuario: state.usuario!.copyWith(
            estado: bloqueado ? 'bloqueado' : 'activo',
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Eliminar usuario
  Future<void> deleteUsuario(String id) async {
    try {
      await _repository.deleteUsuario(id);
      state = state.copyWith(usuario: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Descargar PDF
  Future<List<int>?> downloadProfilePDF(String id) async {
    try {
      return await _repository.downloadProfilePDF(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<List<int>?> downloadContractPDF(String id) async {
    try {
      return await _repository.downloadContractPDF(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

class UsuarioFormState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Map<String, dynamic> uploadedUrls;

  UsuarioFormState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.uploadedUrls = const {},
  });

  UsuarioFormState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    Map<String, dynamic>? uploadedUrls,
  }) {
    return UsuarioFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      uploadedUrls: uploadedUrls ?? this.uploadedUrls,
    );
  }
}

class UsuarioFormNotifier extends StateNotifier<UsuarioFormState> {
  final UsuariosRepository _repository;

  UsuarioFormNotifier(this._repository) : super(UsuarioFormState());

  /// Crear nuevo usuario
  Future<UsuarioModel?> createUsuario(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final usuario = await _repository.createUsuario(data);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Usuario creado exitosamente',
      );
      return usuario;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Subir documentos
  Future<void> uploadDocuments({
    String? fotoPerfil,
    String? cedulaFoto,
    String? cartaUltimoTrabajo,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final urls = await _repository.uploadUserDocuments(
        fotoPerfil: fotoPerfil,
        cedulaFoto: cedulaFoto,
        cartaUltimoTrabajo: cartaUltimoTrabajo,
      );
      state = state.copyWith(
        isLoading: false,
        uploadedUrls: urls,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Extraer datos de cédula con IA
  Future<Map<String, dynamic>?> extractCedulaData(String imagenUrl) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final datos = await _repository.extractCedulaData(imagenUrl);
      state = state.copyWith(isLoading: false);
      return datos;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Limpiar estado
  void clearState() {
    state = UsuarioFormState();
  }
}

// ========== RIVERPOD PROVIDERS ==========

final usuariosListProvider =
    StateNotifierProvider<UsuariosListNotifier, UsuariosListState>((ref) {
  final repository = ref.watch(usuariosRepositoryProvider);
  return UsuariosListNotifier(repository);
});

final usuarioDetailProvider =
    StateNotifierProvider<UsuarioDetailNotifier, UsuarioDetailState>((ref) {
  final repository = ref.watch(usuariosRepositoryProvider);
  return UsuarioDetailNotifier(repository);
});

final usuarioFormProvider =
    StateNotifierProvider<UsuarioFormNotifier, UsuarioFormState>((ref) {
  final repository = ref.watch(usuariosRepositoryProvider);
  return UsuarioFormNotifier(repository);
});
