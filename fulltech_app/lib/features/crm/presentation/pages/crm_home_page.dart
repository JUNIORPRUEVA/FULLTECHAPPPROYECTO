import 'package:flutter/material.dart';

import '../../../../core/widgets/module_page.dart';
import 'crm_chats_page.dart';
import 'crm_customers_page.dart';

class CrmHomePage extends StatelessWidget {
  const CrmHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePage(
      title: 'CRM',
      denseHeader: true,
      headerBottomSpacing: 8,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Chats'),
                  Tab(text: 'Clientes'),
                ],
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  CrmChatsPage(),
                  CrmCustomersPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
