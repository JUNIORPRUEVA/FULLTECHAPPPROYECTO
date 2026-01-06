import 'package:flutter/material.dart';

import '../../data/models/crm_thread.dart';

class ChatListItemPro extends StatelessWidget {
  final CrmThread thread;
  final bool isSelected;
  final VoidCallback onTap;
  final DateTime now;

  const ChatListItemPro({
    super.key,
    required this.thread,
    required this.isSelected,
    required this.onTap,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Display name fallback
    final displayName = (thread.displayName ?? '').trim().isNotEmpty
        ? thread.displayName!.trim()
        : thread.phone ?? 'Sin nombre';

    // Profile photo logic (not available in CrmThread yet).
    final String? profilePhotoUrl = null;

    // Format last message
    final lastMessageDisplay = _formatLastMessage();

    // Format date/time
    final timeStr = _formatChatTime();

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.08)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Avatar with unread badge and important badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    profilePhotoUrl != null
                        ? CircleAvatar(
                            radius: 22,
                            backgroundImage: NetworkImage(profilePhotoUrl),
                            backgroundColor: theme.colorScheme.surfaceVariant,
                          )
                        : CircleAvatar(
                            radius: 22,
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.18),
                            child: Text(
                              _getInitials(displayName),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                    if (thread.important)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (thread.unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Text(
                            thread.unreadCount > 99
                                ? '99+'
                                : thread.unreadCount.toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Center content (expanded)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + optional status chip
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (thread.status.isNotEmpty &&
                              thread.status != 'activo')
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _StatusChipMini(status: thread.status),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Phone number (if not shown as name)
                      if ((thread.displayName ?? '').trim().isEmpty &&
                          thread.phone != null &&
                          thread.phone!.isNotEmpty)
                        Text(
                          thread.phone!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),

                      const SizedBox(height: 3),

                      // Last message preview
                      Text(
                        lastMessageDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: thread.unreadCount > 0
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: thread.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right column: time + indicators
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Time
                    Text(
                      timeStr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: thread.unreadCount > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: thread.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Status indicators
                    if (thread.unreadCount == 0 && thread.lastMessageFromMe)
                      Text(
                        _getMessageStatus(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: thread.lastMessageStatus == 'read'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format last message with type indicator
  String _formatLastMessage() {
    final text = (thread.lastMessagePreview ?? '').trim();

    if (text.isEmpty) {
      return thread.lastMessageType != null && thread.lastMessageType != 'text'
          ? _getMediaLabel(thread.lastMessageType!)
          : '(Sin mensajes)';
    }

    // Add media prefix if applicable
    if (thread.lastMessageType != null && thread.lastMessageType != 'text') {
      final mediaLabel = _getMediaLabel(thread.lastMessageType!);
      return '$mediaLabel $text';
    }

    return text;
  }

  String _getMediaLabel(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return '🎤';
      case 'image':
        return '🖼️';
      case 'video':
        return '🎥';
      case 'document':
        return '📄';
      default:
        return '📎';
    }
  }

  /// Format date/time: today => HH:mm, else dd/MM or dd Mmm
  String _formatChatTime() {
    if (thread.lastMessageAt == null) return '';

    final last = thread.lastMessageAt!;
    final isSameDay =
        now.year == last.year && now.month == last.month && now.day == last.day;

    if (isSameDay) {
      return '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}';
    }

    final isSameYear = now.year == last.year;
    if (isSameYear) {
      return '${last.day.toString().padLeft(2, '0')}/${last.month.toString().padLeft(2, '0')}';
    }

    return '${last.day.toString().padLeft(2, '0')}/${last.month.toString().padLeft(2, '0')}/${last.year.toString().substring(2)}';
  }

  /// Get message status indicators
  String _getMessageStatus() {
    if (!thread.lastMessageFromMe) return '';

    return switch (thread.lastMessageStatus?.toLowerCase()) {
      'read' => '✓✓', // double check, colored blue
      'delivered' => '✓✓',
      'sent' => '✓',
      'queued' => '⏱',
      'failed' => '⚠',
      _ => '•',
    };
  }

  /// Get initials from name
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }

    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }
}

/// Mini status chip (compacto)
class _StatusChipMini extends StatelessWidget {
  final String status;

  const _StatusChipMini({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _statusColor(status).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: _statusColor(status),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _statusLabel(String v) {
    switch (v.toLowerCase()) {
      case 'primer_contacto':
        return '1er';
      case 'pendiente':
        return 'Pend.';
      case 'interesado':
        return 'Int.';
      case 'reserva':
        return 'Res.';
      case 'compro':
        return 'Cpró';
      case 'no_interesado':
        return 'No';
      default:
        return v.substring(0, (v.length / 2).ceil());
    }
  }

  Color _statusColor(String v) {
    switch (v.toLowerCase()) {
      case 'primer_contacto':
      case 'pendiente':
        return Colors.orange;
      case 'interesado':
        return Colors.blue;
      case 'reserva':
        return Colors.purple;
      case 'compro':
        return Colors.green;
      case 'no_interesado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
