import 'package:auravibes_app/domain/entities/workspace_tool.dart';

class GetContextAwareToolEntitiesUseCase {
  const GetContextAwareToolEntitiesUseCase({
    required Future<List<WorkspaceToolEntity>> Function(String, String)
    getAvailableToolEntities,
  }) : _getAvailableToolEntities = getAvailableToolEntities;

  final Future<List<WorkspaceToolEntity>> Function(String, String)
  _getAvailableToolEntities;

  Future<List<WorkspaceToolEntity>> call({
    required String conversationId,
    required String workspaceId,
  }) {
    return _getAvailableToolEntities(conversationId, workspaceId);
  }
}
