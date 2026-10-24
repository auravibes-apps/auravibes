import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_open_view_notifier.g.dart';

@riverpod
class WorkspaceOpenViewNotifier extends _$WorkspaceOpenViewNotifier {
  String? get selected => state;
  set selected(String? viewId) => state = viewId;

  @override
  String? build(String workspaceId, String conversationId) => null;
  void close() => state = null;
}
