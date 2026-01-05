class CrmQuickReply {
  final String id;
  final String title;
  final String category;
  final String content;
  final String? keywords;
  final bool allowComment;
  final bool isActive;

  const CrmQuickReply({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.keywords,
    required this.allowComment,
    required this.isActive,
  });

  factory CrmQuickReply.fromJson(Map<String, dynamic> json) {
    return CrmQuickReply(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      keywords: json['keywords'] as String?,
      allowComment: (json['allowComment'] ?? json['allow_comment'] ?? true) as bool,
      isActive: (json['isActive'] ?? json['is_active'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'content': content,
      'keywords': keywords,
      'allowComment': allowComment,
      'isActive': isActive,
    };
  }
}
