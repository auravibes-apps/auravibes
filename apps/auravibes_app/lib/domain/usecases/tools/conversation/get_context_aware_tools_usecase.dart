class GetContextAwareToolsUseCase {
  const GetContextAwareToolsUseCase({
    required Future<List<String>> Function(String, String) getAvailableTools,
  }) : _getAvailableTools = getAvailableTools;

  final Future<List<String>> Function(String, String) _getAvailableTools;

  Future<List<String>> call({
    required String conversationId,
    required String workspaceId,
  }) {
    return _getAvailableTools(conversationId, workspaceId);
  }
}
