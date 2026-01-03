import 'package:flutter/material.dart';

class OperacionesDetailScreen extends StatelessWidget {
  final String title;

  const OperacionesDetailScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('TODO: Detalle/edición del registro (levantamiento / instalación).'),
      ),
    );
  }
}
