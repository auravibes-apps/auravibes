import 'package:auravibes_app/domain/entities/workspace_tool.dart';

class SetConversationToolPermissionUseCase {
  const SetConversationToolPermissionUseCase({
    required Future<bool> Function(
      String conversationId,
      String toolId, {
      required ToolPermissionMode permissionMode,
    })
    setConversationToolPermission,
  }) : _setConversationToolPermission = setConversationToolPermission;

  final Future<bool> Function(
    String conversationId,
    String toolId, {
    required ToolPermissionMode permissionMode,
  })
  _setConversationToolPermission;

  Future<bool> call({
    required String? conversationId,
    required String toolId,
    required ToolPermissionMode permissionMode,
  }) {
    if (conversationId == null || conversationId.isEmpty) {
      return Future.value(true);
    }

    return _setConversationToolPermission(
      conversationId,
      toolId,
      permissionMode: permissionMode,
    );
  }
}
