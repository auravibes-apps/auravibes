enum ConversationSkillAction { add, useNow }

typedef ConversationSkillActionRequest = ({
  String workspaceId,
  String conversationId,
  String slug,
  ConversationSkillAction action,
  String Function(String title) userRequestForSkill,
  String? expectedCatalogRevision,
});

enum ConversationSkillActionResult {
  added,
  alreadyAdded,
  inProgress,
  used,
  stale,
  unavailable,
  unauthorized,
  credentialsMissing,
  credentialsUnknown,
}
