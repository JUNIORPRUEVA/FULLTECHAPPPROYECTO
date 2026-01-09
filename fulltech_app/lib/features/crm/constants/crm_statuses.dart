/// CRM Chat Status Constants and Labels
class CrmStatuses {
  // Status values
  static const String primerContacto = 'primer_contacto';
  static const String interesado = 'interesado';
  static const String reserva = 'reserva';
  static const String compro = 'compro';
  static const String compraFinalizada = 'compra_finalizada';
  static const String servicioReservado = 'servicio_reservado';
  static const String porLevantamiento = 'por_levantamiento';
  static const String noInteresado = 'no_interesado';
  static const String enGarantia = 'en_garantia';
  static const String solucionGarantia = 'solucion_garantia';

  // Status labels
  static const Map<String, String> labels = {
    primerContacto: 'Primer contacto',
    interesado: 'Interesado',
    reserva: 'Reserva',
    compro: 'Compró',
    compraFinalizada: 'Compra finalizada',
    servicioReservado: 'Servicio reservado',
    porLevantamiento: 'Por levantamiento',
    noInteresado: 'No interesado',
    enGarantia: 'En garantía',
    solucionGarantia: 'Solución de garantía',
  };

  /// Statuses that require a form dialog
  static const Set<String> requiresDialog = {
    reserva,
    servicioReservado,
    porLevantamiento,
    enGarantia,
    solucionGarantia,
  };

  /// Statuses that trigger automatic client creation
  static const Set<String> createsClient = {compro, compraFinalizada};

  /// Get label for a status value
  static String getLabel(String status) {
    return labels[status] ?? status.replaceAll('_', ' ');
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
