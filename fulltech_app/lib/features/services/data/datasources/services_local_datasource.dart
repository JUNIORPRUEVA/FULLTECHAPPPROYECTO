import 'dart:convert';
import '../../../../core/storage/local_db.dart';
import '../models/service_model.dart';

class ServicesLocalDatasource {
  final LocalDb _localDb;
  static const String _store = 'services';

  ServicesLocalDatasource(this._localDb);

  Future<List<ServiceModel>> getAllServices() async {
    final jsonList = await _localDb.listEntitiesJson(store: _store);
    return jsonList
        .map(
          (json) =>
              ServiceModel.fromJson(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<ServiceModel>> getActiveServices() async {
    final all = await getAllServices();
    return all.where((s) => s.isActive).toList();
  }

  Future<ServiceModel?> getServiceById(String id) async {
    final json = await _localDb.getEntityJson(store: _store, id: id);
    if (json == null) return null;
    return ServiceModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> insertOrUpdateService(ServiceModel service) async {
    await _localDb.upsertEntity(
      store: _store,
      id: service.id,
      json: jsonEncode(service.toJson()),
    );
  }

  Future<void> deleteService(String id) async {
    await _localDb.deleteEntity(store: _store, id: id);
  }

  Future<void> deleteAll() async {
    await _localDb.clearStore(store: _store);
  }

  Future<List<ServiceModel>> searchServices(String query) async {
    final all = await getAllServices();
    final lowerQuery = query.toLowerCase();
    return all.where((s) {
      return s.name.toLowerCase().contains(lowerQuery) ||
          (s.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
