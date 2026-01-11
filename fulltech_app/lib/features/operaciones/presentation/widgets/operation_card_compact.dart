import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_routes.dart';
import '../../models/operations_models.dart';
import '../../state/operations_providers.dart';

/// Compact operation card with:
/// - Line 1: Name + Phone + Type
/// - Line 2: Date + Tech + Address/note
/// - Corporate dark blue badge for status
/// - Quick action buttons for status changes
class OperationCardCompact extends ConsumerWidget {
  final OperationsJob job;
  final String? technicianName;
  final bool canMutate;
  final bool canOfficeActions;
  final bool canTechActions;
  final VoidCallback onRefresh;

  const OperationCardCompact({
    super.key,
    required this.job,
    this.technicianName,
    required this.canMutate,
    required this.canOfficeActions,
    required this.canTechActions,
    required this.onRefresh,
  });

  Color _estadoColor(BuildContext context, String estado) {
    final cs = Theme.of(context).colorScheme;
    final e = estado.trim().toUpperCase();
    if (e == 'CANCELADO') return cs.error;
    if (e == 'FINALIZADO' || e == 'CERRADO') return Colors.green.shade700;
    // Corporate dark blue for active states
    return const Color(0xFF0D47A1);
  }

  String _estadoLabel(String estado) {
    switch (estado.trim().toUpperCase()) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'PROGRAMADO':
        return 'Programado';
      case 'EN_EJECUCION':
        return 'En ejecución';
      case 'FINALIZADO':
        return 'Finalizado';
      case 'CERRADO':
        return 'Cerrado';
      case 'CANCELADO':
        return 'Cancelado';
      case 'EN_GARANTIA':
        return 'En garantía';
      case 'SOLUCION_GARANTIA':
        return 'Solución garantía';
      default:
        return estado;
    }
  }

  String _typeLabel(OperationsJob job) {
    final tipo = job.tipoTrabajo.trim().toUpperCase();
    switch (tipo) {
      case 'LEVANTAMIENTO':
        return 'Levantamiento';
      case 'GARANTIA':
        return 'Garantía';
      case 'MANTENIMIENTO':
        return 'Mantenimiento';
      case 'INSTALACION':
      default:
        return 'Instalación';
    }
  }

  String _formatTime(DateTime? dt, String? preferredTime) {
    if (dt == null) return '';
    final today = DateTime.now();
    final jobDay = DateTime(dt.year, dt.month, dt.day);
    final todayDay = DateTime(today.year, today.month, today.day);

    String dateStr;
    if (jobDay == todayDay) {
      dateStr = 'Hoy';
    } else if (jobDay == todayDay.add(const Duration(days: 1))) {
      dateStr = 'Mañana';
    } else {
      dateStr = DateFormat('dd/MM').format(dt);
    }

    if (preferredTime != null && preferredTime.trim().isNotEmpty) {
      return '$dateStr $preferredTime';
    }
    return dateStr;
  }

  Future<void> _changeEstado(
    BuildContext context,
    WidgetRef ref,
    String newEstado, {
    bool requireNote = false,
    String noteTitle = 'Nota',
    String noteLabel = 'Nota *',
  }) async {
    String? note;
    if (requireNote) {
      note = await _promptRequiredText(
        context: context,
        title: noteTitle,
        label: noteLabel,
      );
      if (note == null) return;
    }

    try {
      final repo = ref.read(operationsRepositoryProvider);
      await repo.patchOperacionEstado(
        jobId: job.id,
        estado: newEstado,
        note: note ?? 'Cambio de estado',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a ${_estadoLabel(newEstado)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
      onRefresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<String?> _promptRequiredText({
    required BuildContext context,
    required String title,
    required String label,
  }) async {
    final ctrl = TextEditingController();
    String? error;
    final res = await showDialog<String?>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 520,
              child: TextField(
                controller: ctrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: label,
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(null),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final v = ctrl.text.trim();
                  if (v.isEmpty) {
                    setState(() => error = 'Este campo es requerido');
                    return;
                  }
                  Navigator.of(dialogCtx).pop(v);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
    ctrl.dispose();
    return res;
  }

  Future<void> _showEstadoPickerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final estados = const [
      'PROGRAMADO',
      'EN_EJECUCION',
      'FINALIZADO',
      'CERRADO',
      'CANCELADO',
      'EN_GARANTIA',
      'SOLUCION_GARANTIA',
    ];

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cambiar estado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Estado actual: ${_estadoLabel(job.estado)}'),
              const SizedBox(height: 16),
              ...estados.map((e) {
                return ListTile(
                  title: Text(_estadoLabel(e)),
                  onTap: () {
                    Navigator.of(dialogCtx).pop();
                    if (e == 'FINALIZADO') {
                      _changeEstado(
                        context,
                        ref,
                        e,
                        requireNote: true,
                        noteTitle: 'Finalizar',
                        noteLabel: 'Resumen / resultado *',
                      );
                    } else if (e == 'CANCELADO') {
                      _changeEstado(
                        context,
                        ref,
                        e,
                        requireNote: true,
                        noteTitle: 'Cancelar',
                        noteLabel: 'Motivo de cancelación *',
                      );
                    } else {
                      _changeEstado(context, ref, e);
                    }
                  },
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final estadoColor = _estadoColor(context, job.estado);
    final typeLabel = _typeLabel(job);
    final timeStr = _formatTime(job.scheduledDate, job.preferredTime);

    // Line 1: Name • Phone • Type
    final line1Parts = <String>[];
    line1Parts.add(
      job.customerName.trim().isNotEmpty ? job.customerName.trim() : 'Cliente',
    );
    if (job.customerPhone != null && job.customerPhone!.trim().isNotEmpty) {
      line1Parts.add(job.customerPhone!.trim());
    }
    line1Parts.add(typeLabel);

    // Line 2: Date • Tech • Address/note
    final line2Parts = <String>[];
    if (timeStr.isNotEmpty) {
      line2Parts.add(timeStr);
    }
    if (technicianName != null && technicianName!.isNotEmpty) {
      line2Parts.add('Téc: $technicianName');
    }
    if (job.customerAddress != null && job.customerAddress!.trim().isNotEmpty) {
      line2Parts.add('Dir: ${job.customerAddress!.trim()}');
    } else if (job.notes != null && job.notes!.trim().isNotEmpty) {
      line2Parts.add('Nota: ${job.notes!.trim()}');
    }

    final currentEstado = job.estado.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go(AppRoutes.operacionesDetail(job.id)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Left: Compact 2-line info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Line 1 (bold, primary info)
                        Text(
                          line1Parts.join(' • '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Line 2 (secondary info)
                        Text(
                          line2Parts.join(' • '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Right: Status badge + action buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Corporate dark blue status badge (white text, bold)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: estadoColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _estadoLabel(job.estado),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Quick action buttons row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Always show "Change State" button
                          SizedBox(
                            height: 28,
                            child: OutlinedButton(
                              onPressed: canMutate
                                  ? () => _showEstadoPickerDialog(context, ref)
                                  : null,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text(
                                'Cambiar',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Context-specific quick action
                          if (currentEstado == 'PROGRAMADO' && canTechActions)
                            SizedBox(
                              height: 28,
                              child: FilledButton(
                                onPressed: () =>
                                    _changeEstado(context, ref, 'EN_EJECUCION'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: estadoColor,
                                ),
                                child: const Text(
                                  'Iniciar',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),

                          if (currentEstado == 'EN_EJECUCION' && canTechActions)
                            SizedBox(
                              height: 28,
                              child: FilledButton(
                                onPressed: () => _changeEstado(
                                  context,
                                  ref,
                                  'FINALIZADO',
                                  requireNote: true,
                                  noteTitle: 'Finalizar',
                                  noteLabel: 'Resumen / resultado *',
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: estadoColor,
                                ),
                                child: const Text(
                                  'Finalizar',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),

                          if (currentEstado == 'FINALIZADO' && canOfficeActions)
                            SizedBox(
                              height: 28,
                              child: FilledButton(
                                onPressed: () =>
                                    _changeEstado(context, ref, 'CERRADO'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: estadoColor,
                                ),
                                child: const Text(
                                  'Cerrar',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),

                          // Cancel button (always available if not already closed/canceled)
                          if (currentEstado != 'CANCELADO' &&
                              currentEstado != 'CERRADO' &&
                              canTechActions)
                            SizedBox(
                              height: 28,
                              width: 28,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _changeEstado(
                                  context,
                                  ref,
                                  'CANCELADO',
                                  requireNote: true,
                                  noteTitle: 'Cancelar',
                                  noteLabel: 'Motivo de cancelación *',
                                ),
                                icon: Icon(
                                  Icons.cancel_outlined,
                                  size: 18,
                                  color: theme.colorScheme.error,
                                ),
                                tooltip: 'Cancelar',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Additional details row (address, notes, actions)
              if (job.customerAddress != null &&
                      job.customerAddress!.trim().isNotEmpty ||
                  job.notes != null && job.notes!.trim().isNotEmpty ||
                  job.crmChatId != null &&
                      job.crmChatId!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (job.customerAddress != null &&
                              job.customerAddress!.trim().isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    job.customerAddress!.trim(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (job.notes != null && job.notes!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.note_outlined,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      job.notes!.trim(),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontSize: 11,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
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
                    if (job.crmChatId != null &&
                        job.crmChatId!.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 28,
                        child: OutlinedButton.icon(
                          onPressed: () => context.go(
                            '${AppRoutes.crm}/chats/${job.crmChatId}',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 14),
                          label: const Text(
                            'Chat',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            context.go(AppRoutes.operacionesDetail(job.id)),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        tooltip: 'Ver detalles',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
