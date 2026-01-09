import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AgendaItem {
  final String id;
  final String type; // 'servicio' or 'garantia'
  final DateTime fecha;
  final String hora;
  final String titulo;
  final String? ubicacion;
  final String? tecnico;
  final String status;
  final String threadId;
  final String? notas;

  AgendaItem({
    required this.id,
    required this.type,
    required this.fecha,
    required this.hora,
    required this.titulo,
    this.ubicacion,
    this.tecnico,
    required this.status,
    required this.threadId,
    this.notas,
  });

  factory AgendaItem.fromServiceAgenda(Map<String, dynamic> json) {
    return AgendaItem(
      id: json['id'] as String,
      type: 'servicio',
      fecha: DateTime.parse(json['fecha_servicio'] as String),
      hora: json['hora_servicio'] as String,
      titulo: json['tipo_servicio'] as String,
      ubicacion: json['ubicacion'] as String?,
      tecnico: json['tecnico_asignado'] as String?,
      status: json['status'] as String,
      threadId: json['thread_id'] as String,
      notas: json['notas_adicionales'] as String?,
    );
  }

  factory AgendaItem.fromWarrantySolution(Map<String, dynamic> json) {
    return AgendaItem(
      id: json['id'] as String,
      type: 'garantia',
      fecha: DateTime.parse(json['fecha_solucion'] as String),
      hora: '09:00', // Default hour for warranty solutions
      titulo: 'Solución de garantía',
      ubicacion: null,
      tecnico: json['tecnico_responsable'] as String?,
      status: 'programado',
      threadId: json['thread_id'] as String,
      notas: json['solucion_aplicada'] as String,
    );
  }
}

// Provider to fetch agenda items
final agendaItemsProvider = FutureProvider.autoDispose<List<AgendaItem>>((ref) async {
  // TODO: Implement when backend tables are ready
  // For now, return empty list
  return <AgendaItem>[];
});

class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  String _filterType = 'todos'; // todos, servicio, garantia
  String _filterStatus = 'todos'; // todos, programado, completado, cancelado

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agendaAsync = ref.watch(agendaItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Operaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(agendaItemsProvider),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _filterType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'todos', child: Text('Todos')),
                        DropdownMenuItem(value: 'servicio', child: Text('Servicios')),
                        DropdownMenuItem(value: 'garantia', child: Text('Garantías')),
                      ],
                      onChanged: (v) => setState(() => _filterType = v ?? 'todos'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _filterStatus,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'todos', child: Text('Todos')),
                        DropdownMenuItem(value: 'programado', child: Text('Programado')),
                        DropdownMenuItem(value: 'completado', child: Text('Completado')),
                        DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
                      ],
                      onChanged: (v) => setState(() => _filterStatus = v ?? 'todos'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Items list
          Expanded(
            child: agendaAsync.when(
              data: (items) {
                // Apply filters
                var filtered = items;
                if (_filterType != 'todos') {
                  filtered = filtered.where((item) => item.type == _filterType).toList();
                }
                if (_filterStatus != 'todos') {
                  filtered = filtered.where((item) => item.status == _filterStatus).toList();
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No hay elementos en la agenda'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _AgendaItemCard(item: item);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Error al cargar la agenda: $err',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaItemCard extends StatelessWidget {
  final AgendaItem item;

  const _AgendaItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd/MM/yyyy');

    IconData iconData;
    Color iconColor;
    switch (item.type) {
      case 'servicio':
        iconData = Icons.build;
        iconColor = Colors.blue;
        break;
      case 'garantia':
        iconData = Icons.verified_user;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.event;
        iconColor = Colors.grey;
    }

    Color statusColor;
    switch (item.status) {
      case 'programado':
        statusColor = Colors.green;
        break;
      case 'completado':
        statusColor = Colors.grey;
        break;
      case 'cancelado':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          item.titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${dateFormatter.format(item.fecha)} a las ${item.hora}'),
              ],
            ),
            if (item.ubicacion != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(child: Text(item.ubicacion!, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
            if (item.tecnico != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(item.tecnico!),
                ],
              ),
            ],
          ],
        ),
        trailing: Chip(
          label: Text(
            item.status.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: statusColor.withOpacity(0.1),
          side: BorderSide.none,
        ),
        onTap: () {
          // TODO: Navigate to detail view or chat thread
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ver detalles de: ${item.titulo}')),
          );
        },
      ),
    );
  }
}
