import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_sort.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skills_list_view_notifier.g.dart';

typedef SkillsListViewState = ({
  String searchQuery,
  SkillSource? sourceFilter,
  bool? enabledFilter,
  SkillSort sort,
});

/// Retains list choices across route replacement, independently per workspace.
@Riverpod(keepAlive: true)
class SkillsListViewNotifier extends _$SkillsListViewNotifier {
  @override
  SkillsListViewState build(String workspaceId) =>
      (searchQuery: '', sourceFilter: null, enabledFilter: null, sort: .name);

  void setSearchQuery(String value) {
    state = (
      searchQuery: value,
      sourceFilter: state.sourceFilter,
      enabledFilter: state.enabledFilter,
      sort: state.sort,
    );
  }

  void setSourceFilter(SkillSource? value) {
    state = (
      searchQuery: state.searchQuery,
      sourceFilter: value,
      enabledFilter: state.enabledFilter,
      sort: state.sort,
    );
  }

  void setEnabledFilter({required bool? value}) {
    state = (
      searchQuery: state.searchQuery,
      sourceFilter: state.sourceFilter,
      enabledFilter: value,
      sort: state.sort,
    );
  }

  void setSort(SkillSort value) {
    state = (
      searchQuery: state.searchQuery,
      sourceFilter: state.sourceFilter,
      enabledFilter: state.enabledFilter,
      sort: value,
    );
  }
}
