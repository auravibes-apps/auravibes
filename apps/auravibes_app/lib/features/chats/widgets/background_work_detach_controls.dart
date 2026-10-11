import 'package:auravibes_app/features/chats/providers/background_work_continuation_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_stream.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

class const BackgroundWorkDetachControls({
  required final String workspaceId,
  required final String conversationId,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<BackgroundWorkDetachControls> createState() =>
      _BackgroundWorkDetachControlsState();
}

class _BackgroundWorkDetachControlsState
    extends ConsumerState<BackgroundWorkDetachControls> {
  final Set<String> _pendingToolCallIds = {};
  VoidCallback? _closeSnackBar;

  @override
  void dispose() {
    _closeSnackBar?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = (
      workspaceId: widget.workspaceId,
      conversationId: widget.conversationId,
    );
    final calls = ref.watch(backgroundDetachableToolCallsProvider(key));
    if (calls.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        for (final call in calls)
          Card(
            child: ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(_toolCallTitle(call)),
              subtitle: Text(
                'chats_screens.chat_conversation.background_work.detach_hint'
                    .tr(),
              ),
              trailing: TextButton(
                onPressed: _pendingToolCallIds.contains(call.id)
                    ? null
                    : () => _detach(key, call.id),
                child: Text(
                  _backgroundWorkDetachLabel(
                    _pendingToolCallIds.contains(call.id),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _detach(
    BackgroundWorkContinuationKey key,
    String toolCallId,
  ) async {
    setState(() => _pendingToolCallIds.add(toolCallId));
    try {
      final detach = ref.read(backgroundWorkDetachCommandProvider(key));
      final detachedWork = await detach(
        requestId: const UuidV7().generate(),
        toolCallId: toolCallId,
      );
      if (detachedWork.toolCallId != toolCallId) {
        throw StateError('The server detached a different tool call.');
      }
      if (!mounted) return;
      _closeSnackBar?.call();
      _closeSnackBar = AuraSnackBars.show(
        context: context,
        content: Text(
          'chats_screens.chat_conversation.background_work.detached'.tr(),
        ),
        variant: .success,
      ).close;
    } on Object catch (error) {
      if (!mounted) return;
      _closeSnackBar?.call();
      _closeSnackBar = AuraSnackBars.show(
        context: context,
        content: Text(CloudAppErrors.localizationKey(error).tr()),
        variant: .error,
      ).close;
    } finally {
      if (mounted) {
        ref.invalidate(cloudConversationStateProvider(key));
        setState(() => _pendingToolCallIds.remove(toolCallId));
      }
    }
  }
}

String _toolCallTitle(ConversationToolCallView call) {
  final description = call.userFacingDescription;
  if (description == null || description.trim().isEmpty) {
    return 'chats_screens.chat_conversation.background_work.running_task'.tr();
  }

  return description;
}

String _backgroundWorkDetachLabel(bool isPending) {
  final action = isPending ? 'detaching' : 'continue_in_background';

  return '$_backgroundWorkTranslationPrefix$action'.tr();
}

const _backgroundWorkTranslationPrefix =
    'chats_screens.chat_conversation.background_work.';
