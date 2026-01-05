import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../data/models/punch_record.dart';
import '../../providers/punch_provider.dart';

class PunchDetailDialog extends ConsumerWidget {
  final PunchRecord punch;
  final bool isAdmin;

  const PunchDetailDialog({
    super.key,
    required this.punch,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEditOrDelete =
        isAdmin &&
        punch.syncStatus == SyncStatus.synced &&
        !punch.id.startsWith('local-');

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.fingerprint),
          const SizedBox(width: 8),
          Text(_getTypeLabel(punch.type)),
        ],
      ),
      content: SizedBox(
        width: 800,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoRow(
              label: 'Fecha/Hora',
              value: _formatDateTime(punch.datetimeUtc),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Estado de sync',
              value: _syncLabel(punch.syncStatus),
            ),
            const SizedBox(height: 8),
            if (punch.note != null && punch.note!.isNotEmpty)
              _InfoRow(label: 'Notas', value: punch.note!),
            const SizedBox(height: 16),
            _LocationMap(punch: punch),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        if (canEditOrDelete)
          OutlinedButton.icon(
            onPressed: () async {
              final updates = await _showEditDialog(
                context,
                punch: punch,
                isAdmin: isAdmin,
              );
              if (updates == null) return;
              try {
                final repo = ref.read(punchRepositoryProvider);
                await repo.updatePunch(punch.id, updates);
                ref
                    .read(punchesControllerProvider.notifier)
                    .loadPunches(reset: true);
                ref.invalidate(todaySummaryProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Registro actualizado'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No se pudo editar: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
        if (canEditOrDelete)
          FilledButton.tonalIcon(
            onPressed: () async {
              final ok = await _confirmDelete(context);
              if (ok != true) return;
              try {
                final repo = ref.read(punchRepositoryProvider);
                await repo.deletePunch(punch.id);
                ref
                    .read(punchesControllerProvider.notifier)
                    .loadPunches(reset: true);
                ref.invalidate(todaySummaryProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Registro eliminado'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No se pudo eliminar: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar'),
          ),
      ],
    );
  }

  static String _getTypeLabel(PunchType type) {
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

  static String _syncLabel(SyncStatus s) {
    switch (s) {
      case SyncStatus.synced:
        return 'Sincronizado';
      case SyncStatus.pending:
        return 'Pendiente';
      case SyncStatus.failed:
        return 'Error';
    }
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}/${dt.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _LocationMap extends StatelessWidget {
  final PunchRecord punch;

  const _LocationMap({required this.punch});

  @override
  Widget build(BuildContext context) {
    final lat = punch.locationLat;
    final lng = punch.locationLng;
    final hasLocation = lat != null && lng != null;

    void openFullscreen() {
      if (!hasLocation) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => _FullscreenPunchMapPage(punch: punch),
        ),
      );
    }

    return SizedBox(
      height: 420,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: hasLocation
            ? FlutterMap(
                options: MapOptions(
                  initialCenter: ll.LatLng(lat, lng),
                  initialZoom: 18,
                  // Allow users to zoom in as much as possible.
                  // Some providers cap native tiles (e.g. 19); higher zoom will upscale.
                  maxZoom: 22,
                  onTap: (tapPosition, latLng) => openFullscreen(),
                ),
                children: [
                  TileLayer(
                    // Satellite/earth view
                    urlTemplate:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'fulltech_app',
                    maxNativeZoom: 19,
                    maxZoom: 22,
                  ),
                  // Labels/roads overlay (transparent) for better readability.
                  Opacity(
                    opacity: 0.95,
                    child: TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'fulltech_app',
                      maxNativeZoom: 20,
                      maxZoom: 22,
                    ),
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: ll.LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'Imagery © Esri, Maxar, Earthstar Geographics, and the GIS User Community',
                      ),
                      TextSourceAttribution(
                        '© OpenStreetMap contributors © CARTO',
                      ),
                    ],
                  ),
                ],
              )
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Text(
                    'Sin ubicación registrada',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
      ),
    );
  }
}

enum _PunchMapView { satellite, street }

class _FullscreenPunchMapPage extends StatefulWidget {
  final PunchRecord punch;

  const _FullscreenPunchMapPage({required this.punch});

  @override
  State<_FullscreenPunchMapPage> createState() =>
      _FullscreenPunchMapPageState();
}

class _FullscreenPunchMapPageState extends State<_FullscreenPunchMapPage> {
  _PunchMapView _view = _PunchMapView.satellite;

  void _toggleView() {
    setState(() {
      _view = _view == _PunchMapView.satellite
          ? _PunchMapView.street
          : _PunchMapView.satellite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final punch = widget.punch;
    final lat = punch.locationLat;
    final lng = punch.locationLng;
    final hasLocation = lat != null && lng != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicación del ponchado'),
        actions: [
          IconButton(
            tooltip: _view == _PunchMapView.satellite
                ? 'Cambiar a Mapa'
                : 'Cambiar a Satélite',
            onPressed: _toggleView,
            icon: Icon(
              _view == _PunchMapView.satellite
                  ? Icons.map_outlined
                  : Icons.satellite_outlined,
            ),
          ),
        ],
      ),
      body: hasLocation
          ? FlutterMap(
              options: MapOptions(
                initialCenter: ll.LatLng(lat, lng),
                initialZoom: 18,
                maxZoom: 22,
              ),
              children: [
                if (_view == _PunchMapView.satellite) ...[
                  TileLayer(
                    urlTemplate:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'fulltech_app',
                    maxNativeZoom: 19,
                    maxZoom: 22,
                  ),
                  Opacity(
                    opacity: 0.95,
                    child: TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'fulltech_app',
                      maxNativeZoom: 20,
                      maxZoom: 22,
                    ),
                  ),
                ] else ...[
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'fulltech_app',
                    maxNativeZoom: 19,
                    maxZoom: 22,
                  ),
                ],
                MarkerLayer(
                  markers: [
                    Marker(
                      point: ll.LatLng(lat, lng),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 36,
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    if (_view == _PunchMapView.satellite)
                      TextSourceAttribution(
                        'Imagery © Esri, Maxar, Earthstar Geographics, and the GIS User Community',
                      ),
                    if (_view == _PunchMapView.satellite)
                      TextSourceAttribution(
                        '© OpenStreetMap contributors © CARTO',
                      ),
                    if (_view == _PunchMapView.street)
                      TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            )
          : Center(
              child: Text(
                'Sin ubicación registrada',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
    );
  }
}

Future<Map<String, dynamic>?> _showEditDialog(
  BuildContext context, {
  required PunchRecord punch,
  required bool isAdmin,
}) async {
  PunchType selectedType = punch.type;
  DateTime selectedUtc = punch.datetimeUtc;
  final noteCtrl = TextEditingController(text: punch.note ?? '');

  Map<String, dynamic>? result;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar ponchado'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<PunchType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: PunchType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(PunchDetailDialog._getTypeLabel(t)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: isAdmin
                        ? (v) => setState(() => selectedType = v!)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  if (isAdmin)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: const Text('Fecha/Hora'),
                      subtitle: Text(
                        PunchDetailDialog._formatDateTime(selectedUtc),
                      ),
                      onTap: () async {
                        final local = selectedUtc.toLocal();
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          initialDate: local,
                        );
                        if (date == null) return;

                        if (!context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(local),
                        );
                        if (time == null) return;

                        if (!context.mounted) return;
                        final mergedLocal = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        setState(() => selectedUtc = mergedLocal.toUtc());
                      },
                    ),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final note = noteCtrl.text.trim();
                  result = {
                    'note': note.isEmpty ? null : note,
                    'isManualEdit': true,
                    if (isAdmin) 'type': _typeToApi(selectedType),
                    if (isAdmin) 'datetimeUtc': selectedUtc.toIso8601String(),
                  };
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );

  noteCtrl.dispose();
  return result;
}

Future<bool?> _confirmDelete(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Seguro que deseas eliminar este ponchado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
}

String _typeToApi(PunchType type) {
  switch (type) {
    case PunchType.in_:
      return 'IN';
    case PunchType.lunchStart:
      return 'LUNCH_START';
    case PunchType.lunchEnd:
      return 'LUNCH_END';
    case PunchType.out:
      return 'OUT';
  }
}
