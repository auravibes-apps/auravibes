import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

final ProviderFamily<
  ValueNotifier<int>,
  ({String workspaceId, String conversationId})
>
sidebarWorkspaceTabCountProvider = Provider.autoDispose
    .family<ValueNotifier<int>, ({String workspaceId, String conversationId})>((
      ref,
      scope,
    ) {
      final count = ValueNotifier(0);
      final _ = ref.onDispose(count.dispose);

      return count;
    });
