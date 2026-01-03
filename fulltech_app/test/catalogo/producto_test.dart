import 'package:flutter_test/flutter_test.dart';

import 'package:fulltech_app/features/catalogo/models/producto.dart';

void main() {
  group('Producto.fromJson', () {
    test('tolerates int ids and null imagen_url', () {
      final p = Producto.fromJson({
        'id': 1,
        'nombre': 'Taladro',
        'precio_compra': 1000,
        'precio_venta': 1500,
        'imagen_url': null,
        'categoria_id': 10,
        'categoria': null,
        'search_count': 0,
        'is_active': true,
      });

      expect(p.id, '1');
      expect(p.categoriaId, '10');
      expect(p.imagenUrl, '');
      expect(p.nombre, 'Taladro');
    });

    test('parses decimal with comma strings', () {
      final p = Producto.fromJson({
        'id': 'p1',
        'nombre': 'Martillo',
        'precio_compra': '12,50',
        'precio_venta': '20.00',
        'imagen_url': '',
        'categoria_id': 'c1',
        'categoria': null,
        'search_count': 0,
        'is_active': true,
      });

      expect(p.precioCompra, closeTo(12.5, 0.0001));
      expect(p.precioVenta, closeTo(20.0, 0.0001));
    });

    test('toJson always includes imagen_url key', () {
      final p = Producto.fromJson({
        'id': 'p2',
        'nombre': 'Sierra',
        'precio_compra': 1,
        'precio_venta': 2,
        'categoria_id': 'c2',
        'is_active': true,
      });

      final json = p.toJson();
      expect(json.containsKey('imagen_url'), true);
      expect(json['imagen_url'], '');
    });
  });
}
