import 'dart:async';

import 'package:auravibes_app/features/chats/providers/background_work_providers.dart';
import 'package:auravibes_app/features/chats/providers/background_work_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_stream.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_list_view.dart';
import 'package:auravibes_app/features/chats/widgets/tool_call_response_modal.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

const String _backgroundWorkTitleKey =
    LocaleKeys.chats_screens_chat_conversation_background_work_title;
const String _backgroundWorkLoadingAccessibleLabelKey =
    'chats_screens.chat_conversation.'
    'background_work_loading_accessible_label';
const String _backgroundWorkRefreshErrorAccessibleLabelKey =
    'chats_screens.chat_conversation.'
    'background_work_refresh_error_accessible_label';
const String _backgroundWorkLoadErrorAccessibleLabelKey =
    'chats_screens.chat_conversation.'
    'background_work_load_error_accessible_label';
const String _backgroundWorkRetryKey =
    'chats_screens.chat_conversation.background_work_retry';
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
    final worksAsync = _watchBackgroundWorks(
      ref,
      isCloud: isCloud,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    final works = _backgroundWorksValue(worksAsync);

    return _BackgroundWorkHeaderButtonView(
      activeCount: _activeBackgroundWorkCount(works),
      isLoading: worksAsync.isLoading && !worksAsync.hasValue,
      hasError: worksAsync.hasError,
      hasValue: worksAsync.hasValue,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
  }
}

class const _BackgroundWorkHeaderButtonView({
  required final int activeCount,
  required final bool isLoading,
  required final bool hasError,
  required final bool hasValue,
  required final String workspaceId,
  required final String conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('background_work_header_button'),
    child: _BackgroundWorkHeaderButtonControl(
      activeCount: activeCount,
      isLoading: isLoading,
      hasError: hasError,
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
    button: true,
    identifier: 'background_work_header_button',
    label: _backgroundWorkAccessibleLabel(
      activeCount: activeCount,
      isLoading: isLoading,
      hasError: hasError,
      hasValue: hasValue,
    ),
  );
}

class const _BackgroundWorkHeaderButtonControl({
  required final int activeCount,
  required final bool isLoading,
  required final bool hasError,
  required final String workspaceId,
  required final String conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Tooltip(
    message: _backgroundWorkTitleKey.tr(),
    child: _BackgroundWorkButton(
      activeCount: activeCount,
      isLoading: isLoading,
      hasError: hasError,
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
  );
}

class const _BackgroundWorkButton({
  required final int activeCount,
  required final bool isLoading,
  required final bool hasError,
  required final String workspaceId,
  required final String conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    void openList() => _openBackgroundWorkList(context);

    return AuraButton(
      onPressed: openList,
      child: _BackgroundWorkButtonContent(
        activeCount: activeCount,
        isLoading: isLoading,
        hasError: hasError,
      ),
      variant: .ghost,
      size: .small,
    );
  }

  void _openBackgroundWorkList(BuildContext context) {
    _showBackgroundWorkList(
      context: context,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
  }
}

class const _BackgroundWorkButtonContent({
  required final int activeCount,
  required final bool isLoading,
  required final bool hasError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      if (isLoading)
        const SizedBox.square(
          child: CircularProgressIndicator(strokeWidth: 2),
          dimension: 16,
        )
      else
        AuraIcon(
          hasError ? Icons.error_outline : Icons.work_outline,
          size: .small,
          tint: hasError ? .error : .primary,
        ),
      if (activeCount > 0) Text('$activeCount'),
    ],
    spacing: .xs,
    mainAxisSize: .min,
  );
}

String _backgroundWorkAccessibleLabel({
  required int activeCount,
  required bool isLoading,
  required bool hasError,
  required bool hasValue,
}) {
  if (isLoading) {
    return _backgroundWorkLoadingAccessibleLabelKey.tr();
  }
  if (hasError && hasValue) {
    return _backgroundWorkRefreshErrorAccessibleLabelKey.tr(
      args: [activeCount.toString()],
    );
  }
  if (hasError) {
    return _backgroundWorkLoadErrorAccessibleLabelKey.tr();
  }

  return LocaleKeys
      .chats_screens_chat_conversation_background_work_accessible_label
      .tr(args: [activeCount.toString()]);
}

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
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
  }
}

class const _BackgroundWorkListSheetView({
  required final AsyncValue<List<AgentBackgroundWork>> worksAsync,
  required final String workspaceId,
  required final String conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SafeArea(
    child: _BackgroundWorkSheetLayout(
      worksAsync: worksAsync,
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
  );
}

class const _BackgroundWorkSheetLayout({
  required final AsyncValue<List<AgentBackgroundWork>> worksAsync,
  required final String workspaceId,
  required final String conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: .new(
      maxHeight:
          MediaQuery.sizeOf(context).height * _backgroundWorkSheetHeightFactor,
    ),
    child: _BackgroundWorkSheetColumn(
      worksAsync: worksAsync,
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
  );
}

class const _BackgroundWorkSheetColumn({
  required final AsyncValue<List<AgentBackgroundWork>> worksAsync,
  required final String workspaceId,
  required final String conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: _backgroundWorkSheetTopInset),
    child: Column(
      mainAxisSize: .min,
      children: [
        const _BackgroundWorkSheetHeader(),
        const Divider(height: 1),
        Flexible(
          child: _BackgroundWorkListStateView(
            worksAsync: worksAsync,
            workspaceId: workspaceId,
            conversationId: conversationId,
          ),
        ),
      ],
    ),
  );
}

class const _BackgroundWorkSheetHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: .symmetric(horizontal: _backgroundWorkSheetHorizontalInset),
    child: Row(
      children: [
        _BackgroundWorkSheetTitle(),
        _BackgroundWorkSheetCloseButton(),
      ],
    ),
  );
}

class const _BackgroundWorkSheetTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: TextLocale(
      _backgroundWorkTitleKey,
      style: Theme.of(context).textTheme.titleMedium,
    ),
  );
}

class const _BackgroundWorkSheetCloseButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('background_work_close'),
    onPressed: () => Navigator.of(context).pop(),
    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
    icon: const Icon(Icons.close),
  );
}

class const _BackgroundWorkListStateView({
  required final AsyncValue<List<AgentBackgroundWork>> worksAsync,
  required final String workspaceId,
  required final String conversationId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = _backgroundWorkListDisplay(worksAsync);
    if (display.hasError) {
      return _BackgroundWorkMessage(
        message: _BackgroundWorkLoadError(
          workspaceId: workspaceId,
          conversationId: conversationId,
        ),
      );
    }
    if (display.works case final works?) {
      return _BackgroundWorkListContent(
        works: works,
        workspaceId: workspaceId,
        conversationId: conversationId,
      );
    }
    if (display.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return const _BackgroundWorkMessage(
      message: TextLocale(
        LocaleKeys.chats_screens_chat_conversation_background_work_empty,
        textAlign: .center,
      ),
    );
  }
}

class const _BackgroundWorkLoadError({
  required final String workspaceId,
  required final String conversationId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    mainAxisSize: .min,
    children: [
      const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_background_work_load_error,
        textAlign: .center,
      ),
      const AuraSizedBox(height: .sm),
      AuraButton(
        onPressed: () =>
            _invalidateBackgroundWorks(ref, workspaceId, conversationId),
        child: const TextLocale(_backgroundWorkRetryKey),
        key: const ValueKey('background_work_retry'),
        variant: .outlined,
        size: .small,
      ),
    ],
  );
}

typedef _BackgroundWorkListDisplay = ({
  List<AgentBackgroundWork>? works,
  bool isLoading,
  bool hasError,
});

_BackgroundWorkListDisplay _backgroundWorkListDisplay(
  AsyncValue<List<AgentBackgroundWork>> worksAsync,
) {
  if (worksAsync.hasError) {
    return (works: null, isLoading: false, hasError: true);
  }

  return (
    works: worksAsync.value,
    isLoading: worksAsync.isLoading,
    hasError: false,
  );
}

