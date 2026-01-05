import 'package:dio/dio.dart';

import '../models/rules_content.dart';
import '../models/rules_page.dart';
import '../models/rules_query.dart';

class RulesRemoteDataSource {
  final Dio _dio;

  RulesRemoteDataSource(this._dio);

  Future<RulesPage> list(RulesQuery query, {CancelToken? cancelToken}) async {
    final res = await _dio.get(
      '/rules',
      queryParameters: query.toQueryParams(),
      cancelToken: cancelToken,
    );

    return RulesPage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RulesContent> getById(String id, {CancelToken? cancelToken}) async {
    final res = await _dio.get('/rules/$id', cancelToken: cancelToken);
    final data = res.data as Map<String, dynamic>;
    return RulesContent.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<RulesContent> create(RulesContent draft) async {
    final res = await _dio.post('/rules', data: draft.toUpsertJson());
    final data = res.data as Map<String, dynamic>;
    return RulesContent.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<RulesContent> update(String id, Map<String, dynamic> patch) async {
    final res = await _dio.put('/rules/$id', data: patch);
    final data = res.data as Map<String, dynamic>;
    return RulesContent.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/rules/$id');
  }

  Future<RulesContent> toggleActive(String id) async {
    await _dio.patch('/rules/$id/toggle-active');
    // toggle-active only returns partial fields; refetch full detail
    return getById(id);
  }
}
