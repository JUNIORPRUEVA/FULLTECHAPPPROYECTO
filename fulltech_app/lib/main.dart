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

  // Load API endpoint settings early to avoid baseUrl races on desktop.
  // (In release builds, local overrides are always disabled.)
  ApiEndpointSettings? savedSettings;
  try {
    final prefs = await SharedPreferences.getInstance();
    savedSettings = loadApiEndpointSettings(prefs);
  } catch (_) {
    savedSettings = null;
  }

  if (kDebugMode && savedSettings != null) {
    applyApiEndpointSettings(savedSettings);
  } else {
    AppConfig.setRuntimeApiBaseUrlOverride(null);
    AppConfig.setRuntimeCrmApiBaseUrlOverride(null);
  }

  final db = getLocalDb();
  await db.init();

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

        // IMPORTANT: switching server changes the session namespace
        // (sessions are stored per-baseUrl). Reload the appropriate session.
        // This avoids random logouts caused by provider rebuilds.
        Future.microtask(
          () => ref.read(authControllerProvider.notifier).bootstrap(),
        );
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
