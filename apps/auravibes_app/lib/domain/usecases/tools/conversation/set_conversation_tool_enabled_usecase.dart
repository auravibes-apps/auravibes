class SetConversationToolEnabledUseCase {
  const SetConversationToolEnabledUseCase({
    required Future<bool> Function(
      String conversationId,
      String toolId, {
      required bool isEnabled,
    })
    setConversationToolEnabled,
  }) : _setConversationToolEnabled = setConversationToolEnabled;

  final Future<bool> Function(
    String conversationId,
    String toolId, {
    required bool isEnabled,
  })
  _setConversationToolEnabled;

  Future<bool> call({
    required String? conversationId,
    required String toolId,
    required bool isEnabled,
  }) {
    if (conversationId == null || conversationId.isEmpty) {
      return Future.value(true);
    }

    return _setConversationToolEnabled(
      conversationId,
      toolId,
      isEnabled: isEnabled,
    );
  }
}
