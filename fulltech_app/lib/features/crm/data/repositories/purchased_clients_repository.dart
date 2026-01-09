import '../datasources/purchased_clients_remote_datasource.dart';
import '../models/purchased_client.dart';

abstract class PurchasedClientsRepository {
  Future<PurchasedClientsResponse> getPurchasedClients({
    String? search,
    int page = 1,
    int limit = 30,
  });

  Future<PurchasedClient> getPurchasedClient(String clientId);

  Future<PurchasedClient> updatePurchasedClient(
    String clientId, {
    String? displayName,
    String? phone,
    String? note,
    String? assignedUserId,
    String? productId,
  });

  Future<String> deletePurchasedClient(String clientId, {bool hardDelete = false});
}

class PurchasedClientsRepositoryImpl implements PurchasedClientsRepository {
  final PurchasedClientsRemoteDatasource _remoteDatasource;

  PurchasedClientsRepositoryImpl({
    required PurchasedClientsRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Future<PurchasedClientsResponse> getPurchasedClients({
    String? search,
    int page = 1,
    int limit = 30,
  }) async {
    return await _remoteDatasource.getPurchasedClients(
      search: search,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<PurchasedClient> getPurchasedClient(String clientId) async {
    return await _remoteDatasource.getPurchasedClient(clientId);
  }

  @override
  Future<PurchasedClient> updatePurchasedClient(
    String clientId, {
    String? displayName,
    String? phone,
    String? note,
    String? assignedUserId,
    String? productId,
  }) async {
    return await _remoteDatasource.updatePurchasedClient(
      clientId,
      displayName: displayName,
      phone: phone,
      note: note,
      assignedUserId: assignedUserId,
      productId: productId,
    );
  }

  @override
  Future<String> deletePurchasedClient(String clientId, {bool hardDelete = false}) async {
    return await _remoteDatasource.deletePurchasedClient(
      clientId,
      hardDelete: hardDelete,
    );
  }
}