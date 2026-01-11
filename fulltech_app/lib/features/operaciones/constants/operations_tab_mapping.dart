import '../models/operations_models.dart';

enum OperationsTab {
  agenda,
  levantamientos,
  instalacionEnCurso,
  instalacionFinalizada,
  enGarantia,
  solucionGarantia,
  historial,
}

String operationsTabLabel(OperationsTab tab) {
  switch (tab) {
    case OperationsTab.agenda:
      return 'Agenda';
    case OperationsTab.levantamientos:
      return 'Levantamientos';
    case OperationsTab.instalacionEnCurso:
      return 'Instalación en curso';
    case OperationsTab.instalacionFinalizada:
      return 'Instalación finalizada';
    case OperationsTab.enGarantia:
      return 'En garantía';
    case OperationsTab.solucionGarantia:
      return 'Solución garantía';
    case OperationsTab.historial:
      return 'Historial';
  }
}

bool _isHistorialEstado(String estado) {
  final e = estado.trim().toUpperCase();
  return e == 'FINALIZADO' || e == 'CERRADO' || e == 'CANCELADO';
}

bool _isAgendaEstado(String estado) {
  final e = estado.trim().toUpperCase();
  return e == 'PENDIENTE' || e == 'PROGRAMADO' || e == 'EN_EJECUCION';
}

bool isWarranty(OperationsJob job) {
  final t = (job.crmTaskType ?? '').toUpperCase();
  if (t == 'GARANTIA') return true;
  return job.status.startsWith('warranty_') || job.status == 'closed';
}

bool isInstalacion(OperationsJob job) {
  final t = (job.crmTaskType ?? '').toUpperCase();
  return t == 'INSTALACION' || job.status.startsWith('installation_');
}

bool isLevantamiento(OperationsJob job) {
  final t = (job.crmTaskType ?? '').toUpperCase();
  return t == 'LEVANTAMIENTO' ||
      job.status.startsWith('pending_survey') ||
      job.status.startsWith('survey_');
}

bool isMantenimiento(OperationsJob job) {
  // Backend labels mantenimiento jobs using service_type = 'Mantenimiento'.
  final s = job.serviceType.trim().toLowerCase();
  return s == 'mantenimiento' || s.contains('mantenimiento');
}

bool isReservaAgendar(OperationsJob job) {
  final t = (job.crmTaskType ?? '').toUpperCase();
  return t == 'SERVICIO_RESERVADO';
}

bool hasScheduleOrScheduledStatus(OperationsJob job) {
  return job.scheduledDate != null ||
      job.status == 'pending_scheduling' ||
      job.status == 'scheduled';
}

bool jobMatchesTab(OperationsTab tab, OperationsJob job) {
  final tipo = job.tipoTrabajo.trim().toUpperCase();
  final estado = job.estado.trim().toUpperCase();

  switch (tab) {
    case OperationsTab.agenda:
      // Agenda: PROGRAMADO or PENDIENTE, excluding LEVANTAMIENTO
      return (estado == 'PROGRAMADO' || estado == 'PENDIENTE') &&
          tipo != 'LEVANTAMIENTO';

    case OperationsTab.levantamientos:
      // Levantamientos: active states (not closed/canceled) and type LEVANTAMIENTO
      return _isAgendaEstado(estado) && tipo == 'LEVANTAMIENTO';

    case OperationsTab.instalacionEnCurso:
      // Installation in progress: EN_EJECUCION for INSTALACION or MANTENIMIENTO
      return (tipo == 'INSTALACION' || tipo == 'MANTENIMIENTO') &&
          estado == 'EN_EJECUCION';

    case OperationsTab.instalacionFinalizada:
      // Completed installations: FINALIZADO or CERRADO for INSTALACION or MANTENIMIENTO
      return (tipo == 'INSTALACION' || tipo == 'MANTENIMIENTO') &&
          (estado == 'FINALIZADO' || estado == 'CERRADO');

    case OperationsTab.enGarantia:
      // Active warranty: GARANTIA type with active states (not closed/canceled)
      return tipo == 'GARANTIA' &&
          (estado == 'PROGRAMADO' ||
              estado == 'PENDIENTE' ||
              estado == 'EN_EJECUCION');

    case OperationsTab.solucionGarantia:
      // Resolved warranty: GARANTIA type with FINALIZADO or CERRADO
      return tipo == 'GARANTIA' && (estado == 'FINALIZADO' || estado == 'CERRADO');

    case OperationsTab.historial:
      // Historial: CANCELADO only (FINALIZADO/CERRADO go to their specific tabs)
      return estado == 'CANCELADO';
  }
}

OperationsTab tabForCrmStatus(String status) {
  final s = status.trim().toLowerCase();
  if (s == 'por_levantamiento') return OperationsTab.levantamientos;
  if (s == 'historial') return OperationsTab.historial;
  return OperationsTab.agenda;
}
