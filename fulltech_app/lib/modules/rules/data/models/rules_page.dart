import 'rules_content.dart';

class RulesPage {
  final int page;
  final int pageSize;
  final int total;
  final List<RulesContent> items;

  const RulesPage({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory RulesPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(RulesContent.fromJson)
        .toList();

    return RulesPage(
      page: (json['page'] as num? ?? 1).toInt(),
      pageSize: (json['page_size'] as num? ?? 50).toInt(),
      total: (json['total'] as num? ?? items.length).toInt(),
      items: items,
    );
  }
}
