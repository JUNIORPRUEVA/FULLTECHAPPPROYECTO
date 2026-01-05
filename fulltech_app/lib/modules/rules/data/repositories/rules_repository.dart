import 'package:dio/dio.dart';

import '../datasources/rules_remote_datasource.dart';
import '../models/rules_content.dart';
import '../models/rules_page.dart';
import '../models/rules_query.dart';

class RulesRepository {
  final RulesRemoteDataSource _remote;
  CancelToken? _cancelToken;

  RulesRepository(this._remote);

  void cancelOngoing() {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
  }

  Future<RulesPage> list(RulesQuery query) async {
    _cancelToken ??= CancelToken();
    return _remote.list(query, cancelToken: _cancelToken);
  }

  Future<RulesContent> get(String id) {
    return _remote.getById(id);
  }

  Future<RulesContent> create(RulesContent draft) {
    return _remote.create(draft);
  }

  Future<RulesContent> update(String id, Map<String, dynamic> patch) {
    return _remote.update(id, patch);
  }

  Future<void> delete(String id) {
    return _remote.delete(id);
  }

  Future<RulesContent> toggleActive(String id) {
    return _remote.toggleActive(id);
  }
}
