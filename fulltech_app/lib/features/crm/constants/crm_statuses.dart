/// CRM Chat Status Constants and Labels
class CrmStatuses {
  // Status values
  static const String primerContacto = 'primer_contacto';
  static const String interesado = 'interesado';
  static const String reserva = 'reserva';
  static const String agendado = 'agendado';
  static const String compro = 'compro';
  static const String compraFinalizada = 'compra_finalizada';
  // Legacy status value (deprecated in UI; treated as RESERVA).
  static const String servicioReservado = 'servicio_reservado';
  static const String noInteresado = 'no_interesado';
  static const String porLevantamiento = 'por_levantamiento';
  static const String instalacion = 'instalacion';
  static const String pendientePago = 'pendiente_pago';
  static const String garantia = 'garantia';
  // Legacy-compatible (some existing data uses it)
  static const String enGarantia = 'en_garantia';
  static const String solucionGarantia = 'solucion_garantia';
  static const String cancelado = 'cancelado';

  // Status labels
  static const Map<String, String> labels = {
    primerContacto: 'Primer contacto',
    interesado: 'Interesado',
    reserva: 'Reserva',
    agendado: 'Agendado',
    compro: 'Compró',
    compraFinalizada: 'Compra finalizada',
    noInteresado: 'No interesado',
    porLevantamiento: 'Por levantamiento',
    instalacion: 'Instalación',
    pendientePago: 'Pendiente de pago',
    garantia: 'Garantía',
    enGarantia: 'En garantía',
    solucionGarantia: 'Solución de garantía',
    cancelado: 'Cancelado',
  };

  /// Canonical statuses list for UI (same for chat status + filters).
  /// NOTE: Excludes legacy "activo/pendiente/inactivo" intentionally.
  static const List<String> ordered = [
    primerContacto,
    interesado,
    reserva,
    agendado,
    pendientePago,
    porLevantamiento,
    instalacion,
    garantia,
    solucionGarantia,
    compro,
    noInteresado,
    cancelado,
  ];

  /// Statuses that require a form dialog
  static const Set<String> requiresDialog = {
    reserva,
    agendado,
    porLevantamiento,
    instalacion,
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
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return primerContacto;

    // Backend alias inputs: these normalize to servicio_reservado on the server.
    if (v == 'agendado' || v == 'reservado') return agendado;

    if (v == 'instalación') return instalacion;

    // Legacy/deprecated CRM statuses still present in older data.
    if (v == 'compra_finalizada') return compro;
    if (v == 'servicio_finalizado') return compro;
    if (v == 'con_problema') return garantia;

    // Legacy customer tags or older UI values.
    if (v == 'noInteresado') return noInteresado;
    if (v == 'solucionGarantia') return solucionGarantia;
    if (v == 'pendientePago') return pendientePago;
    if (v == 'porLevantamiento') return porLevantamiento;
    if (v == 'servicioReservado') return agendado;
    if (v == 'mantenimiento') return agendado;
    if (v == 'enGarantia') return garantia;

    // Deprecated UI status (legacy): treat as RESERVA.
    if (v == servicioReservado) return agendado;

    // Legacy CRM status.
    if (v == enGarantia) return garantia;

    // Explicitly deprecated states (avoid crashes in dropdown initialValue).
    if (v == 'activo' || v == 'pendiente' || v == 'inactivo') {
      return primerContacto;
    }

    return labels.containsKey(v) ? v : primerContacto;
  }

  /// True when a thread belongs to post-sale (cliente activo / postventa) inbox.
  static bool isPostSaleStatus(String status) {
    switch (normalizeValue(status)) {
      case compro:
      case garantia:
      case solucionGarantia:
        return true;
      default:
        return false;
    }
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
