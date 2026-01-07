import 'dart:ui';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/api_endpoint_settings.dart';
import 'core/storage/local_db.dart';
import 'features/auth/state/auth_providers.dart';
import 'features/auth/state/auth_state.dart';
import 'core/services/app_config.dart';
import 'core/state/api_endpoint_settings_provider.dart';

import 'features/crm/services/crm_image_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Workaround for a known Flutter Windows keyboard assertion that can spam
  // the console and feel like a freeze in debug mode.
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    if (msg.contains(
      'Attempted to send a key down event when no keys are in keysPressed',
    )) {
      if (kDebugMode) {
        debugPrint('[UI] Ignored RawKeyboard assertion: $msg');
      }
      return;
    }
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final msg = error.toString();
    if (msg.contains(
      'Attempted to send a key down event when no keys are in keysPressed',
    )) {
      if (kDebugMode) {
        debugPrint('[UI] Ignored platform RawKeyboard error: $msg');
      }
      return true;
    }
    return false;
  };

  // Helps ensure PDFium/pdfrx is initialized before any PdfViewer builds.
  pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);

  final db = getLocalDb();
  await db.init();

  // Apply API endpoint overrides only when the persisted session is admin.
  // In debug builds, allow selecting cloud/local consistently even before login.
  ApiEndpointSettings? savedSettings;
  try {
    final prefs = await SharedPreferences.getInstance();
    savedSettings = loadApiEndpointSettings(prefs);
  } catch (_) {
    savedSettings = null;
  }

  try {
    await db.readSession();
    // If there is a saved session, we still apply endpoint settings in debug
    // to keep behavior consistent between login and authenticated flows.
    if (kDebugMode && savedSettings != null) {
      // Apply saved settings in debug so login+post-login are consistent.
      // This prevents "login succeeds then immediately logs out" when the app
      // switches backend after authentication.
      applyApiEndpointSettings(savedSettings);
    } else {
      AppConfig.setRuntimeApiBaseUrlOverride(null);
      AppConfig.setRuntimeCrmApiBaseUrlOverride(null);
    }
  } catch (_) {
    AppConfig.setRuntimeApiBaseUrlOverride(null);
    AppConfig.setRuntimeCrmApiBaseUrlOverride(null);
  }

  // CRM media cache cleanup (7-day TTL). Best-effort and non-blocking.
  CrmImageCache.instance.startMaintenance();
  unawaited(CrmImageCache.instance.cleanupExpired());

  runApp(
    ProviderScope(
      overrides: [localDbProvider.overrideWithValue(db)],
      child: const _Bootstrapper(),
    ),
  );
}

class _Bootstrapper extends ConsumerStatefulWidget {
  const _Bootstrapper();

  @override
  ConsumerState<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends ConsumerState<_Bootstrapper> {
  ProviderSubscription<AuthState>? _authSub;
  ProviderSubscription<ApiEndpointSettings>? _apiSettingsSub;

  void _enforceApiForRole() {
    final auth = ref.read(authControllerProvider);
    if (auth is AuthUnknown) return;

    final settings = ref.read(apiEndpointSettingsProvider);

    // Never allow local override in non-debug builds.
    if (!kDebugMode) {
      AppConfig.setRuntimeApiBaseUrlOverride(null);
      AppConfig.setRuntimeCrmApiBaseUrlOverride(null);
      return;
    }

    // In debug builds, allow endpoint settings for everyone so the login screen
    // and authenticated flows use the same backend.
    // (In release builds, local overrides are always disabled.)
    applyApiEndpointSettings(settings);
  }

  @override
  void initState() {
    super.initState();

    // Enforce endpoint rules when auth/settings change.
    _authSub = ref.listenManual<AuthState>(authControllerProvider, (
      prev,
      next,
    ) {
      _enforceApiForRole();
    });
    _apiSettingsSub = ref.listenManual<ApiEndpointSettings>(
      apiEndpointSettingsProvider,
      (prev, next) {
        _enforceApiForRole();
      },
    );

    // Restore existing session from local DB.
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).bootstrap(),
    );

    Future.microtask(_enforceApiForRole);
  }

  @override
  void dispose() {
    _authSub?.close();
    _apiSettingsSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const FulltechApp();
  }
}
