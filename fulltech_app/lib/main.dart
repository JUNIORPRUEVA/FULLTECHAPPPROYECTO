import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app.dart';
import 'core/services/api_client.dart';
import 'core/storage/local_db.dart';
import 'features/auth/state/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Helps ensure PDFium/pdfrx is initialized before any PdfViewer builds.
  pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);

  final db = getLocalDb();
  await db.init();
  final api = await ApiClient.create(db);

  runApp(
    ProviderScope(
      overrides: [
        localDbProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(api),
      ],
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
  @override
  void initState() {
    super.initState();
    // Restore existing session from local DB.
    Future.microtask(() => ref.read(authControllerProvider.notifier).bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    return const FulltechApp();
  }
}
