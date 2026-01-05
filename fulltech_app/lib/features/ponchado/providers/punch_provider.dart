import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/dio_provider.dart';
import '../../auth/state/auth_providers.dart';
import '../data/datasources/punch_remote_datasource.dart';
import '../data/repositories/punch_repository.dart';
import '../data/models/punch_record.dart';
import '../../../core/utils/debouncer.dart';

// DataSource
final punchRemoteDataSourceProvider = Provider<PunchRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return PunchRemoteDataSource(dio);
});

// Repository
final punchRepositoryProvider = Provider<PunchRepository>((ref) {
  final remoteDataSource = ref.watch(punchRemoteDataSourceProvider);
  final db = ref.watch(localDbProvider);
  return PunchRepository(remoteDataSource, db);
});

// State for punches list
class PunchesState {
  final List<PunchRecord> punches;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  PunchesState({
    this.punches = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  PunchesState copyWith({
    List<PunchRecord>? punches,
    bool? isLoading,
    String? error,
    bool? hasMore,
  }) {
    return PunchesState(
      punches: punches ?? this.punches,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Controller for punches list
class PunchesController extends StateNotifier<PunchesState> {
  final PunchRepository repository;
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 400),
  );

  String _typeLabel(PunchType type) {
    switch (type) {
      case PunchType.in_:
        return 'Entrada';
      case PunchType.lunchStart:
        return 'Inicio Almuerzo';
      case PunchType.lunchEnd:
        return 'Fin Almuerzo';
      case PunchType.out:
        return 'Salida';
    }
  }

  // Filters
  String? fromDate;
  String? toDate;
  PunchType? typeFilter;
  String? search;

  PunchesController(this.repository) : super(PunchesState());

  @override
  void dispose() {
    _debouncer.dispose();
    repository.cancelRequests();
    super.dispose();
  }

  Future<void> loadPunches({bool reset = false}) async {
    if (reset) {
      state = PunchesState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await repository.listPunches(
        from: fromDate,
        to: toDate,
        type: typeFilter,
        limit: 100,
        offset: reset ? 0 : state.punches.length,
      );

      final filtered = (search == null || search!.trim().isEmpty)
          ? response.items
          : response.items.where((p) {
              final q = search!.trim().toLowerCase();
            // Buscar por tipo (Entrada/Salida/...) y otros campos útiles.
            // Intencionalmente NO se busca por ubicación/addressText.
            final typeText = _typeLabel(p.type).toLowerCase();
            final note = (p.note ?? '').toLowerCase();
            final userName = (p.userName ?? '').toLowerCase();
            final userEmail = (p.userEmail ?? '').toLowerCase();
            final deviceName = (p.deviceName ?? '').toLowerCase();
            final platform = (p.platform ?? '').toLowerCase();
            final datetimeLocal = (p.datetimeLocal).toLowerCase();

            return typeText.contains(q) ||
              note.contains(q) ||
              userName.contains(q) ||
              userEmail.contains(q) ||
              deviceName.contains(q) ||
              platform.contains(q) ||
              datetimeLocal.contains(q);
            }).toList();

      final newPunches = reset ? filtered : [...state.punches, ...filtered];

      state = state.copyWith(
        punches: newPunches,
        isLoading: false,
        hasMore: newPunches.length < response.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setDateRange(String? from, String? to) {
    fromDate = from;
    toDate = to;
    _debouncer.run(() => loadPunches(reset: true));
  }

  void setTypeFilter(PunchType? type) {
    typeFilter = type;
    _debouncer.run(() => loadPunches(reset: true));
  }

  void setSearch(String? value) {
    search = value;
    _debouncer.run(() => loadPunches(reset: true));
  }

  void clearFilters() {
    fromDate = null;
    toDate = null;
    typeFilter = null;
    search = null;
    loadPunches(reset: true);
  }
}

// Provider for the controller
final punchesControllerProvider =
    StateNotifierProvider<PunchesController, PunchesState>((ref) {
      final repository = ref.watch(punchRepositoryProvider);
      return PunchesController(repository);
    });

// Provider for today's summary
final todaySummaryProvider = FutureProvider<PunchSummary>((ref) async {
  final repository = ref.watch(punchRepositoryProvider);
  final today = DateTime.now().toIso8601String().split('T')[0];
  return await repository.getSummary(from: today, to: today);
});
