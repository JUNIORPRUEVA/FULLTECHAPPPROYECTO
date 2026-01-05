import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../../../../core/widgets/module_page.dart';
import '../../providers/punch_provider.dart';
import '../../data/models/punch_record.dart';
import '../widgets/punch_filters_bar.dart';
import '../widgets/punch_today_card.dart';
import '../widgets/punch_list_view.dart';

class PonchodoPage extends ConsumerStatefulWidget {
  const PonchodoPage({super.key});

  @override
  ConsumerState<PonchodoPage> createState() => _PonchodoPageState();
}

class _PonchodoPageState extends ConsumerState<PonchodoPage> {
  bool _isPunching = false;

  String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime _localDateTimeFromPunch(PunchRecord p) {
    final parsed = DateTime.tryParse(p.datetimeLocal);
    if (parsed != null) return parsed;
    return p.datetimeUtc.toLocal();
  }

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

  IconData _typeIcon(PunchType type) {
    switch (type) {
      case PunchType.in_:
        return Icons.login;
      case PunchType.lunchStart:
        return Icons.lunch_dining;
      case PunchType.lunchEnd:
        return Icons.restaurant;
      case PunchType.out:
        return Icons.logout;
    }
  }

  ({Set<PunchType> allowed, String? reason}) _allowedPunchTypesForToday(
    List<PunchRecord> todayPunches,
  ) {
    final types = todayPunches.map((p) => p.type).toSet();

    bool has(PunchType t) => types.contains(t);

    // If already closed the day.
    if (has(PunchType.out)) {
      return (allowed: <PunchType>{}, reason: 'Ya registraste la salida hoy.');
    }

    // Must start with IN.
    if (!has(PunchType.in_)) {
      // If there are inconsistent punches, block to avoid corrupt data.
      if (todayPunches.isNotEmpty) {
        return (
          allowed: <PunchType>{},
          reason:
              'Registros de hoy inconsistentes. Contacta a un administrador.',
        );
      }
      return (allowed: <PunchType>{PunchType.in_}, reason: null);
    }

    // Lunch flow.
    if (has(PunchType.lunchStart) && !has(PunchType.lunchEnd)) {
      return (allowed: <PunchType>{PunchType.lunchEnd}, reason: null);
    }

    // Normal: after IN (and optionally after lunch end), you can OUT.
    if (has(PunchType.lunchEnd) && !has(PunchType.lunchStart)) {
      return (
        allowed: <PunchType>{},
        reason:
            'Registros de almuerzo inconsistentes. Contacta a un administrador.',
      );
    }

    // After IN, you may either start lunch or leave (skip lunch).
    if (!has(PunchType.lunchStart) && !has(PunchType.lunchEnd)) {
      return (
        allowed: <PunchType>{PunchType.lunchStart, PunchType.out},
        reason: null,
      );
    }

    // After lunch end, only OUT remains.
    if (has(PunchType.lunchStart) && has(PunchType.lunchEnd)) {
      return (allowed: <PunchType>{PunchType.out}, reason: null);
    }

    // Fallback (should not happen).
    return (
      allowed: <PunchType>{},
      reason:
          'No se pudo determinar el siguiente ponchado. Contacta a un administrador.',
    );
  }

