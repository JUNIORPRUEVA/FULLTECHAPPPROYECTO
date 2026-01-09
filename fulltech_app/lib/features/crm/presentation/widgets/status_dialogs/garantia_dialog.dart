import 'package:flutter/material.dart';

class GarantiaDialogResult {
  final String productoAfectado;
  final String numeroSerie;
  final String tiempoGarantia;
  final String detalles;

  GarantiaDialogResult({
    required this.productoAfectado,
    required this.numeroSerie,
    required this.tiempoGarantia,
    required this.detalles,
  });

  Map<String, dynamic> toJson() {
    return {
      'producto_afectado': productoAfectado,
      'numero_serie': numeroSerie,
      'tiempo_garantia': tiempoGarantia,
      'detalles': detalles,
    };
  }
}

class GarantiaDialog extends StatefulWidget {
  const GarantiaDialog({super.key});

  @override
  State<GarantiaDialog> createState() => _GarantiaDialogState();
}

class _GarantiaDialogState extends State<GarantiaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productoController = TextEditingController();
  final _serieController = TextEditingController();
  final _garantiaController = TextEditingController();
  final _detallesController = TextEditingController();

  @override
  void dispose() {
    _productoController.dispose();
    _serieController.dispose();
    _garantiaController.dispose();
    _detallesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final result = GarantiaDialogResult(
        productoAfectado: _productoController.text.trim(),
        numeroSerie: _serieController.text.trim(),
        tiempoGarantia: _garantiaController.text.trim(),
        detalles: _detallesController.text.trim(),
      );
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Caso de Garantía'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Producto
                TextFormField(
                  controller: _productoController,
                  decoration: const InputDecoration(
                    labelText: 'Producto *',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Laptop Dell XPS 15',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Número de serie
                TextFormField(
                  controller: _serieController,
                  decoration: const InputDecoration(
                    labelText: 'Número de serie *',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: SN123456789',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tiempo de garantía
                TextFormField(
                  controller: _garantiaController,
                  decoration: const InputDecoration(
                    labelText: 'Tiempo de garantía *',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: 12 meses, 2 años',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Detalles
                TextFormField(
                  controller: _detallesController,
                  decoration: const InputDecoration(
                    labelText: 'Detalles *',
                    border: OutlineInputBorder(),
                    hintText: 'Describa detalladamente el problema',
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    if (value.trim().length < 10) {
                      return 'Los detalles deben tener al menos 10 caracteres';
                    }
                    return null;
                  },
                ),
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
        ElevatedButton(
          onPressed: _handleSubmit,
          child: const Text('Registrar Caso'),
        ),
      ],
    );
  }
}
