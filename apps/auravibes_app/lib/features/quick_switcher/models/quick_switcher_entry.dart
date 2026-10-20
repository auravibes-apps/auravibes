import 'package:auravibes_app/features/quick_switcher/models/quick_switcher_entry_type.dart';

export 'package:auravibes_app/features/quick_switcher/models/quick_switcher_entry_type.dart';

class const QuickSwitcherEntry({
  required final QuickSwitcherEntryType type,
  required final String workspaceId,
  required final String workspaceName,
  required final String title,
  final String? id,
  final String? titleKey,
  final String searchTerms = '',
});

class const QuickSwitcherEntries({
  required final List<QuickSwitcherEntry> entries,
  required final bool hasUnavailableResults,
});
