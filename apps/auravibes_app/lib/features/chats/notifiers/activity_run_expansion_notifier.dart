import 'package:riverpod/riverpod.dart';

typedef ActivityRunExpansionState = ({
  bool isLive,
  bool traceExpanded,
  Set<String> expandedToolGroupIds,
  Set<String> expandedToolIds,
});

class ActivityRunExpansionNotifier
    extends Notifier<Map<String, Map<String, ActivityRunExpansionState>>> {
  static Set<String> updateExpandedIds({
    required Set<String> expandedIds,
    required String id,
    required bool isExpanded,
  }) => {
    for (final expandedId in expandedIds)
      if (isExpanded || expandedId != id) expandedId,
    if (isExpanded) id,
  };

  @override
  Map<String, Map<String, ActivityRunExpansionState>> build() => {};

  void updateExpansion({
    required String conversationId,
    required String activityRunId,
    required ActivityRunExpansionState initialState,
    required ActivityRunExpansionState Function(ActivityRunExpansionState)
    update,
  }) {
    final expansionByRun =
        state[conversationId] ?? const <String, ActivityRunExpansionState>{};
    state = {
      ...state,
      conversationId: {
        ...expansionByRun,
        activityRunId: update(expansionByRun[activityRunId] ?? initialState),
      },
    };
  }
}

final activityRunExpansionProvider =
    NotifierProvider<
      ActivityRunExpansionNotifier,
      Map<String, Map<String, ActivityRunExpansionState>>
    >(ActivityRunExpansionNotifier.new);
