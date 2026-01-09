/// CRM Chat Status Constants and Labels
class CrmStatuses {
  // Status values
  static const String primerContacto = 'primer_contacto';
  static const String interesado = 'interesado';
  static const String reserva = 'reserva';
  static const String compro = 'compro';
  static const String compraFinalizada = 'compra_finalizada';
  static const String servicioReservado = 'servicio_reservado';
  static const String noInteresado = 'no_interesado';
  static const String porLevantamiento = 'por_levantamiento';
  static const String pendientePago = 'pendiente_pago';
  static const String conProblema = 'con_problema';
  static const String garantia = 'garantia';
  // Legacy-compatible (some existing data uses it)
  static const String enGarantia = 'en_garantia';
  static const String solucionGarantia = 'solucion_garantia';
  static const String servicioFinalizado = 'servicio_finalizado';
  static const String cancelado = 'cancelado';

  // Status labels
  static const Map<String, String> labels = {
    primerContacto: 'Primer contacto',
    interesado: 'Interesado',
    reserva: 'Reserva',
    compro: 'Compró',
    compraFinalizada: 'Compra finalizada',
    servicioReservado: 'Servicio reservado',
    noInteresado: 'No interesado',
    porLevantamiento: 'Por levantamiento',
    pendientePago: 'Pendiente de pago',
    conProblema: 'Con problema',
    garantia: 'Garantía',
    enGarantia: 'En garantía',
    solucionGarantia: 'Solución de garantía',
    servicioFinalizado: 'Servicio finalizado',
    cancelado: 'Cancelado',
  };

  /// Canonical statuses list for UI (same for chat status + filters).
  /// NOTE: Excludes legacy "activo/pendiente/inactivo" intentionally.
  static const List<String> ordered = [
    primerContacto,
    interesado,
    reserva,
    compro,
    compraFinalizada,
    pendientePago,
    porLevantamiento,
    servicioReservado,
    conProblema,
    garantia,
    solucionGarantia,
    noInteresado,
    servicioFinalizado,
    cancelado,
  ];

  /// Statuses that require a form dialog
  static const Set<String> requiresDialog = {
    reserva,
    servicioReservado,
    porLevantamiento,
    conProblema,
    garantia,
    solucionGarantia,
  };

  /// Statuses that trigger automatic client creation
  static const Set<String> createsClient = {
    compro,
    compraFinalizada,
  };

  /// Get label for a status value
  static String getLabel(String status) {
    return labels[status] ?? status.replaceAll('_', ' ');
  }

  /// Normalize legacy/mixed values into the canonical set used by the app.
  static String normalizeValue(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return primerContacto;

    // Legacy customer tags or older UI values.
    if (v == 'noInteresado') return noInteresado;
    if (v == 'solucionGarantia') return solucionGarantia;
    if (v == 'servicioFinalizado') return servicioFinalizado;
    if (v == 'pendientePago') return pendientePago;
    if (v == 'porLevantamiento') return porLevantamiento;
    if (v == 'servicioReservado') return servicioReservado;
    if (v == 'conProblema') return conProblema;
    if (v == 'enGarantia') return garantia;

    // Legacy CRM status.
    if (v == enGarantia) return garantia;

    // Explicitly deprecated states (avoid crashes in dropdown initialValue).
    if (v == 'activo' || v == 'pendiente' || v == 'inactivo') {
      return primerContacto;
    }

    return labels.containsKey(v) ? v : primerContacto;
  }

  /// Check if a status requires a dialog
  static bool needsDialog(String status) {
    return requiresDialog.contains(status);
  }

  /// Check if a status should create/update a client
  static bool shouldCreateClient(String status) {
    return createsClient.contains(status);
  }
}
