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
const double _backgroundWorkSheetHeightFactor = 0.78;
const double _backgroundWorkSheetTopInset = 12;
const double _backgroundWorkSheetHorizontalInset = 16;
const double _backgroundWorkMessagePadding = 24;

typedef BackgroundWorkRunRequest = ({
  WidgetRef ref,
  String workspaceId,
  String conversationId,
  String toolCallId,
  String toolKind,
  String originatingMessageId,
  bool isCloud,
});

class const BackgroundWorkHeaderButton({
  required final String workspaceId,
  required final String conversationId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCloud =
        ref.watch(workspaceSessionForRouteProvider(workspaceId)).value?.cloud !=
        null;
    final works = _backgroundWorksValue(
      _watchBackgroundWorks(
        ref,
        isCloud: isCloud,
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    );

    return _BackgroundWorkHeaderButtonView(
      activeCount: _activeBackgroundWorkCount(works),
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
  }
}

class const _BackgroundWorkHeaderButtonView({
  required this.activeCount,
  required this.workspaceId,
  required this.conversationId,
}) extends StatelessWidget {
  final int activeCount;
  final String workspaceId;
  final String conversationId;

  @override
  Widget build(BuildContext context) => Semantics(
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
    label: _backgroundWorkAccessibleLabel(activeCount),
  );
}

String _backgroundWorkAccessibleLabel(int activeCount) => LocaleKeys
    .chats_screens_chat_conversation_background_work_accessible_label
    .tr(args: [activeCount.toString()]);

class const _BackgroundWorkListSheet({
  required final String workspaceId,
  required final String conversationId,
}) extends ConsumerWidget {
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

    return _BackgroundWorkListSheetView(
      worksAsync: worksAsync,
    );
  }
}

class const _BackgroundWorkListSheetView({
  required this.worksAsync,
}) extends StatelessWidget {
  final AsyncValue<List<AgentBackgroundWork>> worksAsync;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height *
            _backgroundWorkSheetHeightFactor,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: _backgroundWorkSheetTopInset),
        child: Column(
          mainAxisSize: .min,
          children: [
            const _BackgroundWorkSheetHeader(),
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

class const _BackgroundWorkSheetHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: _backgroundWorkSheetHorizontalInset,
    ),
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
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}

class const _BackgroundWorkListStateView({
  required final AsyncValue<List<AgentBackgroundWork>> worksAsync,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (worksAsync) {
    AsyncData<List<AgentBackgroundWork>>(:final value) =>
      _buildBackgroundWorkList(context, ref, value),
    AsyncLoading<List<AgentBackgroundWork>>(:final value?) =>
      _buildBackgroundWorkList(context, ref, value),
    AsyncLoading<List<AgentBackgroundWork>>() => const Center(
      child: CircularProgressIndicator(),
    ),
    AsyncError<List<AgentBackgroundWork>>() => const _BackgroundWorkMessage(
      localeKey:
          LocaleKeys.chats_screens_chat_conversation_background_work_load_error,
    ),
  };
}

class const _BackgroundWorkMessage({required this.localeKey})
    extends StatelessWidget {
  final String localeKey;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: .all(_backgroundWorkMessagePadding),
      child: TextLocale(localeKey, textAlign: .center),
    ),
  );
}

Widget _buildBackgroundWorkList(
  BuildContext context,
  WidgetRef ref,
  List<AgentBackgroundWork> works,
) => works.isEmpty
    ? const _BackgroundWorkMessage(
        localeKey: LocaleKeys.chats_screens_chat_conversation_background_work_empty,
      )
    : BackgroundWorkListView(
        works: _sortBackgroundWorks(works),
        onStop: (work) => _stopBackgroundWork(ref, work),
        onOpenResult: (work) => _showBackgroundWorkResult(context, work),
      );

void _showBackgroundWorkResult(
  BuildContext context,
  AgentBackgroundWork work,
) => ToolCallResponseModal.show(
  context,
  toolName: work.identity.toolKind,
  content: work.state.resultContent ?? '',
);

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

abstract final class BackgroundWorkActions {
  static Future<bool> runToolInBackground(BackgroundWorkRunRequest request) =>
      request.isCloud
          ? _runCloudToolInBackground(request)
          : _runLocalToolInBackground(request);
}

Future<bool> _runLocalToolInBackground(
  BackgroundWorkRunRequest request,
) async {
  final work = await request.ref
      .read(backgroundWorkCoordinatorProvider)
      .runInBackground(
        .new(
          conversationId: request.conversationId,
          toolCallId: request.toolCallId,
          toolKind: request.toolKind,
          originatingMessageId: request.originatingMessageId,
        ),
      );

  return work != null;
}

Future<bool> _runCloudToolInBackground(
  BackgroundWorkRunRequest request,
) async {
  final gateway = await request.ref.read(
    cloudWorkspaceStateGatewayForWorkspaceProvider(request.workspaceId).future,
  );
  if (gateway == null) return false;
  final _ = await CloudChatGateway(gateway).detachToolCall(
    requestId: const UuidV7().generate(),
    conversationId: request.conversationId,
    toolCallId: request.toolCallId,
  );
  _invalidateCloudBackgroundWork(
    request.ref,
    request.workspaceId,
    request.conversationId,
  );

  return true;
}

void _invalidateCloudBackgroundWork(
  WidgetRef ref,
  String workspaceId,
  String conversationId,
) {
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
}

Future<void> _stopBackgroundWork(
  WidgetRef ref,
  AgentBackgroundWork work,
) async {
  final workspaceId = work.identity.workspaceId;
  final isCloud =
      ref.read(workspaceSessionForRouteProvider(workspaceId)).value?.cloud !=
      null;
  if (isCloud) {
    await _stopCloudBackgroundWork(ref, work);

    return;
  }
  await _stopLocalBackgroundWork(ref, work);
}

Future<void> _stopLocalBackgroundWork(
  WidgetRef ref,
  AgentBackgroundWork work,
) async {
  final identity = work.identity;
  final _ = await ref
      .read(backgroundWorkCoordinatorProvider)
      .requestStop(
        conversationId: identity.conversationId,
        workId: identity.id,
      );
}

Future<void> _stopCloudBackgroundWork(
  WidgetRef ref,
  AgentBackgroundWork work,
) async {
  final identity = work.identity;
  final gateway = await ref.read(
    cloudWorkspaceStateGatewayForWorkspaceProvider(identity.workspaceId).future,
  );
  if (gateway == null) return;
  final _ = await CloudChatGateway(gateway).stopBackgroundWork(
    requestId: const UuidV7().generate(),
    conversationId: identity.conversationId,
    workId: identity.id,
  );
  ref.invalidate(
    cloudConversationBackgroundWorksProvider((
      workspaceId: identity.workspaceId,
      conversationId: identity.conversationId,
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
