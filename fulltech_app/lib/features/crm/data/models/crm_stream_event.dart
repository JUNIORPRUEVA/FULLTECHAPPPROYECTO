class CrmStreamEvent {
  final String type;
  final String? chatId;
  final String? messageId;
  final String? remoteMessageId;
  final String? status;
  final String? targetUserId;

  const CrmStreamEvent({
    required this.type,
    this.chatId,
    this.messageId,
    this.remoteMessageId,
    this.status,
    this.targetUserId,
  });

  factory CrmStreamEvent.fromJson(Map<String, dynamic> json) {
    return CrmStreamEvent(
      type: (json['type'] ?? '').toString(),
      chatId: json['chatId']?.toString(),
      messageId: json['messageId']?.toString(),
      remoteMessageId: json['remoteMessageId']?.toString(),
      status: json['status']?.toString(),
      targetUserId: json['targetUserId']?.toString(),
    );
  }
}
