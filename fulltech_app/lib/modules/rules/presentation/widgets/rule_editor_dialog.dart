import 'package:flutter/material.dart';

import '../../data/models/rules_category.dart';
import '../../data/models/rules_content.dart';
import '../utils/rules_ui.dart';

class RuleEditorDialog extends StatefulWidget {
  final String title;
  final RulesContent? initial;
  final List<RulesCategory> allowedCategories;
  final RulesCategory? lockedCategory;

  const RuleEditorDialog({
    super.key,
    required this.title,
    this.initial,
    this.allowedCategories = RulesCategory.values,
    this.lockedCategory,
  });

  @override
  State<RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<RuleEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _orderCtrl;

  late RulesCategory _category;
  bool _visibleToAll = true;
  late Set<String> _roleVisibility;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();

    final i = widget.initial;

    _titleCtrl = TextEditingController(text: i?.title ?? '');
    _contentCtrl = TextEditingController(text: i?.content ?? '');
    _orderCtrl = TextEditingController(text: (i?.orderIndex ?? 0).toString());

    _category = widget.lockedCategory ?? i?.category ?? widget.allowedCategories.first;
    _visibleToAll = i?.visibleToAll ?? true;
    _roleVisibility = (i?.roleVisibility ?? const <String>[]).toSet();
    _isActive = i?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_visibleToAll && _roleVisibility.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un rol o activa “Visible para todos los roles”.'),
        ),
      );
      return;
    }

    final order = int.tryParse(_orderCtrl.text.trim()) ?? 0;

    final value = RulesContent.draft(
      title: _titleCtrl.text.trim(),
      category: _category,
      content: _contentCtrl.text.trim(),
      visibleToAll: _visibleToAll,
      roleVisibility: _visibleToAll ? const [] : _roleVisibility.toList()..sort(),
      isActive: _isActive,
      orderIndex: order,
    );

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'El título es obligatorio';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RulesCategory>(
                  initialValue: _category,
                  items: widget.allowedCategories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ),
                      )
                      .toList(),
                  onChanged: widget.lockedCategory != null
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => _category = v);
                        },
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentCtrl,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'El contenido es obligatorio';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _orderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Orden',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n < 0) return 'Orden inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        title: const Text('Activo'),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                SwitchListTile.adaptive(
                  value: _visibleToAll,
                  onChanged: (v) => setState(() => _visibleToAll = v),
                  title: const Text('Visible para todos los roles'),
                ),
                const SizedBox(height: 6),
                if (!_visibleToAll) ...[
                  Text(
                    'Visibilidad por rol',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final role in knownAppRoles)
                        FilterChip(
                          label: Text(roleLabel(role)),
                          selected: _roleVisibility.contains(role),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _roleVisibility.add(role);
                              } else {
                                _roleVisibility.remove(role);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_roleVisibility.isEmpty)
                    Text(
                      'Selecciona al menos un rol, o activa “Visible para todos los roles”.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
