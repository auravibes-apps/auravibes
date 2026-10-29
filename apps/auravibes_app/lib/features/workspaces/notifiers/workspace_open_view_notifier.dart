import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_open_view_notifier.g.dart';

@riverpod
class WorkspaceOpenViewNotifier extends _$WorkspaceOpenViewNotifier {
  @override
  WorkspaceChatItem? build(String workspaceId, String conversationId) => null;
  void open(String viewId) {
    openItem(viewId, 'view');
  }

  void openItem(String id, String kind) =>
      state = WorkspaceChatItem(id: id, kind: kind);

  void close() => state = null;
}

class const WorkspaceChatItem({
  required final String id,
  required final String kind,
});
