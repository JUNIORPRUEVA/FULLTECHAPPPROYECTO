import 'package:dio/dio.dart';
import '../models/punch_record.dart';

class PunchRemoteDataSource {
  final Dio dio;

  PunchRemoteDataSource(this.dio);

  BaseOptions get _defaultOptions => BaseOptions(
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  );

  Future<PunchRecord> createPunch(
    CreatePunchDto dto, {
    CancelToken? cancelToken,
  }) async {
    final response = await dio.post(
      '/attendance/punches',
      data: dto.toJson(),
      options: Options(
        extra: const {'offlineQueue': false},
      ).copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return PunchRecord.fromJson(response.data);
  }

  Future<PunchListResponse> listPunches({
    String? from,
    String? to,
    String? userId,
    PunchType? type,
    int limit = 100,
    int offset = 0,
    CancelToken? cancelToken,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;
    if (userId != null) queryParams['userId'] = userId;
    if (type != null) {
      queryParams['type'] = type == PunchType.in_
          ? 'IN'
          : type == PunchType.lunchStart
          ? 'LUNCH_START'
          : type == PunchType.lunchEnd
          ? 'LUNCH_END'
          : 'OUT';
    }

    final response = await dio.get(
      '/attendance/punches',
      queryParameters: queryParams,
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return PunchListResponse.fromJson(response.data);
  }

  Future<PunchRecord> getPunch(String id, {CancelToken? cancelToken}) async {
    final response = await dio.get(
      '/attendance/punches/$id',
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return PunchRecord.fromJson(response.data);
  }

  Future<PunchRecord> updatePunch(
    String id,
    Map<String, dynamic> updates, {
    CancelToken? cancelToken,
  }) async {
    final response = await dio.put(
      '/attendance/punches/$id',
      data: updates,
      options: Options(
        extra: const {'offlineQueue': false},
      ).copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return PunchRecord.fromJson(response.data);
  }

  Future<void> deletePunch(String id, {CancelToken? cancelToken}) async {
    await dio.delete(
      '/attendance/punches/$id',
      options: Options(
        extra: const {'offlineQueue': false},
      ).copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
  }

  Future<PunchSummary> getSummary({
    String? from,
    String? to,
    String? userId,
    CancelToken? cancelToken,
  }) async {
    final queryParams = <String, dynamic>{};
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;
    if (userId != null) queryParams['userId'] = userId;

    final response = await dio.get(
      '/attendance/summary',
      queryParameters: queryParams,
      options: Options().copyWith(
        sendTimeout: _defaultOptions.sendTimeout,
        receiveTimeout: _defaultOptions.receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return PunchSummary.fromJson(response.data);
  }
}
