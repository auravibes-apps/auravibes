import 'dart:async';

import 'package:auravibes_app/features/chats/providers/background_work_providers.dart';
import 'package:auravibes_app/features/chats/providers/background_work_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_stream.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_list_view.dart';
import 'package:auravibes_app/features/chats/widgets/tool_call_response_modal.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

const String _backgroundWorkTitleKey =
    LocaleKeys.chats_screens_chat_conversation_background_work_title;

class const BackgroundWorkHeaderButton({
  required final String workspaceId,
  required final String conversationId,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCloud =
        ref.watch(workspaceSessionForRouteProvider(workspaceId)).value?.cloud !=
        null;
    final worksAsync = _watchBackgroundWorks(
      ref,
      isCloud: isCloud,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    final works = _backgroundWorksValue(worksAsync);
    final activeCount = _activeBackgroundWorkCount(works);
    final label = LocaleKeys
        .chats_screens_chat_conversation_background_work_accessible_label
        .tr(args: [activeCount.toString()]);

    return Semantics(
      child: Tooltip(
        message: _backgroundWorkTitleKey.tr(),
        child: AuraButton(
          onPressed: () => _showBackgroundWorkList(
            context: context,
            workspaceId: workspaceId,
            conversationId: conversationId,
          ),
          child: AuraRow(
            children: [
              const AuraIcon(Icons.work_outline, size: .small, tint: .primary),
              if (activeCount > 0) Text('$activeCount'),
            ],
            spacing: .xs,
            mainAxisSize: .min,
          ),
          key: const ValueKey('background_work_header_button'),
          variant: .ghost,
          size: .small,
        ),
      ),
      button: true,
      identifier: 'background_work_header_button',
      label: label,
    );
  }
}

class const _BackgroundWorkListSheet({
  required final String workspaceId,
  required final String conversationId,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCloud =
        ref.watch(workspaceSessionForRouteProvider(workspaceId)).value?.cloud !=
        null;
    final worksAsync = _watchBackgroundWorks(
      ref,
      isCloud: isCloud,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: .new(maxHeight: MediaQuery.sizeOf(context).height * 0.78),
        child: Padding(
          padding: const .only(top: 12),
          child: Column(
            mainAxisSize: .min,
            children: [
              Padding(
                padding: const .symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextLocale(
                        _backgroundWorkTitleKey,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('background_work_close'),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: _BackgroundWorkListStateView(worksAsync: worksAsync),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _BackgroundWorkListStateView({
  required final AsyncValue<List<AgentBackgroundWork>> worksAsync,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (worksAsync) {
    AsyncData<List<AgentBackgroundWork>>(:final value) =>
      value.isEmpty
          ? const Center(
              child: Padding(
                padding: .all(24),
                child: TextLocale(
                  LocaleKeys
                      .chats_screens_chat_conversation_background_work_empty,
                  textAlign: .center,
                ),
              ),
            )
          : BackgroundWorkListView(
              works: _sortBackgroundWorks(value),
              onStop: (work) => _stopBackgroundWork(
                ref: ref,
                workspaceId: work.identity.workspaceId,
                conversationId: work.identity.conversationId,
                workId: work.identity.id,
              ),
              onOpenResult: (work) => ToolCallResponseModal.show(
                context,
                toolName: work.identity.toolKind,
                content: work.state.resultContent ?? '',
              ),
            ),
    AsyncLoading<List<AgentBackgroundWork>>(:final value?) =>
      BackgroundWorkListView(
        works: _sortBackgroundWorks(value),
        onStop: (work) => _stopBackgroundWork(
          ref: ref,
          workspaceId: work.identity.workspaceId,
          conversationId: work.identity.conversationId,
          workId: work.identity.id,
        ),
        onOpenResult: (work) => ToolCallResponseModal.show(
          context,
          toolName: work.identity.toolKind,
          content: work.state.resultContent ?? '',
        ),
      ),
    AsyncLoading<List<AgentBackgroundWork>>() => const Center(
      child: CircularProgressIndicator(),
    ),
    AsyncError<List<AgentBackgroundWork>>() => const Center(
      child: Padding(
        padding: .all(24),
        child: TextLocale(
          LocaleKeys.chats_screens_chat_conversation_background_work_load_error,
          textAlign: .center,
        ),
      ),
    ),
  };
}

AsyncValue<List<AgentBackgroundWork>> _watchBackgroundWorks(
  WidgetRef ref, {
  required bool isCloud,
  required String workspaceId,
  required String conversationId,
}) => isCloud
    ? ref.watch(
        cloudConversationBackgroundWorksProvider((
          workspaceId: workspaceId,
          conversationId: conversationId,
        )),
      )
    : ref.watch(conversationBackgroundWorksProvider(conversationId));

List<AgentBackgroundWork> _backgroundWorksValue(
  AsyncValue<List<AgentBackgroundWork>> worksAsync,
) => switch (worksAsync) {
  AsyncData<List<AgentBackgroundWork>>(:final value) => value,
  AsyncLoading<List<AgentBackgroundWork>>(:final value?) => value,
  AsyncLoading<List<AgentBackgroundWork>>() ||
  AsyncError<List<AgentBackgroundWork>>() => const [],
};

List<AgentBackgroundWork> _sortBackgroundWorks(
  List<AgentBackgroundWork> works,
) => [...works]
  ..sort(
    (first, second) => first.state.createdAt.compareTo(second.state.createdAt),
  );

int _activeBackgroundWorkCount(List<AgentBackgroundWork> works) =>
    works.where((work) => _isActiveBackgroundWork(work.state.status)).length;

bool _isActiveBackgroundWork(AgentBackgroundWorkStatus status) =>
    status == .running || status == .stopRequested;

Future<bool> runToolInBackground({
  required WidgetRef ref,
  required String workspaceId,
  required String conversationId,
  required String toolCallId,
  required String toolKind,
  required String originatingMessageId,
  required bool isCloud,
}) async {
  if (!isCloud) {
    final work = await ref
        .read(backgroundWorkCoordinatorProvider)
        .runInBackground(
          .new(
            conversationId: conversationId,
            toolCallId: toolCallId,
            toolKind: toolKind,
            originatingMessageId: originatingMessageId,
          ),
        );

    return work != null;
  }

  final gateway = await ref.read(
    cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
  );
  if (gateway == null) return false;
  final _ = await CloudChatGateway(gateway).detachToolCall(
    requestId: const UuidV7().generate(),
    conversationId: conversationId,
    toolCallId: toolCallId,
  );
  ref
    ..invalidate(
      cloudConversationBackgroundWorksProvider((
        workspaceId: workspaceId,
        conversationId: conversationId,
      )),
    )
    ..invalidate(
      cloudConversationStateProvider((
        workspaceId: workspaceId,
        conversationId: conversationId,
      )),
    );

  return true;
}

Future<void> _stopBackgroundWork({
  required WidgetRef ref,
  required String workspaceId,
  required String conversationId,
  required String workId,
}) async {
  final isCloud =
      ref.read(workspaceSessionForRouteProvider(workspaceId)).value?.cloud !=
      null;
  if (!isCloud) {
    final _ = await ref
        .read(backgroundWorkCoordinatorProvider)
        .requestStop(conversationId: conversationId, workId: workId);

    return;
  }

  final gateway = await ref.read(
    cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
  );
  if (gateway == null) return;
  final _ = await CloudChatGateway(gateway).stopBackgroundWork(
    requestId: const UuidV7().generate(),
    conversationId: conversationId,
    workId: workId,
  );
  ref.invalidate(
    cloudConversationBackgroundWorksProvider((
      workspaceId: workspaceId,
      conversationId: conversationId,
    )),
  );
}

void _showBackgroundWorkList({
  required BuildContext context,
  required String workspaceId,
  required String conversationId,
}) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _BackgroundWorkListSheet(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
      isScrollControlled: true,
      useSafeArea: true,
    ),
  );
}
