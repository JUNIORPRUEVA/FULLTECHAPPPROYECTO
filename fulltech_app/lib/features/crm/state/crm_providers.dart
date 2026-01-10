import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/app_config.dart';
import '../../../core/state/api_endpoint_settings_provider.dart';
import '../../catalogo/state/catalog_providers.dart';
import '../../catalogo/models/producto.dart';
import '../../usuarios/models/registered_user.dart';
import '../data/datasources/crm_remote_datasource.dart';
import '../data/datasources/customers_remote_datasource.dart';
import '../data/repositories/crm_repository.dart';
import '../data/repositories/crm_status_data_repository.dart';
import '../data/repositories/customers_repository.dart';
import '../data/services/crm_sse_client.dart';
import 'crm_chat_filters_controller.dart';
import 'crm_chat_filters_state.dart';
import 'crm_chat_stats_controller.dart';
import 'crm_chat_stats_state.dart';
import 'crm_messages_controller.dart';
import 'crm_messages_state.dart';
import 'crm_threads_controller.dart';
import 'crm_threads_state.dart';
import 'customer_detail_controller.dart';
import 'customer_detail_state.dart';
import 'customers_controller.dart';
import 'customers_state.dart';

final crmApiClientProvider = Provider<ApiClient>((ref) {
  // Rebuild client when the API endpoint setting changes.
  ref.watch(apiEndpointSettingsProvider);
  if (kDebugMode) {
    debugPrint('[CRM] baseUrl=${AppConfig.crmApiBaseUrl}');
  }
  return ApiClient.forBaseUrl(
    ref.watch(localDbProvider),
    AppConfig.crmApiBaseUrl,
  );
});

final crmOnlineProvider = StreamProvider<bool>((ref) async* {
  bool isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  try {
    final initial = await Connectivity().checkConnectivity();
    yield isOnline(initial);
  } catch (_) {
    // If we can't determine, assume online to avoid false negatives.
    yield true;
  }

  await for (final results in Connectivity().onConnectivityChanged) {
    yield isOnline(results);
  }
});

final crmRemoteDataSourceProvider = Provider<CrmRemoteDataSource>((ref) {
  return CrmRemoteDataSource(ref.watch(crmApiClientProvider).dio);
});

final crmRepositoryProvider = Provider<CrmRepository>((ref) {
  return CrmRepository(
    ref.watch(crmRemoteDataSourceProvider),
    ref.watch(localDbProvider),
  );
});

final crmStatusDataRepositoryProvider = Provider<CrmStatusDataRepository>((
  ref,
) {
  return CrmStatusDataRepository();
});

final crmThreadsControllerProvider =
    StateNotifierProvider<CrmThreadsController, CrmThreadsState>((ref) {
      return CrmThreadsController(repo: ref.watch(crmRepositoryProvider));
    });

final selectedThreadIdProvider = StateProvider<String?>((ref) => null);

final crmChatFiltersProvider =
    StateNotifierProvider<CrmChatFiltersController, CrmChatFiltersState>((ref) {
      return CrmChatFiltersController();
    });

