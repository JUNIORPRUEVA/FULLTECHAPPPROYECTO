import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class CrmStatusDataRepository {
  CrmStatusDataRepository();

  // === Reservations ===

  Future<void> saveReservation({
    required String empresaId,
    required String threadId,
    required Map<String, dynamic> reservationData,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();

    final record = {
      'id': id,
      'empresa_id': empresaId,
      'thread_id': threadId,
      'fecha_reserva': reservationData['fecha_reserva'],
      'hora_reserva': reservationData['hora_reserva'],
      'descripcion_producto': reservationData['descripcion_producto'],
      'monto_reserva': reservationData['monto_reserva'],
      'notas_adicionales': reservationData['notas_adicionales'],
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending',
      'last_error': null,
    };

    // TODO: Save to local database when backend is ready
    // For now, just log
    print('[CrmStatusDataRepo] Would save reservation: $record');
  }

  // === Service Agenda ===

  Future<void> saveServiceAgenda({
    required String empresaId,
    required String threadId,
    required Map<String, dynamic> serviceData,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();

    final record = {
      'id': id,
      'empresa_id': empresaId,
      'thread_id': threadId,
      'fecha_servicio': serviceData['fecha_servicio'],
      'hora_servicio': serviceData['hora_servicio'],
      'tipo_servicio': serviceData['tipo_servicio'],
      'ubicacion': serviceData['ubicacion'],
      'tecnico_asignado': serviceData['tecnico_asignado'],
      'notas_adicionales': serviceData['notas_adicionales'],
      'status': 'programado',
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending',
      'last_error': null,
    };

    // TODO: Save to local database when backend is ready
    print('[CrmStatusDataRepo] Would save service agenda: $record');
  }

  // === Warranty Cases ===

  Future<void> saveWarrantyCase({
    required String empresaId,
    required String threadId,
    required Map<String, dynamic> warrantyData,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();

    final record = {
      'id': id,
      'empresa_id': empresaId,
      'thread_id': threadId,
      'fecha_compra': warrantyData['fecha_compra'],
      'producto_afectado': warrantyData['producto_afectado'],
      'descripcion_problema': warrantyData['descripcion_problema'],
      'numero_factura': warrantyData['numero_factura'],
      'notas_adicionales': warrantyData['notas_adicionales'],
      'status': 'abierto',
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending',
      'last_error': null,
    };

    // TODO: Save to local database when backend is ready
    print('[CrmStatusDataRepo] Would save warranty case: $record');
  }

  // === Warranty Solutions ===

  Future<void> saveWarrantySolution({
    required String empresaId,
    required String threadId,
    String? warrantyCaseId,
    required Map<String, dynamic> solutionData,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();

    final record = {
      'id': id,
      'empresa_id': empresaId,
      'thread_id': threadId,
      'warranty_case_id': warrantyCaseId,
      'fecha_solucion': solutionData['fecha_solucion'],
      'solucion_aplicada': solutionData['solucion_aplicada'],
      'tecnico_responsable': solutionData['tecnico_responsable'],
      'piezas_reemplazadas': solutionData['piezas_reemplazadas'],
      'cliente_satisfecho': solutionData['cliente_satisfecho'] ? 1 : 0,
      'notas_adicionales': solutionData['notas_adicionales'],
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending',
      'last_error': null,
    };

    // TODO: Save to local database when backend is ready
    print('[CrmStatusDataRepo] Would save warranty solution: $record');
  }
}
