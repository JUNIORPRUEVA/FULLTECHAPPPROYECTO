import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/module_page.dart';
import '../../providers/maintenance_provider.dart';
import '../dialogs/create_audit_dialog.dart';
import '../dialogs/create_maintenance_dialog.dart';
import '../dialogs/create_warranty_dialog.dart';
import '../widgets/maintenance_list_view.dart';
import '../widgets/warranty_list_view.dart';
import '../widgets/audits_list_view.dart';
import '../widgets/summary_panel.dart';

class MaintenancePage extends ConsumerStatefulWidget {
  const MaintenancePage({super.key});

  @override
  ConsumerState<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends ConsumerState<MaintenancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(maintenanceControllerProvider.notifier)
          .loadMaintenance(reset: true);
      ref.read(warrantyControllerProvider.notifier).loadWarranty(reset: true);
      ref.read(auditsControllerProvider.notifier).loadAudits(reset: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Mantenimiento & Garantía',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () {
            ref
                .read(maintenanceControllerProvider.notifier)
                .loadMaintenance(reset: true);
            ref
                .read(warrantyControllerProvider.notifier)
                .loadWarranty(reset: true);
            ref.read(auditsControllerProvider.notifier).loadAudits(reset: true);
          },
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _openCreateForCurrentTab,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 1000;

          final list = Column(
            children: [
              _buildTabsSelector(),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      MaintenanceListView(),
                      WarrantyListView(),
                      AuditsListView(),
                    ],
                  ),
                ),
              ),
            ],
          );

          final summary = Card(
            clipBehavior: Clip.antiAlias,
            child: const SummaryPanel(),
          );

          if (!wide) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: const SummaryPanel(compact: true),
                  ),
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
              SizedBox(width: 360, child: summary),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabsSelector() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(icon: Icon(Icons.build_outlined), text: 'Mantenimiento'),
              Tab(icon: Icon(Icons.verified_user_outlined), text: 'Garantías'),
              Tab(icon: Icon(Icons.inventory_outlined), text: 'Auditorías'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateForCurrentTab() async {
    final tab = _tabController.index;
    final Widget dialog;
    if (tab == 0) {
      dialog = const CreateMaintenanceDialog();
    } else if (tab == 1) {
      dialog = const CreateWarrantyDialog();
    } else {
      dialog = const CreateAuditDialog();
    }

    await showDialog<bool>(context: context, builder: (_) => dialog);
  }
}
