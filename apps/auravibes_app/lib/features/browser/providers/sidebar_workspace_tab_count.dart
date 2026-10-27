import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

final sidebarWorkspaceTabCountProvider = Provider.autoDispose
    .family<ValueNotifier<int>, ({String workspaceId, String conversationId})>((
      ref,
      scope,
    ) {
      final count = ValueNotifier(0);
      ref.onDispose(count.dispose);
      return count;
    });
