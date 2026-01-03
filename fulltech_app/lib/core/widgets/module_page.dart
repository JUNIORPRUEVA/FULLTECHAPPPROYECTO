import 'package:flutter/material.dart';

import 'main_layout.dart';

/// Simple wrapper to keep all module pages consistent.
class ModulePage extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool denseHeader;
  final double? headerBottomSpacing;

  const ModulePage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.denseHeader = false,
    this.headerBottomSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...actions,
            ],
          ),
          SizedBox(height: headerBottomSpacing ?? (denseHeader ? 6 : 12)),
          Expanded(child: child),
        ],
      ),
    );
  }
}
