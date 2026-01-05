class CrmChatFiltersState {
  final String searchText;
  final String status;
  final String? productId;

  const CrmChatFiltersState({
    required this.searchText,
    required this.status,
    required this.productId,
  });

  factory CrmChatFiltersState.initial() {
    return const CrmChatFiltersState(
      searchText: '',
      status: 'todos',
      productId: null,
    );
  }

  CrmChatFiltersState copyWith({
    String? searchText,
    String? status,
    String? productId,
    bool clearProductId = false,
  }) {
    return CrmChatFiltersState(
      searchText: searchText ?? this.searchText,
      status: status ?? this.status,
      productId: clearProductId ? null : (productId ?? this.productId),
    );
  }
}
