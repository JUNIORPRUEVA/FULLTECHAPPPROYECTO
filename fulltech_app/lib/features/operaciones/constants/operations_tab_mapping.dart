import '../models/operations_models.dart';

enum OperationsTab {
  agenda,
  levantamientos,
  mantenimiento,
  instalaciones,
}

String operationsTabLabel(OperationsTab tab) {
  switch (tab) {
    case OperationsTab.agenda:
      return 'Agenda';
    case OperationsTab.levantamientos:
      return 'Levantamientos';
    case OperationsTab.mantenimiento:
      return 'Mantenimiento';
    case OperationsTab.instalaciones:
      return 'Instalaciones';
  }
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
  switch (tab) {
    case OperationsTab.agenda:
      // Agenda: anything scheduled (and keep warranty visible).
      return hasScheduleOrScheduledStatus(job) ||
          isReservaAgendar(job) ||
          isWarranty(job);

    case OperationsTab.levantamientos:
      // Levantamientos: survey pipeline.
      return isLevantamiento(job) || job.status == 'pending_scheduling';

    case OperationsTab.mantenimiento:
      // Mantenimiento: separate view for maintenance-labelled jobs.
      return isMantenimiento(job);

    case OperationsTab.instalaciones:
      // Instalaciones: installation jobs.
      return isInstalacion(job);
  }
}

OperationsTab tabForCrmStatus(String status) {
  final s = status.trim().toLowerCase();
  if (s == 'por_levantamiento') return OperationsTab.levantamientos;
  if (s == 'mantenimiento') return OperationsTab.mantenimiento;
  if (s == 'instalacion') return OperationsTab.instalaciones;
  // agendado/reserva -> agenda
  return OperationsTab.agenda;
}
