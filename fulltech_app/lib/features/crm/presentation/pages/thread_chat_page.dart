import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/module_page.dart';
import '../../data/models/crm_thread.dart';
import '../../state/crm_providers.dart';
import '../../constants/crm_statuses.dart';
import '../widgets/chat_thread_view.dart';
import '../widgets/right_panel_crm.dart';

class ThreadChatPage extends ConsumerStatefulWidget {
  final String threadId;

  const ThreadChatPage({super.key, required this.threadId});

  @override
  ConsumerState<ThreadChatPage> createState() => _ThreadChatPageState();
}

class _ThreadChatPageState extends ConsumerState<ThreadChatPage> {
  void _exitChat(BuildContext context) {
    ref.read(selectedThreadIdProvider.notifier).state = null;
    context.go(AppRoutes.crm);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedThreadIdProvider.notifier).state = widget.threadId;
    });
  }

  @override
  void didUpdateWidget(covariant ThreadChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.threadId != widget.threadId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedThreadIdProvider.notifier).state = widget.threadId;
      });
    }
  }

  @override
  void dispose() {
    final selectedId = ref.read(selectedThreadIdProvider);
    if (selectedId == widget.threadId) {
      ref.read(selectedThreadIdProvider.notifier).state = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final threadsState = ref.watch(crmThreadsControllerProvider);
    CrmThread? thread;
    for (final t in threadsState.items) {
      if (t.id == widget.threadId) {
        thread = t;
        break;
      }
    }
    final isPostSale = thread != null && CrmStatuses.isPostSaleStatus(thread.status);

    return ModulePage(
      title: isPostSale ? 'Postventa' : 'Chat',
      actions: [
        IconButton(
          tooltip: 'Volver',
          onPressed: () => _exitChat(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      child: Column(
        children: [
          Expanded(child: ChatThreadView(threadId: widget.threadId)),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: RightPanelCrm(threadId: widget.threadId),
          ),
        ],
      ),
    );
  }
}
