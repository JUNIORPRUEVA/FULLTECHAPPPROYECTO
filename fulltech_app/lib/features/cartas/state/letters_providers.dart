import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/features/auth/state/auth_providers.dart';
import 'package:fulltech_app/features/cartas/data/letters_api.dart';

final lettersApiProvider = Provider<LettersApi>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return LettersApi(dio);
});
