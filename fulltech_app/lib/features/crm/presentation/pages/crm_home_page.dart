import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/module_page.dart';
import 'crm_chats_page.dart';
import 'crm_customers_page_enhanced.dart';
import '../widgets/crm_top_bar.dart';
import '../widgets/evolution_config_dialog.dart';
import '../../state/crm_providers.dart';

class CrmHomePage extends ConsumerWidget {
  const CrmHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the realtime stream alive while CRM is open.
    ref.watch(crmRealtimeProvider);

    return ModulePage(
      title: '',
      denseHeader: true,
      headerBottomSpacing: 0,
      child: DefaultTabController(
        length: 2,
        child: Builder(
          builder: (context) {
            final controller = DefaultTabController.of(context);
            final tabs = _CrmTabs(controller: controller);

            return Column(
              children: [
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final isChats = controller.index == 0;
                    if (isChats) {
                      return CrmTopBar(trailing: tabs);
                    }
                    return _TabsOnlyBar(child: tabs);
                  },
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: TabBarView(
                    children: [
                      const CrmChatsPage(),
                      const CrmCustomersPageEnhanced(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CrmTabs extends StatelessWidget {
  final TabController controller;

  const _CrmTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnChats = controller.index == 0;

    return Row(
      children: [
        Expanded(
          child: TabBar(
            controller: controller,
            isScrollable: true,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
            unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
            labelColor: theme.colorScheme.onSurface,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0,
            indicator: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            tabs: const [
              Tab(text: 'CHATS'),
              Tab(text: 'CLIENTES'),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: () {
            if (isOnChats) {
              context.go('${AppRoutes.customers}?onlyActive=1');
              return;
            }
            controller.animateTo(0);
          },
          icon: Icon(isOnChats ? Icons.people : Icons.chat_bubble, size: 18),
          label: Text(isOnChats ? 'Ir a Clientes' : 'Ir a Chats'),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Configuración Evolution/WhatsApp',
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const EvolutionConfigDialog(),
            );
          },
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }
}

class _TabsOnlyBar extends StatelessWidget {
  final Widget child;

  const _TabsOnlyBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [const Spacer(), child]),
    );
  }
}
