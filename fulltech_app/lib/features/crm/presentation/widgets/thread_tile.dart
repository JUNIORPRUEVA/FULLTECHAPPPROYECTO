import 'package:flutter/material.dart';

import '../../data/models/crm_thread.dart';

class ThreadTile extends StatelessWidget {
  final CrmThread thread;
  final bool selected;
  final VoidCallback onTap;

  const ThreadTile({
    super.key,
    required this.thread,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title =
        (thread.displayName != null && thread.displayName!.trim().isNotEmpty)
        ? thread.displayName!.trim()
        : (thread.phone ?? thread.waId);

    final subtitle = (thread.lastMessagePreview ?? '').trim();
    final phone = (thread.phone ?? '').trim();
    final waId = thread.waId.trim();
    final primaryId = phone.isNotEmpty ? phone : waId;

    return ListTile(
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
      onTap: onTap,
      leading: CircleAvatar(
        child: Text(title.isNotEmpty ? title[0].toUpperCase() : '?'),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(primaryId, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (phone.isNotEmpty)
            Text(
              waId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          if (subtitle.isNotEmpty)
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: thread.lastMessageAt != null
          ? Text(
              _dateTimeCompact(thread.lastMessageAt!),
              style: theme.textTheme.labelSmall,
            )
          : null,
    );
  }

  static String _dateTimeCompact(DateTime dt) {
    final now = DateTime.now();
    final sameDay =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;
    if (sameDay) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$d/$mo';
  }
}
