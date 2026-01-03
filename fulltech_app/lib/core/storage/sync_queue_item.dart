class SyncQueueItem {
  final String id;
  final String module;
  final String op; // create|update|delete
  final String entityId;
  final String payloadJson;
  final int createdAtMs;
  final int status; // 0=pending, 1=sent, 2=error

  const SyncQueueItem({
    required this.id,
    required this.module,
    required this.op,
    required this.entityId,
    required this.payloadJson,
    required this.createdAtMs,
    required this.status,
  });
}
