import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_providers.dart';
import '../data/ai_letters_api.dart';
import '../data/company_settings_api.dart';
import '../data/letters_api.dart';
import '../data/letters_repository.dart';

final lettersApiProvider = Provider<LettersApi>((ref) {
  return LettersApi(ref.watch(apiClientProvider).dio);
});

final aiLettersApiProvider = Provider<AiLettersApi>((ref) {
  return AiLettersApi(ref.watch(apiClientProvider).dio);
});

final companySettingsApiProvider = Provider<CompanySettingsApi>((ref) {
  return CompanySettingsApi(ref.watch(apiClientProvider).dio);
});

final lettersRepositoryProvider = Provider<LettersRepository>((ref) {
  return LettersRepository(
    lettersApi: ref.watch(lettersApiProvider),
    aiApi: ref.watch(aiLettersApiProvider),
    companySettingsApi: ref.watch(companySettingsApiProvider),
    db: ref.watch(localDbProvider),
  );
});