final crmProductsProvider = StreamProvider<List<Producto>>((ref) async* {
  // Offline-first products for CRM.
  // Reads cached snapshot from local DB, then refreshes from network when online.
  const store = 'catalog_products';

  final db = ref.watch(localDbProvider);
  final api = ref.watch(catalogApiProvider);

  Future<List<Producto>> readCached() async {
    final rows = await db.listEntitiesJson(store: store);
    return rows
        .map((s) => Producto.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<List<Producto>> refreshFromApi() async {
    final productos = await api.listProductos(includeInactive: true);
    await db.clearStore(store: store);
    for (final p in productos) {
      await db.upsertEntity(
        store: store,
        id: p.id,
        json: jsonEncode(p.toJson()),
      );
    }
    return productos;
  }

  try {
    final cached = await readCached();
    if (cached.isNotEmpty) yield cached;
  } catch (_) {
    // Ignore cache errors.
  }

  bool isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  try {
    final initial = await Connectivity().checkConnectivity();
    if (isOnline(initial)) {
      yield await refreshFromApi();
    }
  } catch (_) {
    // Ignore connectivity errors.
  }

  await for (final results in Connectivity().onConnectivityChanged) {
    if (!isOnline(results)) continue;
    try {
      yield await refreshFromApi();
    } catch (_) {
      // Best-effort.
    }
  }
});

final crmTechniciansProvider = FutureProvider<List<RegisteredUserSummary>>((
  ref,
) async {
  // Use Operations endpoint so non-admin CRM users can still load technicians.
  final dio = ref.watch(apiClientProvider).dio;

  final res = await dio.get('/operations/technicians');
  final data = res.data as Map<String, dynamic>;
  final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
      .cast<Map<String, dynamic>>()
      .map(RegisteredUserSummary.fromJson)
      .toList(growable: false);

  // Defensive: filter client-side too (backend already filters).
  final allowed = <String>{
    'tecnico',
    'tecnico_fijo',
    'technician',
    'technical',
    'contratista',
    'contractor',
  };
  final out = items
      .where((u) => allowed.contains(u.rol.toLowerCase().trim()))
      .toList(growable: false);
  out.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
  return out;
});

final crmSseClientProvider = Provider<CrmSseClient>((ref) {
  return CrmSseClient(ref.watch(crmApiClientProvider).dio);
});

final crmRealtimeProvider = Provider<void>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthAuthenticated) {
    // Don't connect SSE when unauthenticated/validating.
    return;
  }

  final client = ref.watch(crmSseClientProvider);

  final pendingChatIds = <String>{};
  Timer? timer;
  bool isRefreshing = false;

  void flush() {
    timer?.cancel();
    timer = null;

    // Prevent multiple simultaneous refreshes
    if (isRefreshing) return;
    isRefreshing = true;

    // Always refresh threads once for any CRM event.
    // Controllers are offline-first (cache local then refresh), so this keeps
    // immediate backend updates while maintaining a local base.
    ref
        .read(crmThreadsControllerProvider.notifier)
        .refresh()
        .then((_) {
          isRefreshing = false;
        })
        .catchError((e) {
          isRefreshing = false;
        });

    final selected = ref.read(selectedThreadIdProvider);
    if (selected != null && pendingChatIds.contains(selected)) {
      // ignore: unawaited_futures
      ref.read(crmMessagesControllerProvider(selected).notifier).loadInitial();
    }
    pendingChatIds.clear();
  }

  void scheduleFlush() {
    // Increased debounce to 300ms to reduce DB pressure
    timer ??= Timer(const Duration(milliseconds: 300), flush);
  }

  final sub = client.stream().listen(
    (evt) {
      if (evt.type == 'message.new' && evt.chatId != null) {
        pendingChatIds.add(evt.chatId!);
        scheduleFlush();
        return;
      }
      if (evt.type == 'message.updated' && evt.chatId != null) {
        pendingChatIds.add(evt.chatId!);
        scheduleFlush();
        return;
      }
      if (evt.type == 'chat.updated' && evt.chatId != null) {
        pendingChatIds.add(evt.chatId!);
        scheduleFlush();
        return;
      }
      if (evt.type == 'message.status' && evt.chatId != null) {
        pendingChatIds.add(evt.chatId!);
        scheduleFlush();
        return;
      }
    },
    onError: (e) {
      if (kDebugMode) {
        debugPrint('[CRM][SSE] stream onError: $e');
      }
    },
    onDone: () {
      if (kDebugMode) {
        debugPrint('[CRM][SSE] stream onDone');
      }
    },
  );

  ref.onDispose(() async {
    timer?.cancel();
    await sub.cancel();
  });
});

final crmMessagesControllerProvider =
    StateNotifierProvider.family<
      CrmMessagesController,
      CrmMessagesState,
      String
    >((ref, threadId) {
      return CrmMessagesController(
        repo: ref.watch(crmRepositoryProvider),
        threadId: threadId,
      );
    });

final crmChatStatsControllerProvider =
    StateNotifierProvider<CrmChatStatsController, CrmChatStatsState>((ref) {
      return CrmChatStatsController(repo: ref.watch(crmRepositoryProvider));
    });

final customersRemoteDataSourceProvider = Provider<CustomersRemoteDataSource>((
  ref,
) {
  return CustomersRemoteDataSource(ref.watch(crmApiClientProvider).dio);
});

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(ref.watch(customersRemoteDataSourceProvider));
});

final customersControllerProvider =
    StateNotifierProvider<CustomersController, CustomersState>((ref) {
      return CustomersController(repo: ref.watch(customersRepositoryProvider));
    });

final customerDetailControllerProvider =
    StateNotifierProvider.family<
      CustomerDetailController,
      CustomerDetailState,
      String
    >((ref, customerId) {
      return CustomerDetailController(
        repo: ref.watch(customersRepositoryProvider),
        customerId: customerId,
      );
    });
