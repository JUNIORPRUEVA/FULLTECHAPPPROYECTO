import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/crm_providers.dart';
import '../../../catalogo/models/producto.dart';

class CrmTopBar extends ConsumerStatefulWidget {
  final Widget? trailing;

  const CrmTopBar({super.key, this.trailing});

  static const double height = 60;

  @override
  ConsumerState<CrmTopBar> createState() => _CrmTopBarState();
}

class _CrmTopBarState extends ConsumerState<CrmTopBar> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(crmChatFiltersProvider);
    _searchCtrl = TextEditingController(text: filters.searchText);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(crmChatFiltersProvider);
    final filtersNotifier = ref.read(crmChatFiltersProvider.notifier);

    if (_searchCtrl.text != filters.searchText) {
      _searchCtrl.value = _searchCtrl.value.copyWith(
        text: filters.searchText,
        selection: TextSelection.collapsed(offset: filters.searchText.length),
        composing: TextRange.empty,
      );
    }

    final productsAsync = ref.watch(crmProductsProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: LayoutBuilder(
        builder: (context, c) {
          final isNarrow = c.maxWidth < 900;

          final searchField = TextField(
            controller: _searchCtrl,
            onChanged: filtersNotifier.setSearchText,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 20),
              hintText: 'Buscar…',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          );

          final productField = productsAsync.when(
            data: (items) => _ProductDropdown(
              items: items,
              value: filters.productId,
              onChanged: filtersNotifier.setProductId,
            ),
            loading: () => const SizedBox(
              height: 44,
              child: Center(child: LinearProgressIndicator()),
            ),
            error: (e, _) => InputDecorator(
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Producto',
              ),
              child: Text(
                'No disponible',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          );

          final statusField = DropdownButtonFormField<String>(
            value: filters.status,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                value: 'todos',
                child: Text(
                  'Todos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'pendiente',
                child: Text(
                  'Pendiente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'interesado',
                child: Text(
                  'Interesado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'reserva',
                child: Text(
                  'Reserva',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'compro',
                child: Text(
                  'Compró',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'no_interesado',
                child: Text(
                  'No interesado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'activo',
                child: Text(
                  'Activo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            onChanged: (v) => filtersNotifier.setStatus(v ?? 'todos'),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Estado',
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          );

          final clearBtn = IconButton.filledTonal(
            tooltip: 'Limpiar filtros',
            onPressed: () => filtersNotifier.clear(),
            icon: const Icon(Icons.filter_alt_off),
          );

          final trailing = widget.trailing;

          if (isNarrow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                searchField,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(flex: 4, child: productField),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: statusField),
                    const SizedBox(width: 4),
                    clearBtn,
                  ],
                ),
                if (trailing != null) ...[
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerRight, child: trailing),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 10, child: searchField),
              const SizedBox(width: 8),
              Expanded(flex: 5, child: productField),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: statusField),
              const SizedBox(width: 4),
              clearBtn,
              if (trailing != null) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: trailing,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProductDropdown extends StatelessWidget {
  final List<Producto> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ProductDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final active = items.where((p) => p.isActive).toList();

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      isDense: true,
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Todos')),
        ...active.map(
          (p) => DropdownMenuItem<String>(
            value: p.id,
            child: Text(
              p.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
      decoration: const InputDecoration(
        isDense: true,
        labelText: 'Producto',
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }
}
