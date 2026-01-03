import '../datasources/crm_remote_datasource.dart';
import '../models/crm_message.dart';
import '../models/crm_thread.dart';
import 'package:file_picker/file_picker.dart';

class CrmRepository {
  final CrmRemoteDataSource _remote;

  CrmRepository(this._remote);

  Future<ThreadsPage> listThreads({
    String? search,
    String? estado,
    bool? pinned,
    String? assignedUserId,
    int limit = 30,
    int offset = 0,
  }) {
    return _remote.listThreads(
      search: search,
      estado: estado,
      pinned: pinned,
      assignedUserId: assignedUserId,
      limit: limit,
      offset: offset,
    );
  }

  Future<CrmThread> getThread(String id) => _remote.getThread(id);

  Future<CrmThread> patchThread(String id, Map<String, dynamic> patch) =>
      _remote.patchThread(id, patch);

  Future<MessagesPage> listMessages({
    required String threadId,
    int limit = 50,
    DateTime? before,
  }) {
    return _remote.listMessages(threadId: threadId, limit: limit, before: before);
  }

  Future<CrmMessage> postMessage({
    required String threadId,
    required bool fromMe,
    String type = 'text',
    String? body,
    String? mediaUrl,
  }) {
    return _remote.postMessage(
      threadId: threadId,
      fromMe: fromMe,
      type: type,
      body: body,
      mediaUrl: mediaUrl,
    );
  }

  Future<CrmMessage> sendMessage({
    required String threadId,
    String type = 'text',
    String? message,
    String? mediaUrl,
  }) {
    return _remote.sendMessage(
      threadId: threadId,
      type: type,
      message: message,
      mediaUrl: mediaUrl,
    );
  }

  Future<CrmMessage> sendMediaMessage({
    required String threadId,
    required PlatformFile file,
    String? caption,
    String? type,
  }) {
    return _remote.sendMediaMessage(
      threadId: threadId,
      file: file,
      caption: caption,
      type: type,
    );
  }

  Future<ConvertResult> convertThreadToCustomer(String threadId) =>
      _remote.convertThreadToCustomer(threadId);
}
