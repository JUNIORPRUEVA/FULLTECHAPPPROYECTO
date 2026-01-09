import 'package:uuid/uuid.dart';
import '../../../../core/services/network_info.dart';
import '../../../../core/storage/local_db.dart';
import '../datasources/services_local_datasource.dart';
import '../datasources/services_remote_datasource.dart';
import '../models/service_model.dart';

class ServicesRepository {
  final ServicesLocalDatasource _localDatasource;
  final ServicesRemoteDatasource _remoteDatasource;
  final NetworkInfo _networkInfo;
  final LocalDb _localDb;

  ServicesRepository({
    required ServicesLocalDatasource localDatasource,
    required ServicesRemoteDatasource remoteDatasource,
    required NetworkInfo networkInfo,
    required LocalDb localDb,
  }) : _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource,
       _networkInfo = networkInfo,
       _localDb = localDb;

  Future<List<ServiceModel>> getServices({
    String? query,
    bool? isActive,
    bool forceRemote = false,
  }) async {
    if (forceRemote || await _networkInfo.isConnected) {
      try {
        final services = await _remoteDatasource.fetchServices(
          query: query,
          isActive: isActive,
        );

        // Update local cache
        for (final service in services) {
          await _localDatasource.insertOrUpdateService(service);
        }

        return services;
      } catch (e) {
        print('Error fetching services remotely: $e');
        // Fallback to local
      }
    }

    // Return from local DB
    if (isActive == true) {
      return await _localDatasource.getActiveServices();
    }
    return await _localDatasource.getAllServices();
  }

  Future<ServiceModel?> getServiceById(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        final service = await _remoteDatasource.fetchServiceById(id);
        await _localDatasource.insertOrUpdateService(service);
        return service;
      } catch (e) {
        print('Error fetching service remotely: $e');
      }
    }

    return await _localDatasource.getServiceById(id);
  }

  Future<ServiceModel> createService({
    required String name,
    String? description,
    double? defaultPrice,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final service = await _remoteDatasource.createService(
          name: name,
          description: description,
          defaultPrice: defaultPrice,
        );
        await _localDatasource.insertOrUpdateService(service);
        return service;
      } catch (e) {
        print('Error creating service remotely: $e');
        rethrow;
      }
    } else {
      // Create locally and queue for sync
      final now = DateTime.now();
      final service = ServiceModel(
        id: const Uuid().v4(),
        empresaId: '', // Will be set by backend
        name: name,
        description: description,
        defaultPrice: defaultPrice,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        syncStatus: 'pending',
      );

      await _localDatasource.insertOrUpdateService(service);
      await _localDb.enqueueSync(
        module: 'services',
        op: 'create',
        entityId: service.id,
        payloadJson: service.toJson().toString(),
      );

      return service;
    }
  }

  Future<ServiceModel> updateService({
    required String id,
    String? name,
    String? description,
    double? defaultPrice,
    bool? isActive,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final service = await _remoteDatasource.updateService(
          id: id,
          name: name,
          description: description,
          defaultPrice: defaultPrice,
          isActive: isActive,
        );
        await _localDatasource.insertOrUpdateService(service);
        return service;
      } catch (e) {
        print('Error updating service remotely: $e');
        rethrow;
      }
    } else {
      // Update locally and queue for sync
      final existing = await _localDatasource.getServiceById(id);
      if (existing == null) {
        throw Exception('Service not found locally');
      }

      final updated = existing.copyWith(
        name: name ?? existing.name,
        description: description ?? existing.description,
        defaultPrice: defaultPrice ?? existing.defaultPrice,
        isActive: isActive ?? existing.isActive,
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      );

      await _localDatasource.insertOrUpdateService(updated);
      await _localDb.enqueueSync(
        module: 'services',
        op: 'update',
        entityId: id,
        payloadJson: updated.toJson().toString(),
      );

      return updated;
    }
  }

  Future<void> deleteService(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDatasource.deleteService(id);
        await _localDatasource.deleteService(id);
      } catch (e) {
        print('Error deleting service remotely: $e');
        rethrow;
      }
    } else {
      await _localDatasource.deleteService(id);
      await _localDb.enqueueSync(
        module: 'services',
        op: 'delete',
        entityId: id,
        payloadJson: '{}',
      );
    }
  }

  Future<List<ServiceModel>> searchServices(String query) async {
    return await _localDatasource.searchServices(query);
  }
}
