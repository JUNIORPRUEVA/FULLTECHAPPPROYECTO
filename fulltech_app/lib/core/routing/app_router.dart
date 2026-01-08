import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/state/auth_providers.dart';
import '../../features/auth/state/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/access_revoked_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/crm/presentation/pages/crm_home_page.dart';
import '../../features/crm/presentation/pages/thread_chat_page.dart';
import '../../features/crm/presentation/pages/customer_detail_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/presupuesto/screens/presupuesto_detail_screen.dart';
import '../../features/cotizaciones/screens/cotizaciones_list_screen.dart';
import '../../features/cotizaciones/screens/cotizacion_detail_screen.dart';
import '../../features/cotizaciones/screens/informe_cotizaciones_screen.dart';
import '../../features/cotizaciones/screens/crear_cartas_screen.dart';
import '../../features/operaciones/screens/operaciones_list_screen.dart';
import '../../features/operaciones/screens/operaciones_detail_screen.dart';
import '../../features/garantia/screens/garantia_list_screen.dart';
import '../../features/nomina/screens/nomina_list_screen.dart';
import '../../features/nomina/screens/payroll_run_detail_screen.dart';
import '../../features/ventas/screens/ventas_list_screen.dart';
import '../../features/catalogo/screens/catalogo_screen.dart';
import '../../modules/pos/presentation/pages/pos_credit_page.dart';
import '../../modules/pos/presentation/pages/pos_inventory_page.dart';
import '../../modules/pos/presentation/pages/pos_purchases_page.dart';
import '../../modules/pos/presentation/pages/pos_reports_page.dart';
import '../../modules/pos/presentation/pages/pos_suppliers_page.dart';
import '../../modules/pos/presentation/pages/pos_tpv_page.dart';
import '../../features/tecnico/screens/tecnico_list_screen.dart';
import '../../features/contrato/screens/contrato_list_screen.dart';
import '../../features/guagua/screens/guagua_list_screen.dart';
import '../../features/maintenance/presentation/pages/maintenance_page.dart';
import '../../features/ponchado/presentation/pages/ponchado_page.dart';
import '../../features/rrhh/screens/rrhh_list_screen.dart';
import '../../features/perfil/screens/perfil_screen.dart';
import '../../features/configuracion/screens/configuracion_screen.dart';
import '../../features/configuracion/screens/company_settings_screen.dart';
import '../../features/configuracion/screens/theme_settings_screen.dart';
import '../../features/configuracion/screens/display_settings_screen.dart';
import '../../features/configuracion/screens/api_endpoint_settings_screen.dart';
import '../../modules/settings/permissions/permissions_settings_screen.dart';
import '../../modules/settings/printer/printer_settings_screen.dart';
import '../../features/usuarios/presentation/pages/user_detail_page.dart';
import '../../features/usuarios/presentation/pages/usuarios_list_page.dart';
import '../../features/usuarios/presentation/pages/user_form_page.dart';
import '../../modules/accounting/presentation/accounting_dashboard_page.dart';
import '../../modules/accounting/presentation/payroll_entry.dart';
import '../../modules/accounting/presentation/expenses_page.dart';
import '../../modules/accounting/presentation/income_payments_page.dart';
import '../../modules/accounting/presentation/accounting_reports_page.dart';
import '../../modules/accounting/presentation/accounting_categories_page.dart';
import '../../modules/accounting/presentation/biweekly_close/biweekly_close_page.dart';
import '../../modules/rules/presentation/screens/admin_manage_rules_screen.dart';
import '../../modules/rules/presentation/screens/policies_screen.dart';
import '../../modules/rules/presentation/screens/procedures_screen.dart';
import '../../modules/rules/presentation/screens/role_responsibilities_screen.dart';
import '../../modules/rules/presentation/screens/rules_access_denied_screen.dart';
import '../../modules/rules/presentation/screens/rules_home_screen.dart';
import '../../modules/rules/presentation/screens/rules_search_screen.dart';
import '../../modules/rules/presentation/screens/vision_mission_screen.dart';
import 'app_routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final router = createRouter(ref);
  ref.onDispose(router.dispose);
  return router;
});

