import 'package:auravibes_app/features/chats/models/background_work_continuation_preview.dart';
import 'package:auravibes_app/features/chats/providers/background_work_continuation_provider.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const BackgroundWorkContinuationStatus({
  required final String workspaceId,
  required final String conversationId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final works = ref
        .watch(
          backgroundWorkContinuationsProvider((
            workspaceId: workspaceId,
            conversationId: conversationId,
          )),
        )
        .value;
    if (works == null || works.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        for (final work in works) _QueuedBackgroundWorkCard(work: work),
      ],
    );
  }
}

class const _QueuedBackgroundWorkCard({required final BackgroundWorkView work})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.hourglass_top),
      title: Text(_continuationStatusKey(work.statusPreview).tr()),
      trailing: TextButton(
        onPressed: () => _showResult(context, work),
        child: Text(
          'chats_screens.chat_conversation.background_work.view_result'.tr(),
        ),
      ),
    ),
  );
}

String _continuationStatusKey(String? statusPreview) => switch (statusPreview) {
  BackgroundWorkContinuationPreview.inProgress =>
    'chats_screens.chat_conversation.background_work.continuation_in_progress',
  BackgroundWorkContinuationPreview.failed =>
    'chats_screens.chat_conversation.background_work.continuation_failed',
  _ =>
    'chats_screens.chat_conversation.background_work.waiting_for_continuation',
};

Future<void> _showResult(BuildContext context, BackgroundWorkView work) =>
    showDialog<void>(
      context: context,
      builder: (context) => _BackgroundWorkResultDialog(work: work),
    );

class const _BackgroundWorkResultDialog({
  required final BackgroundWorkView work,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      'chats_screens.chat_conversation.background_work.result_title'.tr(),
    ),
    content: _BackgroundWorkResultContent(work: work),
    actions: const [_BackgroundWorkResultCloseButton()],
  );
}

class const _BackgroundWorkResultContent({
  required final BackgroundWorkView work,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 560,
    child: SingleChildScrollView(
      child: SelectableText(_backgroundWorkResult(work)),
    ),
  );
}

class const _BackgroundWorkResultCloseButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child: Text('chats_screens.chat_conversation.background_work.close'.tr()),
  );
}

String _backgroundWorkResult(BackgroundWorkView work) {
  final result = work.resultContent;
  if (result == null || result.trim().isEmpty) {
    return 'chats_screens.chat_conversation.background_work.no_result'.tr();
  }

  return result;
}
