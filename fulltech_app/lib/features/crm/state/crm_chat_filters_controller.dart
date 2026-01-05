import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crm_chat_filters_state.dart';

class CrmChatFiltersController extends StateNotifier<CrmChatFiltersState> {
  CrmChatFiltersController() : super(CrmChatFiltersState.initial());

  void setSearchText(String value) {
    state = state.copyWith(searchText: value);
  }

  void setStatus(String value) {
    state = state.copyWith(status: value);
  }

  void setProductId(String? productId) {
    state = state.copyWith(productId: productId);
  }

  void clear() {
    state = CrmChatFiltersState.initial();
  }
}
