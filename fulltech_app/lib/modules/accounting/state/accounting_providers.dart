import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/state/auth_providers.dart';
import '../data/accounting_repository.dart';
import '../data/local_accounting_repository.dart';
import 'biweekly_close_controller.dart';
import 'biweekly_close_state.dart';

final accountingRepositoryProvider = Provider<AccountingRepository>((ref) {
  return LocalAccountingRepository(db: ref.watch(localDbProvider));
});

final biweeklyCloseControllerProvider =
    StateNotifierProvider<BiweeklyCloseController, BiweeklyCloseState>((ref) {
      final ctrl = BiweeklyCloseController(
        repo: ref.watch(accountingRepositoryProvider),
      );
      // Load initial snapshot.
      ctrl.refresh(showLoading: true);
      return ctrl;
    });