class const _BackgroundWorkListContent({
  required final List<AgentBackgroundWork> works,
  required final String workspaceId,
  required final String conversationId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (works.isEmpty) {
      return const _BackgroundWorkMessage(
        message: TextLocale(
          LocaleKeys.chats_screens_chat_conversation_background_work_empty,
          textAlign: .center,
        ),
      );
    }

    return BackgroundWorkListView(
      works: _sortBackgroundWorks(works),
      onStop: _stopBackgroundWorkHandler(ref),
      onOpenResult: _openBackgroundWorkResultHandler(context),
      onOpenChild: _openChildBackgroundWorkHandler(
        context: context,
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    );
  }
}

Future<void> Function(AgentBackgroundWork work) _stopBackgroundWorkHandler(
  WidgetRef ref,
) =>
    (work) => _stopBackgroundWork(ref, work);

Future<void> Function(AgentBackgroundWork work)
_openBackgroundWorkResultHandler(BuildContext context) =>
    (work) async => _showBackgroundWorkResult(context, work);

Future<void> Function(AgentBackgroundWork work)
_openChildBackgroundWorkHandler({
  required BuildContext context,
  required String workspaceId,
  required String conversationId,
}) =>
    (work) => _openChildBackgroundWork(
      context: context,
      workspaceId: workspaceId,
      conversationId: conversationId,
      work: work,
    );

class const _BackgroundWorkMessage({required final Widget message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const .all(_backgroundWorkMessagePadding),
      child: message,
    ),
  );
}

void _showBackgroundWorkResult(
  BuildContext context,
  AgentBackgroundWork work,
) => ToolCallResponseModal.show(
  context,
  toolName: work.identity.toolKind,
  content: work.state.resultContent ?? '',
);

Future<void> _openChildBackgroundWork({
  required BuildContext context,
  required String workspaceId,
  required String conversationId,
  required AgentBackgroundWork work,
}) async {
  final childConversationId = work.identity.childConversationId;
  if (childConversationId == null) return;
  await SubAgentConversationRoute(
    workspaceId: workspaceId,
    chatId: conversationId,
    subAgentConversationId: childConversationId,
  ).push<void>(context);
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

void _invalidateBackgroundWorks(
  WidgetRef ref,
  String workspaceId,
  String conversationId,
) {
  if (_isCloudWorkspace(ref, workspaceId)) {
    ref.invalidate(
      cloudConversationBackgroundWorksProvider((
        workspaceId: workspaceId,
        conversationId: conversationId,
      )),
    );

    return;
  }
  ref.invalidate(conversationBackgroundWorksProvider(conversationId));
}

bool _isCloudWorkspace(WidgetRef ref, String workspaceId) =>
    ref.read(workspaceSessionForRouteProvider(workspaceId)).value?.cloud !=
    null;

List<AgentBackgroundWork> _backgroundWorksValue(
  AsyncValue<List<AgentBackgroundWork>> worksAsync,
) => worksAsync.value ?? const [];

List<AgentBackgroundWork> _sortBackgroundWorks(
  List<AgentBackgroundWork> works,
) => [...works]..sort(_compareBackgroundWorks);

int _compareBackgroundWorks(
  AgentBackgroundWork first,
  AgentBackgroundWork second,
) {
  final createdAtComparison = first.state.createdAt.compareTo(
    second.state.createdAt,
  );
  if (createdAtComparison != 0) return createdAtComparison;

  return first.identity.id.compareTo(second.identity.id);
}

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

Future<bool> _runLocalToolInBackground(BackgroundWorkRunRequest request) async {
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

Future<bool> _runCloudToolInBackground(BackgroundWorkRunRequest request) async {
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
  final gateway = await _cloudGatewayFor(ref, identity.workspaceId);
  if (gateway == null) return;
  await _sendCloudBackgroundWorkStop((gateway: gateway, identity: identity));
  ref.invalidate(
    cloudConversationBackgroundWorksProvider((
      workspaceId: identity.workspaceId,
      conversationId: identity.conversationId,
    )),
  );
}

Future<CloudWorkspaceStateGateway?> _cloudGatewayFor(
  WidgetRef ref,
  String workspaceId,
) => ref.read(
  cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
);

typedef _CloudBackgroundWorkStopRequest = ({
  CloudWorkspaceStateGateway gateway,
  AgentBackgroundWorkIdentity identity,
});

Future<void> _sendCloudBackgroundWorkStop(
  _CloudBackgroundWorkStopRequest request,
) async {
  final _ = await CloudChatGateway(request.gateway).stopBackgroundWork(
    requestId: const UuidV7().generate(),
    conversationId: request.identity.conversationId,
    workId: request.identity.id,
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
