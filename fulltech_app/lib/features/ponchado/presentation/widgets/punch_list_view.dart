import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/compact_error_widget.dart';
import '../../../auth/state/auth_providers.dart';
import '../../../auth/state/auth_state.dart';
import '../../data/models/punch_record.dart';
import '../../providers/punch_provider.dart';
import '../dialogs/punch_detail_dialog.dart';

class PunchListView extends ConsumerWidget {
  const PunchListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(punchesControllerProvider);

    if (state.isLoading && state.punches.isEmpty) {
      return const _PunchListSkeleton();
    }

    if (state.error != null && state.punches.isEmpty) {
      return Center(
        child: CompactErrorWidget(
          error: state.error!,
          onRetry: () {
            ref
                .read(punchesControllerProvider.notifier)
                .loadPunches(reset: true);
          },
        ),
      );
    }

    if (state.punches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 77),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay registros',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 153),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.punches.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == state.punches.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: state.isLoading
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: () {
                        ref
                            .read(punchesControllerProvider.notifier)
                            .loadPunches();
                      },
                      child: const Text('Cargar más'),
                    ),
            ),
          );
        }

        final punch = state.punches[index];
        return _PunchListItem(punch: punch);
      },
    );
  }
}

class _PunchListSkeleton extends StatelessWidget {
  const _PunchListSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget skeletonLine({double w = double.infinity}) {
      return Container(
        height: 12,
        width: w,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      skeletonLine(w: 140),
                      const SizedBox(height: 10),
                      skeletonLine(w: 200),
                      const SizedBox(height: 10),
                      skeletonLine(w: 260),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PunchListItem extends ConsumerWidget {
  final PunchRecord punch;

  const _PunchListItem({required this.punch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final isAdmin =
        auth is AuthAuthenticated &&
        (auth.user.role == 'admin' || auth.user.role == 'administrador');

    final canEditOrDelete =
        punch.syncStatus == SyncStatus.synced && !punch.id.startsWith('local-');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) =>
                PunchDetailDialog(punch: punch, isAdmin: isAdmin),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildTypeIcon(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getTypeLabel(punch.type),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (punch.isManualEdit)
                          Chip(
                            label: const Text(
                              'Editado',
                              style: TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.orange.withValues(alpha: 51),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(punch.datetimeUtc),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 153),
                      ),
                    ),
                    if (punch.locationLat != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 153),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                punch.addressText ?? 'Ubicación registrada',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withValues(alpha: 153),
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSyncBadge(context),
                  const SizedBox(height: 8),
                  if (isAdmin)
                    PopupMenuButton<String>(
                      tooltip: 'Opciones',
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18),
                              SizedBox(width: 10),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (!canEditOrDelete) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Primero sincroniza este registro para editar/eliminar.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        if (value == 'edit') {
                          final updates = await _showEditDialog(
                            context,
                            isAdmin: isAdmin,
                          );
                          if (!context.mounted) return;
                          if (updates == null) return;

                          try {
                            final repo = ref.read(punchRepositoryProvider);
                            await repo.updatePunch(punch.id, updates);
                            ref
                                .read(punchesControllerProvider.notifier)
                                .loadPunches(reset: true);
                            ref.invalidate(todaySummaryProvider);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Registro actualizado'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No se pudo editar: $e'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }

                        if (value == 'delete') {
                          final ok = await _confirmDelete(context);
                          if (!context.mounted) return;
                          if (ok != true) return;
                          try {
                            final repo = ref.read(punchRepositoryProvider);
                            await repo.deletePunch(punch.id);
                            ref
                                .read(punchesControllerProvider.notifier)
                                .loadPunches(reset: true);
                            ref.invalidate(todaySummaryProvider);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Registro eliminado'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No se pudo eliminar: $e'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.more_vert, size: 18),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showEditDialog(
    BuildContext context, {
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
                              child: Text(_getTypeLabel(t)),
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
                        subtitle: Text(_formatDateTime(selectedUtc)),
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

  String _getTypeLabel(PunchType type) {
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

  Widget _buildTypeIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (punch.type) {
      case PunchType.in_:
        icon = Icons.login;
        color = Colors.green;
        break;
      case PunchType.lunchStart:
        icon = Icons.lunch_dining;
        color = Colors.orange;
        break;
      case PunchType.lunchEnd:
        icon = Icons.restaurant;
        color = Colors.blue;
        break;
      case PunchType.out:
        icon = Icons.logout;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildSyncBadge(BuildContext context) {
    IconData icon;
    Color color;
    String tooltip;

    switch (punch.syncStatus) {
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        color = Colors.green;
        tooltip = 'Sincronizado';
        break;
      case SyncStatus.pending:
        icon = Icons.cloud_upload;
        color = Colors.orange;
        tooltip = 'Pendiente de sincronizar';
        break;
      case SyncStatus.failed:
        icon = Icons.cloud_off;
        color = Colors.red;
        tooltip =
            'Error de sincronización (presiona Actualizar para reintentar)';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}/${dt.year}';
  }
}
