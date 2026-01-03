import 'package:flutter/material.dart';

import '../../data/models/crm_message.dart';

class MessageBubble extends StatelessWidget {
  final CrmMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.fromMe;
    final theme = Theme.of(context);

    final bg = isMe
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;

    final body = (message.body ?? '').trim();
    final hasBody = body.isNotEmpty;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          color: bg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (hasBody)
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  Text(
                    '[sin texto] ${message.type}',
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 6),
                Text(
                  _timeOnly(message.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _timeOnly(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
