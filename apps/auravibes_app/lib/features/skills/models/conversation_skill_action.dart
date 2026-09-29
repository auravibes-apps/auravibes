enum ConversationSkillAction { add, useNow }

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
