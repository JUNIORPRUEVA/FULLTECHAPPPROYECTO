import 'rules_category.dart';

class RulesContent {
  final String id;
  final String title;
  final RulesCategory category;
  final String content;

  final bool visibleToAll;
  final List<String> roleVisibility;

  final bool isActive;
  final int orderIndex;

  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RulesContent({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.visibleToAll,
    required this.roleVisibility,
    required this.isActive,
    required this.orderIndex,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RulesContent.draft({
    required String title,
    required RulesCategory category,
    required String content,
    required bool visibleToAll,
    required List<String> roleVisibility,
    required bool isActive,
    required int orderIndex,
  }) {
    final now = DateTime.now();
    return RulesContent(
      id: '',
      title: title,
      category: category,
      content: content,
      visibleToAll: visibleToAll,
      roleVisibility: roleVisibility,
      isActive: isActive,
      orderIndex: orderIndex,
      createdBy: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  factory RulesContent.fromJson(Map<String, dynamic> json) {
    return RulesContent(
      id: json['id'] as String,
      title: (json['title'] ?? '') as String,
      category: RulesCategory.fromApi((json['category'] ?? 'GENERAL') as String),
      content: (json['content'] ?? '') as String,
      visibleToAll: (json['visibleToAll'] ?? true) as bool,
      roleVisibility:
          (json['roleVisibility'] as List<dynamic>? ?? const []).cast<String>(),
      isActive: (json['isActive'] ?? true) as bool,
      orderIndex: (json['orderIndex'] as num? ?? 0).toInt(),
      createdBy: (json['createdBy'] ?? '') as String,
      createdAt: DateTime.parse((json['createdAt'] as String)),
      updatedAt: DateTime.parse((json['updatedAt'] as String)),
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'title': title,
      'category': category.apiValue,
      'content': content,
      'visibleToAll': visibleToAll,
      'roleVisibility': roleVisibility,
      'isActive': isActive,
      'orderIndex': orderIndex,
    };
  }
}
