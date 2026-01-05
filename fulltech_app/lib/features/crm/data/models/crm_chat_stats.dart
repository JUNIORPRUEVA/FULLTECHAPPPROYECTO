class CrmChatStats {
  final int total;
  final Map<String, int> byStatus;
  final int importantCount;
  final int unreadTotal;

  const CrmChatStats({
    required this.total,
    required this.byStatus,
    required this.importantCount,
    required this.unreadTotal,
  });

  factory CrmChatStats.fromJson(Map<String, dynamic> json) {
    final by = <String, int>{};
    final raw = json['byStatus'] ?? json['by_status'];
    if (raw is Map) {
      for (final e in raw.entries) {
        by[e.key.toString()] = (e.value as num? ?? 0).toInt();
      }
    }

    return CrmChatStats(
      total: (json['total'] as num? ?? 0).toInt(),
      byStatus: by,
      importantCount: (json['importantCount'] as num? ?? json['important_count'] as num? ?? 0).toInt(),
      unreadTotal: (json['unreadTotal'] as num? ?? json['unread_total'] as num? ?? 0).toInt(),
    );
  }
}
