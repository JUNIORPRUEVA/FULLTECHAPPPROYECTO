import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

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

    final bubbleRadius = BorderRadius.only(
      topLeft: Radius.circular(isMe ? 14 : 4),
      topRight: Radius.circular(isMe ? 4 : 14),
      bottomLeft: const Radius.circular(14),
      bottomRight: const Radius.circular(14),
    );

    final body = (message.body ?? '').trim();
    final hasBody = body.isNotEmpty;

    final mediaUrl = (message.mediaUrl ?? '').trim();
    final hasMedia = mediaUrl.isNotEmpty;

    final IconData mediaIcon;
    switch (message.type) {
      case 'image':
        mediaIcon = Icons.image;
        break;
      case 'video':
        mediaIcon = Icons.videocam;
        break;
      case 'audio':
      case 'ptt':
        mediaIcon = Icons.audiotrack;
        break;
      case 'document':
        mediaIcon = Icons.insert_drive_file;
        break;
      default:
        mediaIcon = Icons.attach_file;
        break;
    }

    final statusWidget = isMe
        ? _buildStatusIcon(context, message.status)
        : null;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Asistente Junior',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(color: bg, borderRadius: bubbleRadius),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasMedia) ...[
                      if (message.type == 'image')
                        _ImageThumb(
                          url: mediaUrl,
                          labelStyle: theme.textTheme.bodySmall,
                          showUrl: false,
                        )
                      else if (message.type == 'audio' || message.type == 'ptt')
                        _AudioPlayerBubble(
                          url: mediaUrl,
                          labelStyle: theme.textTheme.bodySmall,
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(mediaIcon, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                mediaUrl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      if (hasBody) const SizedBox(height: 8),
                    ],
                    if (hasBody)
                      RichText(text: _formatToSpan(context, body))
                    else if (!hasMedia)
                      Text(
                        '[sin texto] ${message.type}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _timeOnly(message.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (statusWidget != null) ...[
                          const SizedBox(width: 4),
                          statusWidget,
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _timeOnly(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static Widget? _buildStatusIcon(BuildContext context, String status) {
    final theme = Theme.of(context);
    final s = status.trim().toLowerCase();

    IconData? icon;
    Color? color;

    if (s.isEmpty || s == 'received') return null;

    if (s == 'failed' || s == 'error') {
      icon = Icons.error_outline;
      color = theme.colorScheme.error;
    } else if (s == 'queued' || s == 'pending' || s == 'sending') {
      icon = Icons.access_time;
      color = theme.colorScheme.onSurfaceVariant;
    } else if (s == 'sent') {
      icon = Icons.check;
      color = theme.colorScheme.onSurfaceVariant;
    } else if (s == 'delivered') {
      icon = Icons.done_all;
      color = theme.colorScheme.onSurfaceVariant;
    } else if (s == 'read' || s == 'seen') {
      icon = Icons.done_all;
      color = theme.colorScheme.primary;
    } else {
      // Unknown status: keep the UI clean.
      return null;
    }

    return Icon(icon, size: 16, color: color);
  }
}

TextSpan _formatToSpan(BuildContext context, String input) {
  final theme = Theme.of(context);
  final baseStyle = theme.textTheme.bodyMedium ?? const TextStyle();

  final spans = <TextSpan>[];

  int i = 0;
  while (i < input.length) {
    final nextMono = input.indexOf('```', i);
    final nextBold = input.indexOf('*', i);
    final nextItalic = input.indexOf('_', i);
    final nextStrike = input.indexOf('~', i);

    int next = -1;
    String marker = '';
    for (final cand in [
      MapEntry('```', nextMono),
      MapEntry('*', nextBold),
      MapEntry('_', nextItalic),
      MapEntry('~', nextStrike),
    ]) {
      final idx = cand.value;
      if (idx < 0) continue;
      if (next < 0 || idx < next) {
        next = idx;
        marker = cand.key;
      }
    }

    if (next < 0) {
      spans.add(TextSpan(text: input.substring(i)));
      break;
    }

    if (next > i) {
      spans.add(TextSpan(text: input.substring(i, next)));
    }

    final end = input.indexOf(marker, next + marker.length);
    if (end < 0) {
      // Unmatched marker: treat as plain text.
      spans.add(TextSpan(text: marker));
      i = next + marker.length;
      continue;
    }

    final inner = input.substring(next + marker.length, end);
    TextStyle style = baseStyle;
    if (marker == '*') {
      style = baseStyle.copyWith(fontWeight: FontWeight.w800);
    } else if (marker == '_') {
      style = baseStyle.copyWith(fontStyle: FontStyle.italic);
    } else if (marker == '~') {
      style = baseStyle.copyWith(decoration: TextDecoration.lineThrough);
    } else if (marker == '```') {
      style = baseStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      );
    }
    spans.add(TextSpan(text: inner, style: style));
    i = end + marker.length;
  }

  return TextSpan(style: baseStyle, children: spans);
}

class _ImageThumb extends StatelessWidget {
  final String url;
  final TextStyle? labelStyle;
  final bool showUrl;

  const _ImageThumb({
    required this.url,
    required this.labelStyle,
    required this.showUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (context) {
                return Dialog(
                  child: InteractiveViewer(
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                );
              },
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260, maxHeight: 220),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image),
                        const SizedBox(width: 8),
                        Flexible(child: SelectableText(url, style: labelStyle)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (showUrl) ...[
          const SizedBox(height: 6),
          SelectableText(url, style: labelStyle),
        ],
      ],
    );
  }
}

