import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/adaptive_image.dart';
import '../../../../core/utils/launch_uri.dart';

import '../../data/models/crm_message.dart';

class MessageBubble extends StatelessWidget {
  final CrmMessage message;
  final String? displayName;
  final String? phone;

  const MessageBubble({
    super.key,
    required this.message,
    this.displayName,
    this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.fromMe;
    final theme = Theme.of(context);

    final status = (message.status).trim().toLowerCase();
    final isFailed = isMe && (status == 'failed' || status == 'error');

    final bg = isMe
      ? theme.colorScheme.primaryContainer
      : theme.colorScheme.surfaceVariant;
    final fg = isMe
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;

    // Chat-bubble style: rounded corners with a slightly tighter
    // corner on the "tail" side.
    const bigR = Radius.circular(18);
    const tailR = Radius.circular(6);
    final bubbleRadius = BorderRadius.only(
      topLeft: bigR,
      topRight: bigR,
      bottomLeft: isMe ? bigR : tailR,
      bottomRight: isMe ? tailR : bigR,
    );

    final body = (message.body ?? '').trim();
    final hasBody = body.isNotEmpty;

    final mediaUrl = (message.mediaUrl ?? '').trim();
    final hasMedia = mediaUrl.isNotEmpty;

    final showSendingPlaceholder =
        isMe && !hasMedia && status == 'sending' && message.type != 'text';

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

    final borderColor = isFailed
        ? theme.colorScheme.error.withOpacity(0.7)
        : (isMe ? null : theme.colorScheme.outlineVariant.withOpacity(0.55));

    final mediaLabel = _mediaLabel(message.type, mediaUrl, fallback: body);
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: fg, height: 1.25);

    // --- Sender info logic ---
    final showSender = !isMe;
    final senderLabel = (displayName != null && displayName!.trim().isNotEmpty)
        ? displayName!.trim()
        : (phone ?? '');

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(520, MediaQuery.sizeOf(context).width * 0.72),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: bubbleRadius,
                  border: borderColor != null
                      ? Border.all(color: borderColor)
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showSender && senderLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  senderLabel,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _timeOnly(message.createdAt),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hasMedia) ...[
                        if (message.type == 'image')
                          _ImageThumb(
                            url: mediaUrl,
                            labelStyle: theme.textTheme.bodySmall,
                            showUrl: false,
                          )
                        else if (message.type == 'audio' ||
                            message.type == 'ptt')
                          _AudioPlayerBubble(
                            url: mediaUrl,
                            labelStyle: theme.textTheme.bodySmall,
                          )
                        else if (message.type == 'video' ||
                            message.type == 'document')
                          _AttachmentCard(
                            url: mediaUrl,
                            type: message.type,
                            fg: fg,
                          )
                        else
                          _MediaRow(
                            icon: mediaIcon,
                            label: mediaLabel,
                            labelStyle:
                                (theme.textTheme.bodySmall ?? const TextStyle())
                                    .copyWith(color: fg),
                          ),
                        if (hasBody) const SizedBox(height: 8),
                      ],
                      if (hasBody)
                        RichText(
                          text: _formatToSpan(
                            context,
                            body,
                            baseStyle: bodyStyle,
                          ),
                        )
                      else if (showSendingPlaceholder)
                        Text(
                          'Enviando ${message.type}...',
                          style: bodyStyle.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else if (!hasMedia)
                        Text('[sin texto] ${message.type}', style: bodyStyle),
                      if (!showSender)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _timeOnly(message.createdAt),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isMe
                                        ? theme.colorScheme.onPrimaryContainer
                                              .withOpacity(0.75)
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (statusWidget != null) ...[
                                  const SizedBox(width: 4),
                                  statusWidget,
                                ],
                              ],
                            ),
                          ),
                        ),
                      if (showSender && statusWidget != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: statusWidget,
                        ),
                    ],
                  ),
                ),
              ),
            ],
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

TextSpan _formatToSpan(
  BuildContext context,
  String input, {
  required TextStyle baseStyle,
}) {
  final theme = Theme.of(context);

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

class _MediaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle labelStyle;

  const _MediaRow({
    required this.icon,
    required this.label,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: labelStyle.color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
      ],
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final String url;
  final String type;
  final Color fg;

  const _AttachmentCard({
    required this.url,
    required this.type,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = type.trim().toLowerCase();

    final icon = t == 'video' ? Icons.play_circle_outline : Icons.description;
    final title = t == 'video' ? 'Video' : 'Documento';
    final filename = _lastPathSegment(url);

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Icon(icon, color: fg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    if (filename.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          filename,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: fg.withOpacity(0.85),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _openUrl(context, url),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Abrir'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: fg,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _copyUrl(context, url),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: fg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _mediaLabel(String type, String url, {required String fallback}) {
  final t = type.trim().toLowerCase();
  if (url.trim().isEmpty) return fallback;

  final name = _lastPathSegment(url);
  if (t == 'video') return name.isEmpty ? 'Video' : 'Video · $name';
  if (t == 'document') return name.isEmpty ? 'Documento' : 'Documento · $name';
  if (t == 'audio' || t == 'ptt')
    return name.isEmpty ? 'Audio' : 'Audio · $name';
  if (t == 'image') return name.isEmpty ? 'Imagen' : 'Imagen · $name';
  return name.isEmpty ? url : name;
}

String _lastPathSegment(String url) {
  final v = url.trim();
  if (v.isEmpty) return '';

  // Windows local paths.
  if (v.contains('\\')) {
    final parts = v.split('\\').where((s) => s.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.last : '';
  }

  final uri = Uri.tryParse(v);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.last;
  }

  final parts = v.split('/').where((s) => s.trim().isNotEmpty).toList();
  return parts.isNotEmpty ? parts.last : '';
}

Future<void> _copyUrl(BuildContext context, String url) async {
  final v = url.trim();
  if (v.isEmpty) return;

  await Clipboard.setData(ClipboardData(text: v));
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Enlace copiado')));
}

Future<void> _openUrl(BuildContext context, String url) async {
  final v = url.trim();
  if (v.isEmpty) return;

  final uri = toLaunchUri(v);
  if (uri == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Enlace inválido')));
    return;
  }

  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace')));
  }
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

    Widget fallback(Object error) {
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
    }

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
                    child: adaptiveImage(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) {
                        return fallback(error);
                      },
                    ),
                  ),
                );
              },
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260, maxHeight: 220),
              child: adaptiveImage(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  return fallback(error);
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
