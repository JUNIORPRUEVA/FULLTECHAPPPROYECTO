import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RichTextEditorWithBoldShortcut extends StatefulWidget {
  const RichTextEditorWithBoldShortcut({super.key});

  @override
  State<RichTextEditorWithBoldShortcut> createState() => _RichTextEditorWithBoldShortcutState();
}

class _RichTextEditorWithBoldShortcutState extends State<RichTextEditorWithBoldShortcut> {
  final TextEditingController _controller = TextEditingController();
  List<_StyledSpan> _spans = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _applyBold() {
    final text = _controller.text;
    if (text.isEmpty) return;
    final sel = _controller.selection;
    if (sel.isCollapsed) {
      // No selection: apply bold to all
      _spans = [
        _StyledSpan(text, true),
      ];
    } else {
      // Selection: apply bold only to selected area
      final before = text.substring(0, sel.start);
      final selected = text.substring(sel.start, sel.end);
      final after = text.substring(sel.end);
      _spans = [];
      if (before.isNotEmpty) _spans.add(_StyledSpan(before, false));
      if (selected.isNotEmpty) _spans.add(_StyledSpan(selected, true));
      if (after.isNotEmpty) _spans.add(_StyledSpan(after, false));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyB): BoldIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BoldIntent: CallbackAction<BoldIntent>(onInvoke: (intent) {
            _applyBold();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Escribe aquí…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Vista previa:', style: Theme.of(context).textTheme.labelLarge),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RichText(
                  text: TextSpan(
                    children: _spans.isEmpty
                        ? [TextSpan(text: _controller.text, style: const TextStyle(color: Colors.black))]
                        : _spans.map((s) => TextSpan(
                              text: s.text,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: s.bold ? FontWeight.bold : FontWeight.normal,
                              ),
                            )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Atajo: Presiona la tecla "b" para poner en negrita todo el texto o la selección.'),
            ],
          ),
        ),
      ),
    );
  }
}

class BoldIntent extends Intent {
  const BoldIntent();
}

class _StyledSpan {
  final String text;
  final bool bold;
  _StyledSpan(this.text, this.bold);
}
