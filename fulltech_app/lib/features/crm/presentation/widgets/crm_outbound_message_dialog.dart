import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_config.dart';
import '../../state/crm_providers.dart';

class CrmOutboundMessageDialog extends ConsumerStatefulWidget {
  const CrmOutboundMessageDialog({super.key});

  @override
  ConsumerState<CrmOutboundMessageDialog> createState() =>
      _CrmOutboundMessageDialogState();
}

class _CrmOutboundMessageDialogState
    extends ConsumerState<CrmOutboundMessageDialog> {
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  String _status = 'primer_contacto';
  bool _sending = false;
  String? _error;

  static const _statusItems = <({String value, String label})>[
    (value: 'primer_contacto', label: 'Primer contacto'),
    (value: 'pendiente', label: 'Pendiente'),
    (value: 'interesado', label: 'Interesado'),
    (value: 'reserva', label: 'Reserva'),
    (value: 'compro', label: 'Compró'),
    (value: 'no_interesado', label: 'No interesado'),
    (value: 'activo', label: 'Activo'),
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  String _digitsOnly(String v) => v.replaceAll(RegExp(r'\D+'), '');

  String _defaultCountryCode() {
    final cc = AppConfig.evolutionDefaultCountryCode.trim();
    if (cc.isNotEmpty) return _digitsOnly(cc);
    return '1';
  }

  String _normalizePhoneForWhatsapp(String raw) {
    final digits = _digitsOnly(raw);
    if (digits.isEmpty) return '';

    // Mimic backend/client Evolution normalization: if 10 digits, prefix default country code.
    if (digits.length == 10) return '${_defaultCountryCode()}$digits';

    return digits;
  }

  Future<void> _send() async {
    final phoneNormalized = _normalizePhoneForWhatsapp(_phoneCtrl.text);
    final message = _messageCtrl.text.trim();

    if (phoneNormalized.isEmpty) {
      setState(() => _error = 'Ingresa un número de WhatsApp válido.');
      return;
    }
    if (message.isEmpty) {
      setState(() => _error = 'Escribe el mensaje a enviar.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final repo = ref.read(crmRepositoryProvider);
      final result = await repo.sendOutboundTextMessage(
        phone: phoneNormalized,
        text: message,
        status: _status,
        displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      );

      final chatId = (result['chatId'] ??
              (result['chat'] is Map<String, dynamic>
                  ? (result['chat'] as Map<String, dynamic>)['id']
                  : null))
          ?.toString();

      if (chatId == null || chatId.trim().isEmpty) {
        throw Exception('Respuesta inválida: falta chatId');
      }

      if (!mounted) return;
      Navigator.of(context).pop(chatId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error enviando: $e';
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phoneNormalized = _normalizePhoneForWhatsapp(_phoneCtrl.text);
    final waId = phoneNormalized.isEmpty ? '' : '$phoneNormalized@s.whatsapp.net';

    final canSend = !_sending &&
        phoneNormalized.isNotEmpty &&
        _messageCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      title: const Text('Nuevo mensaje (número fuera de chats)'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Número WhatsApp',
                hintText: 'Ej: +1 809 555 1234',
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                waId.isEmpty ? 'WhatsApp ID: —' : 'WhatsApp ID: $waId',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre (opcional)',
                hintText: 'Ej: Juan Pérez',
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _status,
              items: _statusItems
                  .map(
                    (s) => DropdownMenuItem<String>(
                      value: s.value,
                      child: Text(s.label),
                    ),
                  )
                  .toList(),
              onChanged: _sending ? null : (v) => setState(() => _status = v!),
              decoration: const InputDecoration(
                labelText: 'Estado del chat',
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageCtrl,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Mensaje',
                hintText: 'Escribe el mensaje…',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: canSend ? _send : null,
          icon: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Enviar'),
        ),
      ],
    );
  }
}
