import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fulltech_app/core/widgets/module_page.dart';
import 'package:fulltech_app/features/auth/state/auth_providers.dart';
import 'package:fulltech_app/features/crm/data/models/crm_thread.dart';
import 'package:fulltech_app/features/cartas/models/letter_models.dart';
import 'package:fulltech_app/features/cartas/state/letters_providers.dart';
import 'package:fulltech_app/features/presupuesto/widgets/crm_chat_picker_dialog.dart';

class LetterDetailScreen extends ConsumerStatefulWidget {
  final String letterId;

  const LetterDetailScreen({super.key, required this.letterId});

  @override
  ConsumerState<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends ConsumerState<LetterDetailScreen> {
  Letter? _letter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLetter();
  }

  Future<void> _loadLetter() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(lettersApiProvider);
      final letter = await api.getLetter(widget.letterId);
      setState(() {
        _letter = letter;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando carta: $e')));
      }
    }
  }

  Future<void> _openPdf() async {
    try {
      final baseUrl = ref.read(apiClientProvider).dio.options.baseUrl;
      final pdfUrl = '$baseUrl/letters/${widget.letterId}/pdf';
      final uri = Uri.parse(pdfUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se puede abrir el PDF')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error abriendo PDF: $e')));
      }
    }
  }

  Future<void> _sendWhatsApp() async {
    final selected = await showDialog<CrmThread>(
      context: context,
      builder: (_) => const CrmChatPickerDialog(),
    );
    if (selected == null) return;

    try {
      final api = ref.read(lettersApiProvider);
      await api.sendWhatsApp(widget.letterId, selected.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Carta enviada por WhatsApp')),
        );
        _loadLetter(); // Reload to update status
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  Future<void> _deleteLetter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Carta'),
        content: const Text('¿Estás seguro de que deseas eliminar esta carta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ref.read(lettersApiProvider);
      await api.deleteLetter(widget.letterId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Carta eliminada')));
        context.go('/crear-cartas');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ModulePage(
        title: 'Carta',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_letter == null) {
      return ModulePage(
        title: 'Carta',
        child: const Center(child: Text('Carta no encontrada')),
      );
    }

    return ModulePage(
      title: 'Detalle de Carta',
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: 'Ver PDF',
          onPressed: _openPdf,
        ),
        IconButton(
          icon: const Icon(Icons.send),
          tooltip: 'Enviar WhatsApp',
          onPressed: _sendWhatsApp,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'eliminar') {
              _deleteLetter();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text(_letter!.status),
                          backgroundColor: _getStatusColor(_letter!.status),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(_letter!.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cliente',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(_letter!.customerName),
                    if (_letter!.customerPhone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _letter!.customerPhone!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text('Tipo', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(_letter!.letterType),
                    if (_letter!.quotationId != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Incluye cotización',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asunto',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_letter!.subject),
                    const Divider(height: 32),
                    Text(
                      'Contenido',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_letter!.body),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Ver PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sendWhatsApp,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar WhatsApp'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT':
        return Colors.grey;
      case 'SAVED':
        return Colors.blue;
      case 'SENT':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
