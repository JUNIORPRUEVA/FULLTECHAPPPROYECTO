import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_instance.dart';
import '../state/crm_instances_providers.dart';

class TransferChatDialog extends ConsumerStatefulWidget {
  final String chatId;
  final String chatDisplayName;

  const TransferChatDialog({
    super.key,
    required this.chatId,
    required this.chatDisplayName,
  });

  @override
  ConsumerState<TransferChatDialog> createState() => _TransferChatDialogState();
}

class _TransferChatDialogState extends ConsumerState<TransferChatDialog> {
  CrmTransferUser? _selectedUser;
  final _notesController = TextEditingController();
  bool _isTransferring = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _performTransfer() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un usuario destino'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isTransferring = true);

    try {
      final transfer = ref.read(transferChatProvider);
      await transfer(
        chatId: widget.chatId,
        toUserId: _selectedUser!.id,
        toInstanceId: _selectedUser!.instanceId,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      Navigator.pop(context, true); // Return true to indicate success

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chat transferido a ${_selectedUser!.username} exitosamente',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al transferir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(crmTransferUsersProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Color(0xFF0D47A1)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Transferir Chat',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chat info
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat a transferir:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.chatDisplayName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // User selection
              Text(
                'Transferir a:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              usersAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return Card(
                      color: Colors.orange.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No hay otros usuarios con instancias activas disponibles para transferir.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isSelected = _selectedUser?.id == user.id;

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: const Color(
                            0xFF0D47A1,
                          ).withOpacity(0.1),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? const Color(0xFF0D47A1)
                                : Colors.grey.shade400,
                            child: Text(
                              user.username[0].toUpperCase(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user.username,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            'Instancia: ${user.nombreInstancia}',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF0D47A1),
                                )
                              : null,
                          onTap: () {
                            setState(() => _selectedUser = user);
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error al cargar usuarios: $error',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes (optional)
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'Razón de la transferencia...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isTransferring ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isTransferring ? null : _performTransfer,
          icon: _isTransferring
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send),
          label: Text(_isTransferring ? 'Transfiriendo...' : 'Transferir'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
          ),
        ),
      ],
    );
  }
}

/// Helper function to show transfer dialog
Future<bool?> showTransferChatDialog(
  BuildContext context, {
  required String chatId,
  required String chatDisplayName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) =>
        TransferChatDialog(chatId: chatId, chatDisplayName: chatDisplayName),
  );
}
