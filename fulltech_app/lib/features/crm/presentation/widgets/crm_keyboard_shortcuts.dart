import 'package:flutter/material.dart';

class CrmKeyboardShortcut {
  final String keys;
  final String description;

  const CrmKeyboardShortcut({required this.keys, required this.description});
}

const crmKeyboardShortcuts = <CrmKeyboardShortcut>[
  CrmKeyboardShortcut(
    keys: 'Ctrl + Enter',
    description: 'Enviar mensaje (en el campo de mensaje)',
  ),
  CrmKeyboardShortcut(
    keys: 'Esc',
    description: 'Salir del chat / cerrar chat seleccionado',
  ),
];

Future<void> showCrmKeyboardShortcutsDialog(BuildContext context) async {
  final theme = Theme.of(context);

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Atajos de teclado (CRM)'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Estos atajos funcionan mientras estás en el CRM (especialmente dentro del chat).',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ...crmKeyboardShortcuts.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          s.keys,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}
