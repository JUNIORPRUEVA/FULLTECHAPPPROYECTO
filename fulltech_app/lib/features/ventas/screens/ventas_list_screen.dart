import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_config.dart';
import '../../../core/widgets/module_page.dart';
import '../../auth/state/auth_providers.dart';
import '../../usuarios/state/users_providers.dart';
import '../models/sales_models.dart';
import '../state/ventas_providers.dart';
import '../widgets/sales_register_dialog.dart';

class VentasListScreen extends ConsumerStatefulWidget {
  const VentasListScreen({super.key});

  @override
  ConsumerState<VentasListScreen> createState() => _VentasListScreenState();
}

class _VentasListScreenState extends ConsumerState<VentasListScreen> {
  final _qCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;

  int _page = 1;
  final int _pageSize = 20;
  int _total = 0;

  DateTimeRange? _dateRange;

  List<SalesRecord> _items = const [];

  double _periodConfirmedAmount = 0;
  int _periodConfirmedCount = 0;
  num? _metaVentas;
  late final NumberFormat _money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

  static String _summaryForItems(List<SalesLineItem> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first.name;
    final first = items.first.name;
    final extra = items.length - 1;
    return '$first +$extra';
  }

  static double _totalForItems(List<SalesLineItem> items) {
    return items.fold<double>(0, (acc, it) => acc + it.total);
  }

  static String _publicBase() {
    final base = AppConfig.apiBaseUrl;
    return base.replaceFirst(RegExp(r'/api/?$'), '');
  }

