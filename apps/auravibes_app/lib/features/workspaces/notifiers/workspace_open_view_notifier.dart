import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_open_view_notifier.g.dart';

@riverpod
class WorkspaceOpenViewNotifier extends _$WorkspaceOpenViewNotifier {
  @override
  String? build(String workspaceId,String conversationId) => null;
  set selected(String viewId) => state=viewId;
  void close() => state=null;
}
