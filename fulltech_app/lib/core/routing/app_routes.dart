class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const accessRevoked = '/access-revoked';

  static const crm = '/crm';
  static const crmInstanceSettings = '/crm/settings/instance';
  static const customers = '/customers';
  static const presupuesto = '/presupuesto';
  static const cotizaciones = '/cotizaciones';
  static const informeCotizaciones = '/informe-cotizaciones';
  static const crearCartas = '/crear-cartas';
  static const operaciones = '/operaciones';
  static String operacionesDetail(String id) => '$operaciones/$id';
  static const operacionesAgenda = '/operaciones/agenda';
  static const garantia = '/garantia';
  static const nomina = '/nomina';
  static const ventas = '/ventas';
  static const pos = '/pos';
  static const posPurchases = '/pos/purchases';
  static const posSuppliers = '/pos/suppliers';
  static const posInventory = '/pos/inventory';
  static const posCredit = '/pos/credit';
  static const posReports = '/pos/reports';
  static const catalogo = '/catalogo';
  static const tecnico = '/tecnico';
  static const contrato = '/contrato';
  static const guagua = '/guagua';
  static const contabilidad = '/contabilidad';
  static const mantenimiento = '/mantenimiento';
  static const ponchado = '/ponchado';
  static const rrhh = '/rrhh';
  static const usuarios = '/usuarios';
  static const perfil = '/perfil';
  static const rules = '/rules';
  static const configuracion = '/configuracion';
}
