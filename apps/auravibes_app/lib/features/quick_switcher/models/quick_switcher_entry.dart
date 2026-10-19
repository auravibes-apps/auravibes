enum QuickSwitcherEntryType {
  workspace,
  conversation,
  agent,
  skill,
  newConversation,
  settings,
}

class const QuickSwitcherEntry({
  required this.type,
  required this.workspaceId,
  required this.workspaceName,
  required this.title,
  this.id,
  this.titleKey,
  this.searchTerms = '',
}) {
  final QuickSwitcherEntryType type;
  final String workspaceId;
  final String workspaceName;
  final String title;
  final String? id;
  final String? titleKey;
  final String searchTerms;
}

class const QuickSwitcherEntries({
  required this.entries,
  required this.hasUnavailableResults,
}) {
  final List<QuickSwitcherEntry> entries;
  final bool hasUnavailableResults;
}
