import 'dart:async';

import 'package:auravibes_app/domain/entities/agent_list_query.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agent_list_notifier.freezed.dart';
part 'agent_list_notifier.g.dart';

@riverpod
class AgentListNotifier extends _$AgentListNotifier {
  static const _searchDelay = Duration(milliseconds: 300);

  AgentRepository? _repository;
  Timer? _searchTimer;
  var _generation = 0;

  AgentListState? get _current => switch (state) {
    AsyncData(:final value) => value,
    AsyncLoading() || AsyncError() => null,
  };

  @override
  Future<AgentListState> build(String workspaceId) async {
    final repository = ref.watch(agentRepositoryProvider(workspaceId));
    _repository = repository;
    final _ = ref.onDispose(() => _cancelTimer(_searchTimer));
    final page = await repository.listAgents(.new(workspaceId: workspaceId));

    return AgentListState(agents: page.agents, nextCursor: page.nextCursor);
  }

  void setSearch(String search) {
    final current = _current;
    if (current == null || current.search == search) return;
    _generation++;
    _searchTimer?.cancel();
    state = AsyncData(current.copyWith(search: search, refreshFailed: false));
    _searchTimer = .new(_searchDelay, () => unawaited(_replaceAgents(this)));
  }

  void setType(AgentListType? type) {
    final current = _current;
    if (current == null || current.type == type) return;
    _searchTimer?.cancel();
    _generation++;
    state = AsyncData(current.copyWith(type: type, refreshFailed: false));
    unawaited(_replaceAgents(this));
  }

  void setStatus(AgentListStatus? status) {
    final current = _current;
    if (current == null || current.status == status) return;
    _searchTimer?.cancel();
    _generation++;
    state = AsyncData(current.copyWith(status: status, refreshFailed: false));
    unawaited(_replaceAgents(this));
  }

  Future<void> refresh() {
    _searchTimer?.cancel();
    _generation++;

    return _replaceAgents(this);
  }

  Future<void> retry() {
    if (_current?.loadMoreFailed == true) return loadMore();

    return refresh();
  }

  Future<void> loadMore() => _loadMore(this);

  Future<void> _completeRequest(_AgentPageRequest request) async {
    final page = await _tryListAgents(request.repository, request.query);
    if (!ref.mounted || request.generation != _generation) return;
    state = AsyncData(request.complete(page));
  }

  void _setState(AgentListState value) => state = AsyncData(value);
}

@immutable
@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class const AgentListState._() with _$AgentListState {
  const factory({
    @Default([]) List<AgentListItem> agents,
    @Default('') String search,
    AgentListType? type,
    AgentListStatus? status,
    String? nextCursor,
    @Default(false) bool isRefreshing,
    @Default(false) bool isLoadingMore,
    @Default(false) bool refreshFailed,
    @Default(false) bool loadMoreFailed,
  }) = _AgentListState;

  bool get hasFilters =>
      search.trim().isNotEmpty || type != null || status != null;

  bool get canLoadMore => nextCursor != null && !isLoadingMore && !isRefreshing;
}

AgentListQuery _agentListQuery(
  String workspaceId,
  AgentListState state, {
  String? cursor,
}) => .new(
  workspaceId: workspaceId,
  search: state.search,
  type: state.type,
  status: state.status,
  cursor: cursor,
);

List<AgentListItem> _mergeAgents(
  List<AgentListItem> current,
  List<AgentListItem> next,
) {
  final agentsById = {for (final agent in current) agent.id: agent};
  for (final agent in next) {
    agentsById[agent.id] = agent;
  }

  return agentsById.values.toList();
}

void _cancelTimer(Timer? timer) => timer?.cancel();

Future<void> _loadMore(AgentListNotifier notifier) {
  final request = _loadMoreRequest(notifier);
  if (request == null) return Future.value();

  return notifier._completeRequest(request);
}

Future<void> _replaceAgents(AgentListNotifier notifier) {
  final request = _replaceRequest(notifier);
  if (request == null) return Future.value();

  return notifier._completeRequest(request);
}

typedef _AgentPageRequest = ({
  AgentRepository repository,
  AgentListQuery query,
  int generation,
  AgentListState Function(AgentListPage? page) complete,
});

_AgentPageRequest? _loadMoreRequest(AgentListNotifier notifier) {
  final context = _requestContext(notifier._current, notifier._repository);
  if (context == null || !context.current.canLoadMore) return null;

  return _startLoadMore(notifier, context);
}

_AgentPageRequest _startLoadMore(
  AgentListNotifier notifier,
  ({AgentListState current, AgentRepository repository}) context,
) {
  final (:current, :repository) = context;
  final generation = ++notifier._generation;
  notifier._setState(_loadingMore(current));

  return (
    repository: repository,
    query: _loadMoreQuery(notifier.workspaceId, current),
    generation: generation,
    complete: (page) => _completedLoadMore(current, page),
  );
}

AgentListQuery _loadMoreQuery(String workspaceId, AgentListState state) =>
    _agentListQuery(workspaceId, state, cursor: state.nextCursor);

_AgentPageRequest? _replaceRequest(AgentListNotifier notifier) {
  final context = _requestContext(notifier._current, notifier._repository);
  if (context == null) return null;

  return _startReplace(notifier, context);
}

_AgentPageRequest _startReplace(
  AgentListNotifier notifier,
  ({AgentListState current, AgentRepository repository}) context,
) {
  final (:current, :repository) = context;
  final generation = ++notifier._generation;
  final refreshing = _refreshing(current);
  notifier._setState(refreshing);

  return (
    repository: repository,
    query: _agentListQuery(notifier.workspaceId, current),
    generation: generation,
    complete: (page) => _completedRefresh(refreshing, page),
  );
}

({AgentListState current, AgentRepository repository})? _requestContext(
  AgentListState? current,
  AgentRepository? repository,
) => current == null || repository == null
    ? null
    : (current: current, repository: repository);

AgentListState _loadingMore(AgentListState state) =>
    state.copyWith(isLoadingMore: true, loadMoreFailed: false);

AgentListState _loadedMore(AgentListState state, AgentListPage page) =>
    state.copyWith(
      agents: _mergeAgents(state.agents, page.agents),
      nextCursor: page.nextCursor,
      isLoadingMore: false,
      loadMoreFailed: false,
    );

AgentListState _loadMoreFailed(AgentListState state) =>
    state.copyWith(isLoadingMore: false, loadMoreFailed: true);

AgentListState _completedLoadMore(AgentListState state, AgentListPage? page) =>
    page == null ? _loadMoreFailed(state) : _loadedMore(state, page);

AgentListState _refreshing(AgentListState state) => state.copyWith(
  isRefreshing: true,
  isLoadingMore: false,
  refreshFailed: false,
  loadMoreFailed: false,
);

AgentListState _refreshed(AgentListState state, AgentListPage page) =>
    state.copyWith(
      agents: page.agents,
      nextCursor: page.nextCursor,
      isRefreshing: false,
      refreshFailed: false,
    );

AgentListState _refreshFailed(AgentListState state) =>
    state.copyWith(isRefreshing: false, refreshFailed: true);

AgentListState _completedRefresh(AgentListState state, AgentListPage? page) =>
    page == null ? _refreshFailed(state) : _refreshed(state, page);

Future<AgentListPage?> _tryListAgents(
  AgentRepository repository,
  AgentListQuery query,
) async {
  try {
    return await repository.listAgents(query);
  } on Object {
    return null;
  }
}
