import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_providers.dart';
import '../data/cartas_api.dart';

final cartasApiProvider = Provider<CartasApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CartasApi(apiClient.dio);
});
