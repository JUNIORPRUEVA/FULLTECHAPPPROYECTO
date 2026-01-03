
  import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/state/auth_providers.dart';
import '../../features/auth/state/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/access_revoked_screen.dart';
import '../../features/crm/presentation/pages/crm_home_page.dart';
import '../../features/crm/presentation/pages/thread_chat_page.dart';
import '../../features/crm/presentation/pages/customer_detail_page.dart';
import '../../features/presupuesto/screens/presupuesto_list_screen.dart';
import '../../features/operaciones/screens/operaciones_list_screen.dart';
import '../../features/garantia/screens/garantia_list_screen.dart';
import '../../features/nomina/screens/nomina_list_screen.dart';
import '../../features/ventas/screens/ventas_list_screen.dart';
import '../../features/catalogo/screens/catalogo_screen.dart';
import '../../features/tecnico/screens/tecnico_list_screen.dart';
import '../../features/contrato/screens/contrato_list_screen.dart';
import '../../features/guagua/screens/guagua_list_screen.dart';
import '../../features/contabilidad/screens/contabilidad_list_screen.dart';
import '../../features/mantenimiento/screens/mantenimiento_list_screen.dart';
import '../../features/ponchado/screens/ponchado_list_screen.dart';
import '../../features/rrhh/screens/rrhh_list_screen.dart';
import '../../features/perfil/screens/perfil_screen.dart';
import '../../features/configuracion/screens/configuracion_screen.dart';
import '../../features/configuracion/screens/company_settings_screen.dart';
import '../../features/configuracion/screens/theme_settings_screen.dart';
import '../../features/configuracion/screens/display_settings_screen.dart';
import '../../features/usuarios/presentation/pages/user_detail_page.dart';
import '../../features/usuarios/presentation/pages/usuarios_list_page.dart';
import '../../features/usuarios/presentation/pages/user_form_page.dart';
import 'app_routes.dart';

GoRouter createRouter(WidgetRef ref) {
  String? redirect(BuildContext context, GoRouterState state) {
    final auth = ref.read(authControllerProvider);
    final isLoggingIn = state.matchedLocation == AppRoutes.login;

    if (auth is AuthUnknown) return null; // waiting bootstrap

    final isAuthed = auth is AuthAuthenticated;
    if (!isAuthed && !isLoggingIn) return AppRoutes.login;
    if (isAuthed && isLoggingIn) return AppRoutes.crm;
    return null;
  }

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authControllerProvider.notifier).stream,
    ),
    redirect: redirect,
    routes: [
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
            builder: (c, s) => ThreadChatPage(threadId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'customers/:id',
            builder: (c, s) => CustomerDetailPage(customerId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.presupuesto,
        builder: (c, s) => const PresupuestoListScreen(),
      ),
      GoRoute(
        path: AppRoutes.operaciones,
        builder: (c, s) => const OperacionesListScreen(),
      ),
      GoRoute(
        path: AppRoutes.garantia,
        builder: (c, s) => const GarantiaListScreen(),
      ),
      GoRoute(
        path: AppRoutes.nomina,
        builder: (c, s) => const NominaListScreen(),
      ),
      GoRoute(
        path: AppRoutes.ventas,
        builder: (c, s) => const VentasListScreen(),
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
        builder: (c, s) => const ContabilidadListScreen(),
      ),
      GoRoute(
        path: AppRoutes.mantenimiento,
        builder: (c, s) => const MantenimientoListScreen(),
      ),
      GoRoute(
        path: AppRoutes.ponchado,
        builder: (c, s) => const PonchadoListScreen(),
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
          GoRoute(path: 'tema', builder: (c, s) => const ThemeSettingsScreen()),
          GoRoute(
            path: 'pantalla',
            redirect: (context, state) {
              final auth = ref.read(authControllerProvider);
              if (auth is! AuthAuthenticated) return AppRoutes.login;
              final role = auth.user.role;
              final isAdmin = role == 'admin' || role == 'administrador';
              return isAdmin ? null : AppRoutes.configuracion;
            },
            builder: (c, s) => const DisplaySettingsScreen(),
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