class _AudioStub extends StatelessWidget {
  final TextStyle? labelStyle;

  const _AudioStub({required this.labelStyle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              value: 0,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(width: 10),
          Text('Audio', style: labelStyle),
        ],
      ),
    );
  }
}

class _AudioPlayerBubble extends StatefulWidget {
  final String url;
  final TextStyle? labelStyle;

  const _AudioPlayerBubble({required this.url, required this.labelStyle});

  @override
  State<_AudioPlayerBubble> createState() => _AudioPlayerBubbleState();
}

class _AudioPlayerBubbleState extends State<_AudioPlayerBubble> {
  late final AudioPlayer _player;
  Duration _duration = Duration.zero;
  bool _supported = true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    Future.microtask(() async {
      try {
        final d = await _player.setUrl(widget.url);
        if (!mounted) return;
        setState(() => _duration = d ?? Duration.zero);
      } on MissingPluginException {
        if (!mounted) return;
        setState(() => _supported = false);
      } catch (_) {
        // Leave as-is; UI will still show URL.
      }
    });
  }

  @override
  void dispose() {
    Future.microtask(() async {
      try {
        await _player.dispose();
      } on MissingPluginException {
        // Desktop plugin not available; ignore.
      } catch (_) {
        // Ignore dispose errors.
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If just_audio plugin isn't available, fall back to a safe stub UI.
    if (!_supported) {
      return _AudioStub(labelStyle: widget.labelStyle);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, snapState) {
          final playing = snapState.data?.playing ?? false;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () async {
                      try {
                        if (playing) {
                          await _player.pause();
                        } else {
                          await _player.play();
                        }
                      } catch (_) {}
                    },
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  ),
                  const SizedBox(width: 8),
                  StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, snapPos) {
                      final pos = snapPos.data ?? Duration.zero;
                      final maxMs = _duration.inMilliseconds;
                      final posMs = pos.inMilliseconds.clamp(
                        0,
                        maxMs == 0 ? 0 : maxMs,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 170,
                            child: Slider(
                              value: maxMs == 0 ? 0 : (posMs / maxMs),
                              onChanged: (v) {
                                if (maxMs == 0) return;
                                final target = Duration(
                                  milliseconds: (v * maxMs).round(),
                                );
                                _player.seek(target);
                              },
                            ),
                          ),
                          Text(
                            '${_fmt(pos)} / ${_fmt(_duration)}',
                            style: widget.labelStyle,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SelectableText(widget.url, style: widget.labelStyle),
            ],
          );
        },
      ),
    );
  }

  static String _fmt(Duration d) {
    final total = d.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
