import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_open_view_notifier.g.dart';

@riverpod
class WorkspaceOpenViewNotifier extends _$WorkspaceOpenViewNotifier {
  @override
  String? build(String workspaceId, String conversationId) => null;
  void open(String viewId) {
    if (state == viewId) return;
    state = viewId;
  }

  void close() => state = null;
}