  Future<PunchType?> _pickSmartPunchType(BuildContext context) async {
    final nowLocal = DateTime.now();
    if (nowLocal.weekday == DateTime.sunday) {
      _showSnack(
        context,
        icon: Icons.block,
        message: 'No se permite ponchar los domingos.',
      );
      return null;
    }

    final repo = ref.read(punchRepositoryProvider);
    final loader = _showBlockingLoader(
      context,
      message: 'Verificando ponchados de hoy…',
    );

    List<PunchRecord> todayPunches = const [];
    try {
      // Fetch a slightly wider UTC range to avoid timezone edge cases,
      // then filter by local day for the user.
      final nowUtc = nowLocal.toUtc();
      final utcDayStart = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
      final from = _dateKey(utcDayStart.subtract(const Duration(days: 1)));
      final to = _dateKey(utcDayStart.add(const Duration(days: 1)));

      final resp = await repo.listPunches(
        from: from,
        to: to,
        limit: 200,
        offset: 0,
      );
      final todayKey = _dateKey(nowLocal);

      todayPunches =
          resp.items
              .where((p) => _dateKey(_localDateTimeFromPunch(p)) == todayKey)
              .toList()
            ..sort((a, b) => a.datetimeUtc.compareTo(b.datetimeUtc));
    } catch (_) {
      // If we can't verify, allow fallback selection (still validated server-side).
      todayPunches = const [];
    } finally {
      loader.close();
    }

    if (!context.mounted) return null;

    final decision = _allowedPunchTypesForToday(todayPunches);
    final allowed = decision.allowed;
    final reason = decision.reason;

    if (allowed.isEmpty) {
      _showSnack(
        context,
        icon: Icons.info_outline,
        message: reason ?? 'No hay ponchados disponibles para hoy.',
      );
      return null;
    }

    // Show only the allowed actions to keep UX clean and avoid mistakes.
    return showDialog<PunchType>(
      context: context,
      builder: (context) {
        final done = todayPunches
            .map((p) => _typeLabel(p.type))
            .toSet()
            .join(' · ');

        return AlertDialog(
          title: const Text('Registrar ponchado'),
          contentPadding: const EdgeInsets.only(top: 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (done.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Hoy: $done',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              for (final t in PunchType.values)
                if (allowed.contains(t))
                  _PunchTypeTile(
                    icon: _typeIcon(t),
                    title: _typeLabel(t),
                    onTap: () => Navigator.pop(context, t),
                  ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<Position> _getBestEffortAccuratePosition({
    Duration timeout = const Duration(seconds: 12),
    double desiredAccuracyMeters = 60,
  }) async {
    final LocationSettings settings;

    // Use the best available settings per platform.
    // This does not guarantee GPS on every device (e.g., Windows desktop can be coarse).
    if (Theme.of(context).platform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(milliseconds: 500),
      );
    } else if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );
    }

    Position? best;
    StreamSubscription<Position>? sub;
    final completer = Completer<Position>();

    void consider(Position p) {
      if (best == null || p.accuracy < best!.accuracy) {
        best = p;
      }
      if (p.accuracy <= desiredAccuracyMeters && !completer.isCompleted) {
        completer.complete(p);
      }
    }

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        if (best != null) {
          completer.complete(best!);
        } else {
          completer.completeError(TimeoutException('No location fix', timeout));
        }
      }
    });

    try {
      // Start listening for improving accuracy.
      sub = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(consider, onError: (_) {});

      // Also request an immediate fix (often returns quickly, sometimes coarse).
      try {
        final current = await Geolocator.getCurrentPosition(
          locationSettings: settings,
        );
        consider(current);
        if (completer.isCompleted) return completer.future;
      } catch (_) {
        // Ignore and rely on stream.
      }

      return await completer.future;
    } finally {
      timer.cancel();
      await sub?.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Best-effort: retry previously failed sync items whenever the module opens.
      // ignore: unawaited_futures
      ref.read(punchRepositoryProvider).retryFailed().then((_) {
        // ignore: unawaited_futures
        ref.read(punchRepositoryProvider).syncPending();
      });
      ref.read(punchesControllerProvider.notifier).loadPunches(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return ModulePage(
      title: 'Ponchado de Asistencia',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () async {
            // Best-effort: if there are local FAILED punches, retry syncing them now.
            try {
              final repo = ref.read(punchRepositoryProvider);
              await repo.retryFailed();
              await repo.syncPending();
            } catch (_) {
              // Ignore; refresh still works offline.
            }

            ref
                .read(punchesControllerProvider.notifier)
                .loadPunches(reset: true);
            ref.invalidate(todaySummaryProvider);
          },
          tooltip: 'Actualizar',
        ),
        FilledButton.icon(
          onPressed: () => _showPunchDialog(context),
          icon: const Icon(Icons.fingerprint),
          label: const Text('Nuevo ponche'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: PunchFiltersBar(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (isWideScreen) {
                  // Desktop: Left list, Right full-height panel
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(child: PunchListView()),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 420,
                        child: _RightPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const PunchTodayCard(),
                              const SizedBox(height: 16),
                              _RightPanelActions(
                                buildPunchButton: _buildPunchButton,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Mobile: Summary + action, then list
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const PunchTodayCard(),
                          const SizedBox(height: 12),
                          _buildPunchButton(context),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Registros',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Expanded(child: PunchListView()),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPunchButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isPunching ? null : () => _showPunchDialog(context),
      icon: const Icon(Icons.fingerprint),
      label: const Text('Registrar Ponchado'),
    );
  }

  Future<void> _showPunchDialog(BuildContext context) async {
    if (_isPunching) return;

    final platformName = Theme.of(context).platform.name;

    final type = await _pickSmartPunchType(context);

    if (!context.mounted) return;

    if (type == null) return;

    if (mounted) {
      setState(() => _isPunching = true);
    }

    final loading = _showBlockingLoader(context, message: 'Registrando…');

    Position? pos;
    bool locationMissing = false;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        locationMissing = true;
      } else {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          locationMissing = true;
        } else {
          pos = await _getBestEffortAccuratePosition();
        }
      }
    } catch (_) {
      locationMissing = true;
    }

    final nowLocal = DateTime.now();

    // If we got a very coarse location (common when "Precise location" is off
    // or when running on desktop), keep it but treat it as approximate.
    final isCoarse = pos != null && pos.accuracy > 250;

    final dto = CreatePunchDto(
      type: type,
      datetimeUtc: nowLocal.toUtc(),
      datetimeLocal: nowLocal.toIso8601String(),
      timezone: nowLocal.timeZoneName,
      locationLat: pos?.latitude,
      locationLng: pos?.longitude,
      locationAccuracy: pos?.accuracy,
      locationProvider: pos == null ? null : (isCoarse ? 'approx' : 'gps'),
      addressText: null,
      locationMissing: locationMissing,
      deviceId: null,
      deviceName: null,
      platform: platformName,
      note: null,
      syncStatus: SyncStatus.pending,
    );

    try {
      final repo = ref.read(punchRepositoryProvider);
      await repo.createPunchOfflineFirst(dto);
      loading.close();
      if (!context.mounted) return;
      ref.read(punchesControllerProvider.notifier).loadPunches(reset: true);
      ref.invalidate(todaySummaryProvider);

      final successMessage = locationMissing
          ? 'Ponchado registrado. Ubicación no disponible.'
          : (isCoarse
                ? 'Ponchado registrado. Ubicación aproximada (~${pos.accuracy.toStringAsFixed(0)} m).'
                : 'Ponchado registrado (offline-first)');
      _showSnack(
        context,
        icon: locationMissing ? Icons.location_off : Icons.check_circle,
        message: successMessage,
      );
    } catch (e) {
      loading.close();
      if (!context.mounted) return;
      _showSnack(
        context,
        icon: Icons.error_outline,
        message: 'Error al ponchar: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isPunching = false);
      }
    }
  }

  void _showSnack(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onInverseSurface),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  _LoaderHandle _showBlockingLoader(
    BuildContext context, {
    required String message,
  }) {
    bool open = true;
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      },
    );

    return _LoaderHandle(() {
      if (!open) return;
      open = false;
      if (navigator.canPop()) navigator.pop();
    });
  }
}

class _PunchTypeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PunchTypeTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}

class _LoaderHandle {
  final VoidCallback close;
  const _LoaderHandle(this.close);
}

class _RightPanel extends StatelessWidget {
  final Widget child;

  const _RightPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

class _RightPanelActions extends ConsumerWidget {
  final Widget Function(BuildContext) buildPunchButton;

  const _RightPanelActions({required this.buildPunchButton});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildPunchButton(context),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final repo = ref.read(punchRepositoryProvider);
            await repo.retryFailed();
            await repo.syncPending();
            ref
                .read(punchesControllerProvider.notifier)
                .loadPunches(reset: true);
            ref.invalidate(todaySummaryProvider);
          },
          icon: const Icon(Icons.sync),
          label: const Text('Sincronizar'),
        ),
      ],
    );
  }
}
