import 'rules_category.dart';

class RulesQuery {
  final String? q;
  final RulesCategory? category;
  final String? role;
  final bool? active;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int page;
  final int limit;
  final String sort;

  const RulesQuery({
    this.q,
    this.category,
    this.role,
    this.active,
    this.fromDate,
    this.toDate,
    this.page = 1,
    this.limit = 50,
    this.sort = 'order',
  });

  Map<String, dynamic> toQueryParams() {
    String? dateIso(DateTime? dt) => dt?.toUtc().toIso8601String();

    return {
      if (q != null && q!.trim().isNotEmpty) 'q': q!.trim(),
      if (category != null) 'category': category!.apiValue,
      if (role != null && role!.trim().isNotEmpty) 'role': role!.trim(),
      if (active != null) 'active': active,
      if (fromDate != null) 'fromDate': dateIso(fromDate),
      if (toDate != null) 'toDate': dateIso(toDate),
      'page': page,
      'limit': limit,
      'sort': sort,
    };
  }

  RulesQuery copyWith({
    String? q,
    RulesCategory? category,
    String? role,
    bool? active,
    DateTime? fromDate,
    DateTime? toDate,
    int? page,
    int? limit,
    String? sort,
    bool clearRole = false,
    bool clearCategory = false,
    bool clearActive = false,
    bool clearDates = false,
  }) {
    return RulesQuery(
      q: q ?? this.q,
      category: clearCategory ? null : (category ?? this.category),
      role: clearRole ? null : (role ?? this.role),
      active: clearActive ? null : (active ?? this.active),
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
      page: page ?? this.page,
      limit: limit ?? this.limit,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RulesQuery &&
        other.q == q &&
        other.category == category &&
        other.role == role &&
        other.active == active &&
        other.fromDate == fromDate &&
        other.toDate == toDate &&
        other.page == page &&
        other.limit == limit &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(q, category, role, active, fromDate, toDate, page, limit, sort);
}
