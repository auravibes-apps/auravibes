// Riverpod does not publicly export the concrete family type.
// ignore_for_file: implementation_imports

import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:riverpod/src/providers/provider.dart';

final ProviderFamily<ChatA2uiRuntime, String> chatA2uiRuntimeProvider = Provider
    .autoDispose
    .family<ChatA2uiRuntime, String>((ref, conversationId) {
      final runtime = ChatA2uiRuntime(conversationId: conversationId);
      final _ = ref.onDispose(runtime.dispose);

      return runtime;
    });