GoRouter createRouter(Ref ref) {
  String? redirect(BuildContext context, GoRouterState state) {
    final auth = ref.read(authControllerProvider);
    final isLoggingIn = state.matchedLocation == AppRoutes.login;
    final isSplash = state.matchedLocation == '/splash';

    // Show splash screen while bootstrap is in progress
    if (auth is AuthUnknown || auth is AuthValidating) {
      return isSplash ? null : '/splash';
    }

    final isAuthed = auth is AuthAuthenticated;
    if (!isAuthed && !isLoggingIn) return AppRoutes.login;
    if (isAuthed && isLoggingIn) return AppRoutes.crm;
    if (isAuthed && isSplash) return AppRoutes.crm;
    return null;
  }

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authControllerProvider.notifier).stream,
    ),
    redirect: redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.accessRevoked,
        builder: (context, state) => const AccessRevokedScreen(),
      ),
      GoRoute(
        path: AppRoutes.crm,
        builder: (c, s) => const CrmHomePage(),
        routes: [
          GoRoute(
            path: 'chats/:id',
            builder: (c, s) =>
                ThreadChatPage(threadId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'customers/:id',
            builder: (c, s) =>
                CustomerDetailPage(customerId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.customers,
        builder: (c, s) {
          final onlyActive = s.uri.queryParameters['onlyActive'] == '1';
          return CustomersPage(onlyActiveCustomers: onlyActive);
        },
      ),
      GoRoute(
        path: AppRoutes.presupuesto,
        builder: (c, s) => const PresupuestoDetailScreen(),
        routes: [
          GoRoute(path: 'new', redirect: (c, s) => AppRoutes.presupuesto),
        ],
      ),
      GoRoute(
        path: AppRoutes.cotizaciones,
        builder: (c, s) => const CotizacionesListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (c, s) =>
                CotizacionDetailScreen(id: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.informeCotizaciones,
        builder: (c, s) => const InformeCotizacionesScreen(),
      ),
      GoRoute(
        path: AppRoutes.crearCartas,
        builder: (c, s) => const CrearCartasScreen(),
      ),
      GoRoute(
        path: AppRoutes.operaciones,
        builder: (c, s) => const OperacionesListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (c, s) => OperacionesDetailScreen(
              title: 'Operación ${s.pathParameters['id']!}',
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.garantia,
        builder: (c, s) => const GarantiaListScreen(),
      ),
      GoRoute(
        path: AppRoutes.nomina,
        redirect: (context, state) {
          final auth = ref.read(authControllerProvider);
          if (auth is! AuthAuthenticated) return AppRoutes.login;
          final role = auth.user.role;
          final isAdmin = role == 'admin' || role == 'administrador';
          return isAdmin ? null : AppRoutes.accessRevoked;
        },
        builder: (c, s) => const NominaListScreen(),
        routes: [
          GoRoute(
            path: 'runs/:id',
            builder: (c, s) =>
                PayrollRunDetailScreen(runId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.ventas,
        builder: (c, s) => const VentasListScreen(),
      ),
      GoRoute(
        path: AppRoutes.pos,
        builder: (c, s) => const PosTpvPage(),
        routes: [
          GoRoute(
            path: 'purchases',
            builder: (c, s) => const PosPurchasesPage(),
          ),
          GoRoute(
            path: 'suppliers',
            builder: (c, s) => const PosSuppliersPage(),
          ),
          GoRoute(
            path: 'inventory',
            builder: (c, s) => const PosInventoryPage(),
          ),
          GoRoute(path: 'credit', builder: (c, s) => const PosCreditPage()),
          GoRoute(path: 'reports', builder: (c, s) => const PosReportsPage()),
        ],
      ),
      GoRoute(
        path: AppRoutes.catalogo,
        builder: (c, s) => const CatalogoScreen(),
      ),
      GoRoute(
        path: AppRoutes.tecnico,
        builder: (c, s) => const TecnicoListScreen(),
      ),
      GoRoute(
        path: AppRoutes.contrato,
        builder: (c, s) => const ContratoListScreen(),
      ),
      GoRoute(
        path: AppRoutes.guagua,
        builder: (c, s) => const GuaguaListScreen(),
      ),
      GoRoute(
        path: AppRoutes.contabilidad,
        builder: (c, s) => const AccountingDashboardPage(),
        routes: [
          GoRoute(path: 'payroll', builder: (c, s) => const PayrollEntryPage()),
          GoRoute(
            path: 'biweekly-close',
            builder: (c, s) => const BiweeklyClosePage(),
          ),
          GoRoute(path: 'expenses', builder: (c, s) => const ExpensesPage()),
          GoRoute(
            path: 'income-payments',
            builder: (c, s) => const IncomePaymentsPage(),
          ),
          GoRoute(
            path: 'reports',
            builder: (c, s) => const AccountingReportsPage(),
          ),
          GoRoute(
            path: 'categories',
            builder: (c, s) => const AccountingCategoriesPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.mantenimiento,
        redirect: (context, state) {
          final auth = ref.read(authControllerProvider);
          if (auth is! AuthAuthenticated) return AppRoutes.login;

          final role = auth.user.role;
          final isAdminOrAssistant =
              role == 'admin' ||
              role == 'administrador' ||
              role == 'asistente_administrativo';

          if (!isAdminOrAssistant) {
            return AppRoutes.accessRevoked;
          }
          return null;
        },
        builder: (c, s) => const MaintenancePage(),
      ),
      GoRoute(
        path: AppRoutes.ponchado,
        builder: (c, s) => const PonchodoPage(),
      ),
      GoRoute(path: AppRoutes.rrhh, builder: (c, s) => const RrhhListScreen()),
      GoRoute(
        path: AppRoutes.usuarios,
        redirect: (context, state) {
          final auth = ref.read(authControllerProvider);
          if (auth is! AuthAuthenticated) return AppRoutes.login;

          final role = auth.user.role;
          final isAdmin = role == 'admin' || role == 'administrador';

          // Si no es admin, redirige al perfil propio
          if (!isAdmin) {
            return AppRoutes.perfil;
          }
          return null;
        },
        builder: (c, s) => const UsuariosListPage(),
        routes: [
          GoRoute(path: 'new', builder: (c, s) => const UserFormPage()),
          GoRoute(
            path: ':id',
            builder: (c, s) => UserDetailPage(userId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.perfil, builder: (c, s) => const PerfilScreen()),
      GoRoute(
        path: AppRoutes.rules,
        builder: (c, s) => const RulesHomeScreen(),
        routes: [
          GoRoute(
            path: 'vision-mission',
            builder: (c, s) => const VisionMissionScreen(),
          ),
          GoRoute(path: 'policies', builder: (c, s) => const PoliciesScreen()),
          GoRoute(
            path: 'responsibilities',
            builder: (c, s) => const RoleResponsibilitiesScreen(),
          ),
          GoRoute(
            path: 'procedures',
            builder: (c, s) => const ProceduresScreen(),
          ),
          GoRoute(path: 'search', builder: (c, s) => const RulesSearchScreen()),
          GoRoute(
            path: 'admin',
            redirect: (context, state) {
              final auth = ref.read(authControllerProvider);
              if (auth is! AuthAuthenticated) return AppRoutes.login;
              final role = auth.user.role;
              final isAdmin = role == 'admin' || role == 'administrador';
              return isAdmin ? null : '${AppRoutes.rules}/denied';
            },
            builder: (c, s) => const AdminManageRulesScreen(),
          ),
          GoRoute(
            path: 'denied',
            builder: (c, s) => const RulesAccessDeniedScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.configuracion,
        builder: (c, s) => const ConfiguracionScreen(),
        routes: [
          GoRoute(
            path: 'empresa',
            redirect: (context, state) {
              final auth = ref.read(authControllerProvider);
              if (auth is! AuthAuthenticated) return AppRoutes.login;
              final role = auth.user.role;
              final isAdmin = role == 'admin' || role == 'administrador';
              return isAdmin ? null : AppRoutes.configuracion;
            },
            builder: (c, s) => const CompanySettingsScreen(),
          ),
          GoRoute(
            path: 'servidor',
            redirect: (context, state) {
              if (!kDebugMode) return AppRoutes.configuracion;
              final auth = ref.read(authControllerProvider);
              if (auth is! AuthAuthenticated) return AppRoutes.login;
              final role = auth.user.role;
              final isAdmin = role == 'admin' || role == 'administrador';
              return isAdmin ? null : AppRoutes.configuracion;
            },
            builder: (c, s) => const ApiEndpointSettingsScreen(),
          ),
          GoRoute(path: 'tema', builder: (c, s) => const ThemeSettingsScreen()),
          GoRoute(
            path: 'pantalla',
            builder: (c, s) => const DisplaySettingsScreen(),
          ),
          GoRoute(
            path: 'impresora',
            builder: (c, s) => const PrinterSettingsScreen(),
          ),
          GoRoute(
            path: 'permisos',
            redirect: (context, state) {
              final auth = ref.read(authControllerProvider);
              if (auth is! AuthAuthenticated) return AppRoutes.login;
              final role = auth.user.role;
              final isAdmin = role == 'admin' || role == 'administrador';
              return isAdmin ? null : AppRoutes.configuracion;
            },
            builder: (c, s) => const PermissionsSettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Bridge to allow GoRouter to refresh when a Riverpod StateNotifier changes.
///
/// This uses StateNotifier.stream (available in Riverpod 2/3 compatibility).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