  static String? _resolvePublicUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('/')) return '${_publicBase()}$trimmed';
    return '${_publicBase()}/$trimmed';
  }

  @override
  void initState() {
    super.initState();
    _load(page: 1);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qCtrl.dispose();
    super.dispose();
  }

  ({DateTime from, DateTime to, String label}) _currentBiweeklyPeriod(DateTime now) {
    final y = now.year;
    final m = now.month;
    final lastDay = DateTime(y, m + 1, 0).day;
    if (now.day <= 15) {
      final from = DateTime(y, m, 1);
      final to = DateTime(y, m, 15, 23, 59, 59);
      return (from: from, to: to, label: '1–15');
    }
    final from = DateTime(y, m, 16);
    final to = DateTime(y, m, lastDay, 23, 59, 59);
    return (from: from, to: to, label: '16–$lastDay');
  }

  Future<void> _load({required int page}) async {
    final session = await ref.read(localDbProvider).readSession();
    if (!mounted) return;
    if (session == null) {
      setState(() {
        _loading = false;
        _error = 'Sesión no encontrada. Inicia sesión de nuevo.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _page = page;
    });

    try {
      final repo = ref.read(salesRepositoryProvider);
      final empresaId = session.user.empresaId;

      // Load goal (best-effort)
      try {
        final me = await ref.read(usersApiProvider).getUser(session.user.id);
        _metaVentas = me.metaVentas;
      } catch (_) {
        // ignore
      }

      final result = await repo.listSalesOfflineFirst(
        empresaId: empresaId,
        page: page,
        pageSize: _pageSize,
        q: _qCtrl.text.trim().isEmpty ? null : _qCtrl.text.trim(),
        from: _dateRange?.start,
        to: _dateRange == null
            ? null
            : DateTime(
                _dateRange!.end.year,
                _dateRange!.end.month,
                _dateRange!.end.day,
                23,
                59,
                59,
              ),
      );

      // Period stats (all sales in current biweekly period)
      final period = _currentBiweeklyPeriod(DateTime.now());
      final periodConfirmed = await repo.listLocal(
        empresaId: empresaId,
        from: period.from,
        to: period.to,
        page: 1,
        pageSize: 100000,
      );
      final sum = periodConfirmed.fold<double>(
        0,
        (acc, it) => acc + (it.deleted ? 0 : it.amount),
      );

      if (!mounted) return;
      setState(() {
        _items = result.items;
        _total = result.total;
        _periodConfirmedAmount = sum;
        _periodConfirmedCount = periodConfirmed.where((e) => !e.deleted).length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openCreateDialog() async {
    final session = await ref.read(localDbProvider).readSession();
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión no encontrada. Inicia sesión de nuevo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final repo = ref.read(salesRepositoryProvider);

    final created = await showDialog<SalesRegisterDialogResult>(
      context: context,
      builder: (context) => const SalesRegisterDialog(title: 'Registrar venta'),
    );

    if (created == null || !mounted) return;

    try {
      await repo.createSaleLocalFirst(
        empresaId: session.user.empresaId,
        userId: session.user.id,
        items: created.items,
        productOrService: _summaryForItems(created.items),
        amount: _totalForItems(created.items),
        soldAt: created.soldAt,
        customerName: created.customer.fullName,
        customerPhone: created.customer.phone,
        customerDocument: null,
        notes: created.notes,
        evidenceRequired: true,
        evidences: created.evidences,
      );

      if (mounted) await _load(page: 1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar la venta: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEditDialog(SalesRecord record) async {
    final repo = ref.read(salesRepositoryProvider);

    final updated = await showDialog<SalesRegisterDialogResult>(
      context: context,
      builder: (context) => SalesRegisterDialog(title: 'Editar venta', existing: record),
    );

    if (updated == null || !mounted) return;

    try {
      await repo.updateSaleLocalFirst(
        existing: record,
        patch: {
          'customer_name': updated.customer.fullName,
          'customer_phone': updated.customer.phone,
          'customer_document': null,
          'product_or_service': _summaryForItems(updated.items),
          'details': {
            'items':
                updated.items.map((e) => e.toJson()).toList(growable: false),
          },
          'amount': _totalForItems(updated.items),
          'sold_at': updated.soldAt.toIso8601String(),
          'notes': updated.notes,
        },
      );

      if (mounted) await _load(page: _page);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar la venta: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(SalesRecord record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: const Text('¿Deseas eliminar esta venta?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (ok != true) return;

    final repo = ref.read(salesRepositoryProvider);
    try {
      await repo.deleteSaleLocalFirst(id: record.id);
      if (mounted) await _load(page: _page);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar la venta: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEvidenceDialog(SalesRecord record) async {
    final repo = ref.read(salesRepositoryProvider);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Evidencias'),
          content: SizedBox(
            width: 560,
            child: FutureBuilder<List<SalesEvidence>>(
              future: repo.listEvidenceLocal(record.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Error cargando evidencias: ${snap.error}'),
                  );
                }

                final items = (snap.data ?? const <SalesEvidence>[])
                    .toList(growable: false)
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No hay evidencias registradas.'),
                  );
                }

                IconData iconFor(String t) {
                  switch (t) {
                    case SalesEvidenceType.image:
                      return Icons.image_outlined;
                    case SalesEvidenceType.pdf:
                      return Icons.picture_as_pdf_outlined;
                    case SalesEvidenceType.link:
                      return Icons.link;
                    case SalesEvidenceType.text:
                      return Icons.notes_outlined;
                    default:
                      return Icons.attach_file;
                  }
                }

                String titleFor(SalesEvidence e) {
                  if (e.type == SalesEvidenceType.text) return 'Texto';
                  if (e.type == SalesEvidenceType.link) return 'Enlace';
                  final v = e.urlOrPath;
                  if (v.startsWith('local://')) return 'Archivo (pendiente)';
                  final url = _resolvePublicUrl(v) ?? v;
                  try {
                    final uri = Uri.parse(url);
                    if (uri.pathSegments.isNotEmpty) {
                      return uri.pathSegments.last;
                    }
                  } catch (_) {
                    // ignore
                  }
                  final idx = url.lastIndexOf('/');
                  return idx >= 0 ? url.substring(idx + 1) : url;
                }

                Future<void> openEvidence(SalesEvidence e) async {
                  if (!context.mounted) return;

                  if (e.type == SalesEvidenceType.text) {
                    await showDialog<void>(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          title: const Text('Evidencia (texto)'),
                          content: SizedBox(
                            width: 560,
                            child: SelectableText(e.urlOrPath),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }

                  if (e.urlOrPath.startsWith('local://')) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Evidencia pendiente de subir (sincroniza primero).'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final raw = e.urlOrPath;
                  final resolved = _resolvePublicUrl(raw) ?? raw;
                  final uri = Uri.tryParse(resolved);
                  if (uri == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL inválida.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo abrir la evidencia.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final subtitle =
                        '${DateFormat('yyyy-MM-dd HH:mm').format(e.createdAt)} • ${e.syncStatus}';
                    return ListTile(
                      leading: Icon(iconFor(e.type)),
                      title: Text(titleFor(e), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => openEvidence(e),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Buscar… (cliente, producto, notas)',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 400), () {
                      if (!mounted) return;
                      _load(page: 1);
                    });
                  },
                  onSubmitted: (_) => _load(page: 1),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => _load(page: 1),
                child: const Text('Buscar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;
              final rangeField = InputDecorator(
                decoration: const InputDecoration(labelText: 'Rango de fechas'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dateRange == null
                            ? 'Todas'
                            : '${DateFormat('yyyy-MM-dd').format(_dateRange!.start)} → ${DateFormat('yyyy-MM-dd').format(_dateRange!.end)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(DateTime.now().year - 2),
                          lastDate: DateTime(DateTime.now().year + 1),
                          initialDateRange: _dateRange,
                        );
                        if (!mounted) return;
                        if (picked != null) {
                          setState(() => _dateRange = picked);
                          if (mounted) _load(page: 1);
                        }
                      },
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
              );

              final clearButton = OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _qCtrl.text = '';
                    _dateRange = null;
                  });
                  _load(page: 1);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar'),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    rangeField,
                    const SizedBox(height: 12),
                    clearButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: rangeField),
                  const SizedBox(width: 12),
                  clearButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_items.isEmpty) return const Center(child: Text('Sin ventas'));

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final it = _items[index];
        final title = it.customerName?.trim().isNotEmpty == true ? it.customerName! : it.productOrService;
        final subtitleParts = <String>[
          DateFormat('yyyy-MM-dd').format(it.soldAt),
          if (it.items.isNotEmpty) '${it.items.length} productos' else if (it.productOrService.trim().isNotEmpty) it.productOrService,
          if (it.syncStatus == SyncStatus.error) 'Error de sync',
        ];
        final subtitle = subtitleParts.where((s) => s.trim().isNotEmpty).join(' • ');

        return ListTile(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          leading: CircleAvatar(
            child: Text(
              (title.isNotEmpty ? title.substring(0, 1) : 'V').toUpperCase(),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money.format(it.amount),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Evidencias: ${it.evidenceCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Ver evidencias',
                onPressed: () => _openEvidenceDialog(it),
                icon: const Icon(Icons.attach_file),
              ),
            ],
          ),
          onTap: () => _openEditDialog(it),
          onLongPress: () => _confirmDelete(it),
          selected: it.syncStatus == SyncStatus.error,
          selectedColor: Theme.of(context).colorScheme.error,
        );
      },
    );
  }

  Widget _buildPagination() {
    final start = _total == 0 ? 0 : ((_page - 1) * _pageSize + 1);
    final end = ((_page - 1) * _pageSize + _items.length);
    final canPrev = _page > 1;
    final canNext = end < _total;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: Text('Mostrando $start–$end de $_total')),
          IconButton(
            tooltip: 'Anterior',
            onPressed: canPrev ? () => _load(page: _page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Siguiente',
            onPressed: canNext ? () => _load(page: _page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel() {
    final period = _currentBiweeklyPeriod(DateTime.now());
    final goal = (_metaVentas is num) ? (_metaVentas as num).toDouble() : null;
    final progress = (goal == null || goal <= 0)
      ? null
      : (_periodConfirmedAmount / goal).clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Quincena ${period.label}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Ventas (quincena)')),
                Text(_periodConfirmedCount.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: Text('Monto')),
                Text(_money.format(_periodConfirmedAmount), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(child: Text('Meta (quincenal)')),
                Text(goal == null ? '—' : _money.format(goal)),
              ],
            ),
            const SizedBox(height: 8),
            if (progress != null) ...[
              _GoalFunnel(progress: progress),
              const SizedBox(height: 6),
              Text('${(progress * 100).toStringAsFixed(0)}% de la meta'),
            ] else
              Text(
                'Meta no configurada para este usuario.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Ventas',
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: () => _load(page: _page),
          icon: const Icon(Icons.refresh),
        ),
        FilledButton.icon(
          onPressed: _openCreateDialog,
          icon: const Icon(Icons.add),
          label: const Text('Nueva'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 1000;
          final list = Column(
            children: [
              _buildFilters(),
              Expanded(child: Card(child: _buildList())),
              _buildPagination(),
            ],
          );

          if (!wide) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildStatsPanel(),
                ),
                const SizedBox(height: 8),
                Expanded(child: list),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: list),
              const SizedBox(width: 12),
              SizedBox(width: 360, child: _buildStatsPanel()),
            ],
          );
        },
      ),
    );
  }
}

class _GoalFunnel extends StatelessWidget {
  final double progress;

  const _GoalFunnel({required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 74,
      child: CustomPaint(
        painter: _GoalFunnelPainter(
          progress: progress,
          fillColor: cs.primary,
          borderColor: cs.outlineVariant,
          backgroundColor: cs.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _GoalFunnelPainter extends CustomPainter {
  final double progress;
  final Color fillColor;
  final Color borderColor;
  final Color backgroundColor;

  const _GoalFunnelPainter({
    required this.progress,
    required this.fillColor,
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);

    final topW = size.width;
    final bottomW = size.width * 0.55;
    final topLeft = Offset(0, 0);
    final topRight = Offset(topW, 0);
    final bottomLeft = Offset((topW - bottomW) / 2, size.height);
    final bottomRight = Offset((topW + bottomW) / 2, size.height);

    final outline = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(outline, bgPaint);

    // Fill from bottom to top.
    final fillHeight = size.height * p;
    final fillTopY = size.height - fillHeight;

    // Linear interpolation of trapezoid width at a given Y.
    double widthAt(double y) {
      final t = (y / size.height).clamp(0.0, 1.0);
      return topW + (bottomW - topW) * t;
    }

    final wTop = widthAt(fillTopY);
    final leftTop = (topW - wTop) / 2;
    final rightTop = leftTop + wTop;

    final fill = Path()
      ..moveTo(leftTop, fillTopY)
      ..lineTo(rightTop, fillTopY)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fill, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(outline, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _GoalFunnelPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
