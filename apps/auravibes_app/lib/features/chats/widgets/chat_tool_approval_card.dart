// Required: Existing thresholds and limits use numeric values.
// Required: Existing argument values intentionally repeat.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/providers/aura_agent_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/batch_tool_approval_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_turn_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/chats/usecases/batch_tool_approval_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/tool_metadata_decoder.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    as agent
    show
        AgentResolvedToolName,
        AgentToolGrantLevel,
        callSkillToolName,
        toolCallApprovalDigest;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('chat_tool_approval_card');

typedef _ActionErrorRequest = ({
  BuildContext context,
  String errorMessageKey,
  Object error,
  StackTrace stackTrace,
});

typedef _BatchApprovalErrorRequest = ({
  BuildContext context,
  bool approved,
  Set<String> hiddenKeys,
  Object error,
  StackTrace stackTrace,
});

void _showApprovalActionError(_ActionErrorRequest request) {
  _logApprovalActionError(request);
  _showApprovalActionErrorSnack(request);
}

void _logApprovalActionError(_ActionErrorRequest request) {
  final error = request.error;
  final errorCode = error is CloudAppException ? error.code : null;
  final errorSuffix = errorCode == null ? '' : ' ($errorCode)';
  _logger.warning(
    'Tool approval action failed$errorSuffix',
    error,
    request.stackTrace,
  );
}

void _showApprovalActionErrorSnack(_ActionErrorRequest request) {
  final error = request.error;
  final _ = AuraSnackBars.show(
    context: request.context,
    content: TextLocale(
      error is CloudAppException
          ? CloudAppErrors.localizationKey(error)
          : request.errorMessageKey,
    ),
    variant: .error,
  );
}

class const ChatToolApprovalCard({
  required final String workspaceId,
  required final String conversationId,
  final List<PendingToolCall>? pendingCalls,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PendingToolCallsView(
      workspaceId: workspaceId,
      conversationId: conversationId,
      pendingCalls: pendingCalls,
    );
  }
}

class const _PendingToolCallsView({
  required final String workspaceId,
  required final String conversationId,
  required final List<PendingToolCall>? pendingCalls,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiddenKeys = useState(<String>{});
    final asyncCalls = pendingCalls == null
        ? ref.watch(pendingToolCallsProvider(workspaceId, conversationId))
        : null;

    useEffect(() => _resetHiddenKeys(hiddenKeys), [conversationId]);

    return _PendingToolCallsResult(
      workspaceId: workspaceId,
      conversationId: conversationId,
      hiddenKeys: hiddenKeys,
      pendingCalls: pendingCalls,
      asyncCalls: asyncCalls,
    );
  }
}

Dispose? _resetHiddenKeys(ValueNotifier<Set<String>> hiddenKeys) {
  hiddenKeys.value = {};

  return null;
}

class const _PendingToolCallsResult({
  required final String workspaceId,
  required final String conversationId,
  required final ValueNotifier<Set<String>> hiddenKeys,
  required final List<PendingToolCall>? pendingCalls,
  required final AsyncValue<List<PendingToolCall>>? asyncCalls,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (asyncCalls case AsyncError(:final error, :final stackTrace)) {
      _logger.warning('Pending tool calls failed', error, stackTrace);

      return const SizedBox.shrink();
    }

    return _PendingToolCallsList(
      workspaceId: workspaceId,
      conversationId: conversationId,
      hiddenKeys: hiddenKeys,
      pendingCalls: pendingCalls ?? asyncCalls?.value ?? const [],
    );
  }
}

class const _PendingToolCallsList({
  required final String workspaceId,
  required final String conversationId,
  required final ValueNotifier<Set<String>> hiddenKeys,
  required final List<PendingToolCall> pendingCalls,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => pendingCalls.isEmpty
      ? const SizedBox.shrink()
      : _PendingToolCallsPager(
          workspaceId: workspaceId,
          conversationId: conversationId,
          hiddenKeys: hiddenKeys,
          pendingCalls: pendingCalls,
        );
}

class const _PendingToolCallsPager({
  required final String workspaceId,
  required final String conversationId,
  required final ValueNotifier<Set<String>> hiddenKeys,
  required final List<PendingToolCall> pendingCalls,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final request = _usePendingToolCallsPager((
      workspaceId: workspaceId,
      conversationId: conversationId,
      hiddenKeys: hiddenKeys,
      pendingCalls: pendingCalls,
    ));

    return _PendingToolCallsPagerPageBuilder(request: request);
  }
}

typedef _PendingToolCallsPagerPageRequest = ({
  String workspaceId,
  String conversationId,
  List<PendingToolCall> visibleCalls,
  ValueNotifier<String?> selectedKey,
  List<String> previousKeys,
  _HideApprovalCalls onHideCalls,
  _RestoreApprovalCalls onRestoreCalls,
});

typedef _PendingToolCallsPagerHookRequest = ({
  String workspaceId,
  String conversationId,
  ValueNotifier<Set<String>> hiddenKeys,
  List<PendingToolCall> pendingCalls,
});

typedef _PagerVisibilityCallbacks = ({
  _HideApprovalCalls onHideCalls,
  _RestoreApprovalCalls onRestoreCalls,
});

typedef _PagerSelectionState = ({
  ValueNotifier<String?> selectedKey,
  ObjectRef<List<String>> previousKeys,
});

typedef _PagerVisibleState = ({List<PendingToolCall> calls, List<String> keys});

_PendingToolCallsPagerPageRequest _usePendingToolCallsPager(
  _PendingToolCallsPagerHookRequest request,
) {
  final visible = _visiblePagerState(request);
  final selection = _usePagerSelection(request.conversationId, visible.keys);
  final callbacks = _pagerVisibilityCallbacks(
    request.hiddenKeys,
    request.conversationId,
  );

  return _pagerPageRequest(request, visible, selection, callbacks);
}

_PendingToolCallsPagerPageRequest _pagerPageRequest(
  _PendingToolCallsPagerHookRequest request,
  _PagerVisibleState visible,
  _PagerSelectionState selection,
  _PagerVisibilityCallbacks callbacks,
) => (
  workspaceId: request.workspaceId,
  conversationId: request.conversationId,
  visibleCalls: visible.calls,
  selectedKey: selection.selectedKey,
  previousKeys: selection.previousKeys.value,
  onHideCalls: callbacks.onHideCalls,
  onRestoreCalls: callbacks.onRestoreCalls,
);

_PagerVisibleState _visiblePagerState(
  _PendingToolCallsPagerHookRequest request,
) {
  final calls = _visiblePendingCalls(
    pendingCalls: request.pendingCalls,
    hiddenKeys: request.hiddenKeys.value,
    conversationId: request.conversationId,
  );

  return (
    calls: calls,
    keys: _pendingToolCallKeys(calls, request.conversationId),
  );
}

_PagerSelectionState _usePagerSelection(
  String conversationId,
  List<String> visibleKeys,
) {
  final selectedKey = useState<String?>(null);
  final previousKeys = useRef<List<String>>([]);
  _usePagerSelectionEffects((
    conversationId: conversationId,
    selectedKey: selectedKey,
    previousKeys: previousKeys,
    visibleKeys: visibleKeys,
  ));

  return (selectedKey: selectedKey, previousKeys: previousKeys);
}

_PagerVisibilityCallbacks _pagerVisibilityCallbacks(
  ValueNotifier<Set<String>> hiddenKeys,
  String conversationId,
) => (
  onHideCalls: (calls) => _hidePendingCalls((
    calls: calls,
    conversationId: conversationId,
    hiddenKeys: hiddenKeys,
  )),
  onRestoreCalls: (keys) => _restorePendingCalls(hiddenKeys, keys),
);

typedef _PagerSelectionEffectsRequest = ({
  String conversationId,
  ValueNotifier<String?> selectedKey,
  ObjectRef<List<String>> previousKeys,
  List<String> visibleKeys,
});

void _usePagerSelectionEffects(_PagerSelectionEffectsRequest request) {
  useEffect(
    () => _resetPagerSelection(request.selectedKey, request.previousKeys),
    [request.conversationId],
  );
  useEffect(
    () => _syncPagerSelection((
      selectedKey: request.selectedKey,
      previousKeys: request.previousKeys,
      visibleKeys: request.visibleKeys,
    )),
    request.visibleKeys,
  );
}

class const _PendingToolCallsPagerPageBuilder({
  required final _PendingToolCallsPagerPageRequest request,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final visibleCalls = request.visibleCalls;
    if (visibleCalls.isEmpty) return const SizedBox.shrink();

    final conversationId = request.conversationId;

    return _PendingToolCallsPagerPage(
      workspaceId: request.workspaceId,
      conversationId: conversationId,
      pendingCalls: visibleCalls,
      selectedKey: request.selectedKey,
      previousKeys: request.previousKeys,
      onHideCalls: request.onHideCalls,
      onRestoreCalls: request.onRestoreCalls,
    );
  }
}

List<PendingToolCall> _visiblePendingCalls({
  required List<PendingToolCall> pendingCalls,
  required Set<String> hiddenKeys,
  required String conversationId,
}) => [
  for (final pendingCall in pendingCalls)
    if (!hiddenKeys.contains(_pendingToolCallKey(pendingCall, conversationId)))
      pendingCall,
];

List<String> _pendingToolCallKeys(
  Iterable<PendingToolCall> pendingCalls,
  String conversationId,
) => [
  for (final pendingCall in pendingCalls)
    _pendingToolCallKey(pendingCall, conversationId),
];

Dispose? _resetPagerSelection(
  ValueNotifier<String?> selectedKey,
  ObjectRef<List<String>> previousKeys,
) {
  selectedKey.value = null;
  previousKeys.value = [];

  return null;
}

typedef _PagerSelectionSyncRequest = ({
  ValueNotifier<String?> selectedKey,
  ObjectRef<List<String>> previousKeys,
  List<String> visibleKeys,
});

Dispose? _syncPagerSelection(_PagerSelectionSyncRequest request) {
  _applyPagerSelection(
    selectedKey: request.selectedKey,
    previousKeys: request.previousKeys,
    visibleKeys: request.visibleKeys,
  );

  return null;
}

void _applyPagerSelection({
  required ValueNotifier<String?> selectedKey,
  required ObjectRef<List<String>> previousKeys,
  required List<String> visibleKeys,
}) {
  final nextIndex = _pagerSelectionIndex((
    currentKeys: visibleKeys,
    selectedKey: selectedKey.value,
    previousKeys: previousKeys.value,
  ));
  final nextKey = visibleKeys.isEmpty ? null : visibleKeys[nextIndex];
  if (selectedKey.value != nextKey) selectedKey.value = nextKey;
  previousKeys.value = visibleKeys;
}

typedef _PagerKeySelectionRequest = ({
  List<String> currentKeys,
  String? selectedKey,
  List<String> previousKeys,
});

int _pagerSelectionIndex(_PagerKeySelectionRequest request) {
  final selectedKey = request.selectedKey;
  final selectedIndex = selectedKey == null
      ? -1
      : request.currentKeys.indexOf(selectedKey);
  if (selectedIndex >= 0) return selectedIndex;

  final previousIndex = selectedKey == null
      ? -1
      : request.previousKeys.indexOf(selectedKey);

  return math.min(math.max(previousIndex, 0), request.currentKeys.length - 1);
}

typedef _HidePendingCallsRequest = ({
  Iterable<PendingToolCall> calls,
  String conversationId,
  ValueNotifier<Set<String>> hiddenKeys,
});

Set<String>? _hidePendingCalls(_HidePendingCallsRequest request) {
  final keys = _pendingToolCallKeys(request.calls, request.conversationId);
  final newKeys = keys.toSet().difference(request.hiddenKeys.value);
  if (newKeys.isEmpty) return null;

  request.hiddenKeys.value = {...request.hiddenKeys.value, ...newKeys};

  return newKeys;
}

void _restorePendingCalls(
  ValueNotifier<Set<String>> hiddenKeys,
  Set<String> keys,
) {
  hiddenKeys.value = {...hiddenKeys.value}..removeAll(keys);
}

String _pendingToolCallKey(PendingToolCall pendingCall, String conversationId) {
  final sourceConversationId = _pendingToolCallConversationId(
    pendingCall,
    conversationId,
  );

  return '$sourceConversationId:'
      '${pendingCall.messageId}:${pendingCall.toolCall.id}';
}

String _pendingToolCallConversationId(
  PendingToolCall pendingCall,
  String fallbackConversationId,
) => pendingCall.sourceConversationId.isEmpty
    ? fallbackConversationId
    : pendingCall.sourceConversationId;

typedef _HideApprovalCalls = Set<String>? Function(
  Iterable<PendingToolCall> calls,
);

String _pendingToolCallSourceConversationId(
  PendingToolCall pendingCall,
  String rootConversationId,
) => pendingCall.sourceConversationId.isEmpty
    ? rootConversationId
    : pendingCall.sourceConversationId;

typedef _StartApprovalDecision = Set<String>? Function();
typedef _RestoreApprovalCalls = void Function(Set<String> keys);

class const _PendingToolCallsPagerPage({
  required final String workspaceId,
  required final String conversationId,
  required final List<PendingToolCall> pendingCalls,
  required final ValueNotifier<String?> selectedKey,
  required final List<String> previousKeys,
  required final _HideApprovalCalls onHideCalls,
  required final _RestoreApprovalCalls onRestoreCalls,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _PendingToolCallsPagerContentBuilder(
    request: (
      workspaceId: workspaceId,
      conversationId: conversationId,
      pendingCalls: pendingCalls,
      selectedKey: selectedKey.value,
      previousKeys: previousKeys,
      selectedKeyNotifier: selectedKey,
      onHideCalls: onHideCalls,
      onRestoreCalls: onRestoreCalls,
    ),
  );
}

typedef _PendingToolCallsPagerContentRequest = ({
  String workspaceId,
  String conversationId,
  List<PendingToolCall> pendingCalls,
  String? selectedKey,
  List<String> previousKeys,
  ValueNotifier<String?> selectedKeyNotifier,
  _HideApprovalCalls onHideCalls,
  _RestoreApprovalCalls onRestoreCalls,
});

typedef _PagerApprovalCardBuildRequest = ({
  _PendingToolCallsPagerContentRequest request,
  _PendingToolCallsPageSelection selection,
  PendingToolCall current,
  String conversationId,
});

class const _PendingToolCallsPagerContentBuilder({
  required final _PendingToolCallsPagerContentRequest request,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selection = _PendingToolCallsPageSelection(
      request.pendingCalls,
      request.selectedKey,
      request.previousKeys,
      request.conversationId,
    );
    final current = request.pendingCalls[selection.clamped];
    final conversationId = _pendingToolCallConversationId(
      current,
      request.conversationId,
    );

    return _PendingToolCallsPagerContent(
      request: _pagerApprovalCardRequest((
        request: request,
        selection: selection,
        current: current,
        conversationId: conversationId,
      )),
    );
  }
}

_ApprovalCardRequest _pagerApprovalCardRequest(
  _PagerApprovalCardBuildRequest input,
) {
  final page = _pagerApprovalCardPage(
    input.selection,
    input.request.pendingCalls,
  );

  return (
    source: input.request,
    current: input.current,
    conversationId: input.conversationId,
    currentIndex: page.currentIndex,
    totalCount: page.totalCount,
    hasPrev: page.hasPrev,
    hasNext: page.hasNext,
    actions: _pagerApprovalActions(
      input.request,
      input.current,
      page.currentIndex,
    ),
  );
}

({int currentIndex, int totalCount, bool hasPrev, bool hasNext})
_pagerApprovalCardPage(
  _PendingToolCallsPageSelection selection,
  List<PendingToolCall> pendingCalls,
) {
  final currentIndex = selection.clamped;

  return (
    currentIndex: currentIndex,
    totalCount: pendingCalls.length,
    hasPrev: currentIndex > 0,
    hasNext: currentIndex < selection.lastIndex,
  );
}

typedef _ApprovalCardActions = ({
  VoidCallback? onPrev,
  VoidCallback? onNext,
  _StartApprovalDecision onDecisionStarted,
  _StartApprovalDecision onStopAllStarted,
  _RestoreApprovalCalls onDecisionFailed,
});

_ApprovalCardActions _pagerApprovalActions(
  _PendingToolCallsPagerContentRequest request,
  PendingToolCall current,
  int currentIndex,
) {
  final navigation = _pagerNavigationActions(request, currentIndex);
  final decisions = _pagerDecisionActions(request, current);

  return (
    onPrev: navigation.onPrev,
    onNext: navigation.onNext,
    onDecisionStarted: decisions.onDecisionStarted,
    onStopAllStarted: decisions.onStopAllStarted,
    onDecisionFailed: request.onRestoreCalls,
  );
}

typedef _PagerNavigationActions = ({
  VoidCallback? onPrev,
  VoidCallback? onNext,
});

_PagerNavigationActions _pagerNavigationActions(
  _PendingToolCallsPagerContentRequest request,
  int currentIndex,
) {
  final pendingCalls = request.pendingCalls;
  final conversationId = request.conversationId;
  final selectedKey = request.selectedKeyNotifier;

  return (
    onPrev: currentIndex > 0
        ? _setPagerSelection(
            selectedKey,
            pendingCalls[currentIndex - 1],
            conversationId,
          )
        : null,
    onNext: currentIndex < pendingCalls.length - 1
        ? _setPagerSelection(
            selectedKey,
            pendingCalls[currentIndex + 1],
            conversationId,
          )
        : null,
  );
}

VoidCallback _setPagerSelection(
  ValueNotifier<String?> selectedKey,
  PendingToolCall pendingCall,
  String conversationId,
) =>
    () => selectedKey.value = _pendingToolCallKey(pendingCall, conversationId);

typedef _PagerDecisionActions = ({
  _StartApprovalDecision onDecisionStarted,
  _StartApprovalDecision onStopAllStarted,
});

_PagerDecisionActions _pagerDecisionActions(
  _PendingToolCallsPagerContentRequest request,
  PendingToolCall current,
) => (
  onDecisionStarted: () => request.onHideCalls([current]),
  onStopAllStarted: () => request.onHideCalls(request.pendingCalls),
);

class _PendingToolCallsPageSelection {
  new(
    List<PendingToolCall> pendingCalls,
    String? selectedKey,
    List<String> previousKeys,
    String conversationId,
  ) : lastIndex = pendingCalls.length - 1,
      clamped = _pendingToolCallPageIndex((
        pendingCalls: pendingCalls,
        selectedKey: selectedKey,
        previousKeys: previousKeys,
        conversationId: conversationId,
      ));

  final int lastIndex;
  final int clamped;
}

typedef _PagerIndexRequest = ({
  List<PendingToolCall> pendingCalls,
  String? selectedKey,
  List<String> previousKeys,
  String conversationId,
});

int _pendingToolCallPageIndex(_PagerIndexRequest request) {
  final pendingCalls = request.pendingCalls;
  final conversationId = request.conversationId;
  final keys = _pendingToolCallKeys(pendingCalls, conversationId);

  return _pagerSelectionIndex((
    currentKeys: keys,
    selectedKey: request.selectedKey,
    previousKeys: request.previousKeys,
  ));
}

typedef _ApprovalCardRequest = ({
  _PendingToolCallsPagerContentRequest source,
  PendingToolCall current,
  String conversationId,
  int currentIndex,
  int totalCount,
  bool hasPrev,
  bool hasNext,
  _ApprovalCardActions actions,
});

class const _PendingToolCallsPagerContent({
  required final _ApprovalCardRequest request,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ApprovalCardContent(request: request);
}

class const _ApprovalCardContent({required final _ApprovalCardRequest request})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _ApprovalCardDisplay(ref: ref, request: request);
}

class const _ApprovalCardDisplay({
  required final WidgetRef ref,
  required final _ApprovalCardRequest request,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ApprovalCardFrame(
    child: _ApprovalCardBody(
      request: request,
      displayName: _approvalDisplayName(ref, request),
    ),
  );
}

agent.AgentResolvedToolName? _effectiveDisplayTarget(
  MessageToolCallEntity toolCall,
) {
  if (toolCall.name != agent.callSkillToolName) return null;

  return _skillDisplayTarget(_decodeSkillArguments(toolCall.argumentsRaw));
}

agent.AgentResolvedToolName? _skillDisplayTarget(
  Map<String, Object?>? decoded,
) {
  final skill = decoded?['skill'];
  final tool = decoded?['tool'];
  if (skill is! String || skill.isEmpty || tool is! String || tool.isEmpty) {
    return null;
  }

  return ToolNameFormatter.parse(['skill', 'app', skill, tool].join('__'));
}

Map<String, Object?>? _decodeSkillArguments(String argumentsRaw) {
  try {
    final decoded = jsonDecode(argumentsRaw);

    return decoded is Map ? decoded.cast<String, Object?>() : null;
  } on FormatException {
    return null;
  }
}

String _approvalDisplayName(WidgetRef ref, _ApprovalCardRequest request) {
  final toolCall = request.current.toolCall;
  final effectiveTarget = _effectiveDisplayTarget(toolCall);

  return _toolDisplayName((
    ref: ref,
    workspaceId: request.source.workspaceId,
    presentationToolName: effectiveTarget?.fullName ?? toolCall.name,
    effectiveTarget: effectiveTarget,
    rawToolName: toolCall.name,
  ));
}

String _toolDisplayName(
  ({
    WidgetRef ref,
    String workspaceId,
    String presentationToolName,
    agent.AgentResolvedToolName? effectiveTarget,
    String rawToolName,
  })
  request,
) {
  final displayNameAsync = request.ref.watch(
    toolDisplayNameProvider(request.workspaceId, request.presentationToolName),
  );

  return displayNameAsync.maybeWhen(
    data: (name) => name,
    orElse: () => _fallbackToolDisplayName(request),
  );
}

String _fallbackToolDisplayName(
  ({
    WidgetRef ref,
    String workspaceId,
    String presentationToolName,
    agent.AgentResolvedToolName? effectiveTarget,
    String rawToolName,
  })
  request,
) => ToolNameFormatter.formatDisplayName(
  request.effectiveTarget ?? ToolNameFormatter.parse(request.rawToolName),
  rawName: request.rawToolName,
);

class const _ApprovalCardFrame({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final theme = context.auraTheme;

    return Container(
      padding: EdgeInsets.all(theme.fromSpacing(.md)),
      decoration: _approvalCardDecoration(auraColors, theme),
      width: .infinity,
      margin: EdgeInsets.all(theme.fromSpacing(.md)),
      child: child,
    );
  }
}

BoxDecoration _approvalCardDecoration(AuraColorScheme colors, AuraTheme theme) {
  return BoxDecoration(
    color: colors.warning.withValues(alpha: 0.08),
    border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
    borderRadius: BorderRadius.all(.circular(theme.fromBorderRadius(.lg))),
  );
}

class const _ApprovalCardBody({
  required final _ApprovalCardRequest request,
  required final String displayName,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: _ApprovalCardBodyChildren(
      request: request,
      displayName: displayName,
    ).values,
    spacing: .sm,
  );
}

class _ApprovalCardBodyChildren {
  new({required _ApprovalCardRequest request, required String displayName})
    : values = [
        _NavigationHeader(
          currentIndex: request.currentIndex,
          totalCount: request.totalCount,
          hasPrev: request.hasPrev,
          hasNext: request.hasNext,
          onPrev: request.actions.onPrev,
          onNext: request.actions.onNext,
        ),
        _ToolCallInfo(
          displayName: displayName,
          argumentsRaw: request.current.toolCall.argumentsRaw,
          sourceLabel: request.current.sourceLabel,
        ),
        if (request.source.pendingCalls.length > 1)
          _BatchApprovalButtons(
            workspaceId: request.source.workspaceId,
            conversationId: request.conversationId,
            pendingCalls: request.source.pendingCalls,
            onHideCalls: request.source.onHideCalls,
            onRestoreCalls: request.source.onRestoreCalls,
          ),
        _ConfirmationButtons(
          workspaceId: request.source.workspaceId,
          conversationId: _pendingToolCallSourceConversationId(
            request.current,
            request.conversationId,
          ),
          toolCall: request.current.toolCall,
          messageId: request.current.messageId,
          onDecisionStarted: request.actions.onDecisionStarted,
          onStopAllStarted: request.actions.onStopAllStarted,
          onDecisionFailed: request.actions.onDecisionFailed,
        ),
      ];

  final List<Widget> values;
}

class const _NavigationHeader({
  required final int currentIndex,
  required final int totalCount,
  required final bool hasPrev,
  required final bool hasNext,
  required final VoidCallback? onPrev,
  required final VoidCallback? onNext,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NavigationTitle(currentIndex: currentIndex, totalCount: totalCount),
        _NavigationControls(
          hasPrev: hasPrev,
          hasNext: hasNext,
          onPrev: onPrev,
          onNext: onNext,
        ),
      ],
    );
  }
}

class const _NavigationTitle({
  required final int currentIndex,
  required final int totalCount,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          const _NavigationIcon(),
          _NavigationCount(currentIndex: currentIndex, totalCount: totalCount),
        ],
      ),
    );
  }
}

class const _NavigationIcon() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.build_outlined, size: 16, color: context.auraColors.warning),
        const AuraSizedBox(width: .xs),
      ],
    );
  }
}

class const _NavigationCount({
  required final int currentIndex,
  required final int totalCount,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    _navigationCountText(currentIndex, totalCount),
    style: _navigationCountStyle(context),
  );
}

String _navigationCountText(int currentIndex, int totalCount) => LocaleKeys
    .tool_approval_pending_count
    .tr(args: [(currentIndex + 1).toString(), totalCount.toString()]);

TextStyle _navigationCountStyle(BuildContext context) {
  final typography = context.auraTheme.typography;

  return .new(
    color: context.auraColors.onSurface,
    fontSize: typography.fontSizeSm,
    fontWeight: FontWeight.w600,
  );
}

class const _NavigationControls({
  required final bool hasPrev,
  required final bool hasNext,
  required final VoidCallback? onPrev,
  required final VoidCallback? onNext,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: _NavigationControlChildren(
      hasPrev: hasPrev,
      hasNext: hasNext,
      onPrev: onPrev,
      onNext: onNext,
    ).values,
  );
}

class _NavigationControlChildren {
  new({
    required bool hasPrev,
    required bool hasNext,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
  }) : values = [
         _NavButton(
           icon: Icons.chevron_left,
           onPressed: hasPrev ? onPrev : null,
           selectorId: 'tool_approval_previous',
         ),
         const AuraSizedBox(width: .xs),
         _NavButton(
           icon: Icons.chevron_right,
           onPressed: hasNext ? onNext : null,
           selectorId: 'tool_approval_next',
         ),
       ];

  final List<Widget> values;
}

class const _NavButton({
  required final IconData icon,
  required final VoidCallback? onPressed,
  required final String selectorId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey<String>(selectorId),
    child: AuraIconButton(
      icon: icon,
      onPressed: onPressed,
      disabled: onPressed == null,
      size: .small,
    ),
    identifier: selectorId,
  );
}

class const _ToolCallInfo({
  required final String displayName,
  required final String argumentsRaw,
  required final String? sourceLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final argumentLines = _approvalArgumentLines(argumentsRaw);
    final copyableArgs = _approvalArgumentsCopy(argumentsRaw);

    return _ToolCallInfoFrame(
      child: _ToolCallInfoContent(
        displayName: displayName,
        sourceLabel: sourceLabel,
        argumentLines: argumentLines,
        copyableArgs: copyableArgs,
      ),
    );
  }
}

class const _ToolCallInfoFrame({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ToolCallInfoSurface(
    padding: .all(context.auraTheme.fromSpacing(.sm)),
    decoration: _toolCallInfoDecoration(context),
    child: child,
  );
}

class const _ToolCallInfoSurface({
  required final EdgeInsets padding,
  required final BoxDecoration decoration,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: decoration,
    width: .infinity,
    child: child,
  );
}

BoxDecoration _toolCallInfoDecoration(BuildContext context) {
  final theme = context.auraTheme;

  return BoxDecoration(
    color: context.auraColors.surfaceVariant.withValues(alpha: 0.5),
    borderRadius: BorderRadius.all(.circular(theme.fromBorderRadius(.sm))),
  );
}

class const _ToolCallInfoContent({
  required final String displayName,
  required final String? sourceLabel,
  required final List<_ApprovalArgumentLine>? argumentLines,
  required final String? copyableArgs,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: _ToolCallInfoChildren(
      displayName: displayName,
      sourceLabel: sourceLabel,
      argumentLines: argumentLines,
      copyableArgs: copyableArgs,
    ).values,
  );
}

class _ToolCallInfoChildren {
  new({
    required String displayName,
    required String? sourceLabel,
    required List<_ApprovalArgumentLine>? argumentLines,
    required String? copyableArgs,
  }) : values = [
         _ToolCallName(displayName: displayName),
         _ToolCallDescription(displayName: displayName),
         _ToolCallSource(sourceLabel: sourceLabel),
         if (argumentLines case final lines? when lines.isNotEmpty)
           _ToolCallArgumentsPreview(
             lines: lines,
             copyValue: copyableArgs ?? '',
             key: ValueKey<String>(copyableArgs ?? ''),
           ),
       ];

  final List<Widget> values;
}

class const _ToolCallDescription({required final String displayName})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: context.auraTheme.fromSpacing(.xs),
      bottom: context.auraTheme.fromSpacing(.xs),
    ),
    child: Text(
      LocaleKeys.chats_screens_chat_conversation_tool_call_fallback_description
          .tr(namedArgs: {'tool': displayName}),
      style: .new(
        color: context.auraColors.onSurface,
        fontSize: context.auraTheme.typography.fontSizeXs,
      ),
    ),
  );
}

class const _ToolCallName({required final String displayName})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final typography = context.auraTheme.typography;

    return Text(
      displayName,
      style: .new(
        color: colors.onSurface,
        fontSize: typography.fontSizeSm,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class const _ToolCallSource({required final String? sourceLabel})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final value = sourceLabel;
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    final colors = context.auraColors;
    final typography = context.auraTheme.typography;

    return Text(
      value,
      style: .new(
        color: colors.onSurfaceVariant,
        fontSize: typography.fontSizeXs,
      ),
      overflow: .ellipsis,
    );
  }
}

class _ToolCallArgumentsPreview extends StatelessWidget {
  const new({required this.lines, required this.copyValue, super.key});

  final List<_ApprovalArgumentLine> lines;
  final String copyValue;

  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const AuraSizedBox(height: .xs),
      _ToolCallArgumentLines(
        lines: lines,
        maxLines: null,
        copyValue: copyValue,
      ),
    ],
    spacing: .xs,
  );
}

class const _ToolCallArgumentLines({
  required final List<_ApprovalArgumentLine> lines,
  required final int? maxLines,
  required final String copyValue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: .start,
    children: [
      Expanded(
        child: AuraColumn(
          children: [
            for (final line in lines)
              _ToolCallArgumentLine(line: line, maxLines: maxLines),
          ],
          spacing: .xs,
          crossAxisAlignment: .start,
        ),
      ),
      _ToolCallArgumentsCopyButton(content: copyValue),
    ],
  );
}

typedef _ApprovalArgumentLine = ({String path, String value});

class const _ToolCallArgumentLine({
  required final _ApprovalArgumentLine line,
  final int? maxLines,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        if (line.path.isNotEmpty)
          TextSpan(
            text: '${line.path}: ',
            style: _toolCallArgumentKeyStyle(context),
          ),
        TextSpan(text: line.value, style: _toolCallArgumentsStyle(context)),
      ],
    ),
    overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
    maxLines: maxLines,
  );
}

TextStyle _toolCallArgumentsStyle(BuildContext context) {
  final typography = context.auraTheme.typography;

  return .new(
    color: context.auraColors.onSurfaceVariant,
    fontSize: typography.fontSizeXs,
  );
}

TextStyle _toolCallArgumentKeyStyle(BuildContext context) =>
    _toolCallArgumentsStyle(context)
        .copyWith(color: context.auraColors.onSurface, fontWeight: .w600);

class const _ToolCallArgumentsCopyButton({required final String content})
    extends StatefulWidget {
  @override
  State<_ToolCallArgumentsCopyButton> createState() =>
      _ToolCallArgumentsCopyButtonState();
}

class _ToolCallArgumentsCopyButtonState
    extends State<_ToolCallArgumentsCopyButton> {
  var _copied = false;

  IconData get _copyIcon => _copied ? Icons.check : Icons.copy_outlined;

  String get _copyTooltip =>
      (_copied
              ? LocaleKeys.chats_screens_chat_conversation_tool_arguments_copied
              : LocaleKeys.chats_screens_chat_conversation_copy_tool_arguments)
          .tr();

  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: _copyIcon,
    onPressed: () => unawaited(_copyArguments()),
    size: .small,
    tooltip: _copyTooltip,
  );

  Future<void> _copyArguments() async {
    if (widget.content.isEmpty) return;

    try {
      await Clipboard.setData(.new(text: widget.content));
    } on Object {
      return;
    }

    if (mounted) setState(() => _copied = true);
  }
}

const JsonEncoder _approvalArgumentsEncoder = .withIndent('  ');
const _redactedValue = '****';
const _sensitiveKeyParts = [
  'auth',
  'credential',
  'secret',
  'token',
  'password',
  'key',
  'apikey',
  'api_key',
];

typedef _ApprovalDecodeResult = ({bool success, Object? value});

List<_ApprovalArgumentLine>? _approvalArgumentLines(String argumentsRaw) {
  final decoded = _decodeApprovalArguments(argumentsRaw);
  if (!decoded.success) {
    final value = ToolMetadataDecoder.decode(argumentsRaw);

    return value == null ? null : [(path: '', value: value)];
  }

  return _flattenApprovalArgumentLines(_redactCredentialValues(decoded.value));
}

String? _approvalArgumentsCopy(String argumentsRaw) {
  final decoded = _decodeApprovalArguments(argumentsRaw);
  if (!decoded.success) return ToolMetadataDecoder.decode(argumentsRaw);

  return _approvalArgumentsEncoder.convert(
    _redactCredentialValues(decoded.value),
  );
}

_ApprovalDecodeResult _decodeApprovalArguments(String argumentsRaw) {
  try {
    return (success: true, value: jsonDecode(argumentsRaw));
  } on Exception {
    return (success: false, value: null);
  }
}

List<_ApprovalArgumentLine> _flattenApprovalArgumentLines(
  Object? value, [
  String path = '',
]) => switch (value) {
  final Map<Object?, Object?> map => _flattenApprovalMap(map, path),
  final List<Object?> list => _flattenApprovalList(list, path),
  _ => [(path: path, value: _formatApprovalArgumentValue(value))],
};

List<_ApprovalArgumentLine> _flattenApprovalMap(
  Map<Object?, Object?> value,
  String path,
) {
  if (value.isEmpty) return [(path: path, value: '{}')];

  return [
    for (final entry in value.entries)
      ..._flattenApprovalArgumentLines(
        entry.value,
        _approvalArgumentPath(path, entry.key),
      ),
  ];
}

List<_ApprovalArgumentLine> _flattenApprovalList(
  List<Object?> value,
  String path,
) {
  if (value.isEmpty) return [(path: path, value: '[]')];

  return [
    for (var index = 0; index < value.length; index++)
      ..._flattenApprovalArgumentLines(
        value[index],
        _approvalArgumentIndexPath(path, index),
      ),
  ];
}

String _approvalArgumentPath(String path, Object? key) {
  final keyText = key.toString();

  return path.isEmpty ? keyText : '$path.$keyText';
}

String _approvalArgumentIndexPath(String path, int index) =>
    path.isEmpty ? '[$index]' : '$path[$index]';

String _formatApprovalArgumentValue(Object? value) => switch (value) {
  null => 'null',
  final String string => string,
  _ => value.toString(),
};

Object? _redactCredentialValues(Object? value) => switch (value) {
  final List<Object?> list => _redactList(list),
  final Map<Object?, Object?> map => _redactMap(map),
  final String string => _redactString(string),
  _ => value,
};

List<Object?> _redactList(List<Object?> value) =>
    value.map(_redactCredentialValues).toList();

Map<Object?, Object?> _redactMap(Map<Object?, Object?> value) => {
  for (final entry in value.entries)
    entry.key: _isSensitiveKey(entry.key)
        ? _redactedValue
        : _redactCredentialValues(entry.value),
};

Object? _redactString(String value) {
  final decoded = _tryDecodeJsonString(value);
  if (decoded == null) return value;

  return _redactCredentialValues(decoded);
}

Object? _tryDecodeJsonString(String value) {
  final trimmed = value.trim();
  if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return null;

  try {
    return jsonDecode(trimmed);
  } on Exception {
    return null;
  }
}

bool _isSensitiveKey(Object? key) {
  final normalized = key.toString().toLowerCase();

  return normalized == 'authorization' ||
      _sensitiveKeyParts.any(normalized.contains);
}

List<PendingToolCall> _uniquePendingToolCalls(
  Iterable<PendingToolCall> pendingCalls,
  String conversationId,
) {
  final seenKeys = <String>{};

  return [
    for (final pendingCall in pendingCalls)
      if (seenKeys.add(_pendingToolCallKey(pendingCall, conversationId)))
        pendingCall,
  ];
}

class const _BatchApprovalButtons({
  required final String workspaceId,
  required final String conversationId,
  required final List<PendingToolCall> pendingCalls,
  required final _HideApprovalCalls onHideCalls,
  required final _RestoreApprovalCalls onRestoreCalls,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraRow(
    children: [
      _BatchApprovalButton(
        workspaceId: workspaceId,
        conversationId: conversationId,
        pendingCalls: pendingCalls,
        onHideCalls: onHideCalls,
        onRestoreCalls: onRestoreCalls,
        approved: true,
      ),
      _BatchApprovalButton(
        workspaceId: workspaceId,
        conversationId: conversationId,
        pendingCalls: pendingCalls,
        onHideCalls: onHideCalls,
        onRestoreCalls: onRestoreCalls,
        approved: false,
      ),
    ],
  );
}

class const _BatchApprovalAction({
  required final bool approved,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final identifier = approved
        ? 'tool_approval_allow_all'
        : 'tool_approval_deny_all';

    return Semantics(
      key: ValueKey<String>(identifier),
      child: AuraButton(
        onPressed: onPressed,
        child: TextLocale(
          approved
              ? LocaleKeys.tool_confirmation_allow_all
              : LocaleKeys.tool_confirmation_deny_all,
        ),
        variant: .outlined,
        tint: approved ? null : .error,
        size: .small,
      ),
      identifier: identifier,
    );
  }
}

class const _BatchApprovalButton({
  required final String workspaceId,
  required final String conversationId,
  required final List<PendingToolCall> pendingCalls,
  required final _HideApprovalCalls onHideCalls,
  required final _RestoreApprovalCalls onRestoreCalls,
  required final bool approved,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Expanded(
    child: _BatchApprovalAction(
      approved: approved,
      onPressed: () => unawaited(_runBatch(ref, context, approved: approved)),
    ),
  );

  Future<void> _runBatch(
    WidgetRef ref,
    BuildContext context, {
    required bool approved,
  }) async {
    final calls = _uniquePendingToolCalls(pendingCalls, conversationId);
    final hiddenKeys = onHideCalls(calls);
    if (hiddenKeys == null) return;

    try {
      await _performBatch(ref, calls, approved: approved);
    } on Object catch (error, stackTrace) {
      if (context.mounted) {
        _handleBatchError((
          context: context,
          approved: approved,
          hiddenKeys: hiddenKeys,
          error: error,
          stackTrace: stackTrace,
        ));
      }
    }
  }

  Future<void> _performBatch(
    WidgetRef ref,
    List<PendingToolCall> calls, {
    required bool approved,
  }) async {
    final result = await _submitBatch(ref, calls, approved: approved);
    final restoreKeys = _restoreKeys(calls, result);
    if (restoreKeys.isNotEmpty) onRestoreCalls(restoreKeys);
  }

  void _handleBatchError(_BatchApprovalErrorRequest request) {
    onRestoreCalls(request.hiddenKeys);

    _showApprovalActionError((
      context: request.context,
      errorMessageKey: request.approved
          ? LocaleKeys.tool_approval_errors_approve_once
          : LocaleKeys.tool_approval_errors_skip,
      error: request.error,
      stackTrace: request.stackTrace,
    ));
  }

  Future<BatchToolApprovalResult> _submitBatch(
    WidgetRef ref,
    List<PendingToolCall> calls, {
    required bool approved,
  }) {
    final actions = ref.read(batchToolApprovalUsecaseProvider);

    return approved
        ? actions.approveOnce(
            rootConversationId: conversationId,
            workspaceId: workspaceId,
            pendingCalls: calls,
          )
        : actions.skip(
            rootConversationId: conversationId,
            workspaceId: workspaceId,
            pendingCalls: calls,
          );
  }

  Set<String> _restoreKeys(
    List<PendingToolCall> calls,
    BatchToolApprovalResult result,
  ) {
    final handledKeys = {
      for (final item in [...result.claimed, ...result.alreadyHandled])
        '${item.conversationId}:${item.messageId}:${item.toolCallId}',
    };

    return {
      for (final call in calls)
        if (!handledKeys.contains(_pendingToolCallKey(call, conversationId)))
          _pendingToolCallKey(call, conversationId),
    };
  }
}

class const _ConfirmationButtons({
  required final String workspaceId,
  required final String conversationId,
  required final MessageToolCallEntity toolCall,
  required final String messageId,
  required final _StartApprovalDecision onDecisionStarted,
  required final _StartApprovalDecision onStopAllStarted,
  required final _RestoreApprovalCalls onDecisionFailed,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionHandler = _ConfirmationActionHandler(
      workspaceId: workspaceId,
      conversationId: conversationId,
      toolCall: toolCall,
      messageId: messageId,
      onDecisionStarted: onDecisionStarted,
      onStopAllStarted: onStopAllStarted,
      onDecisionFailed: onDecisionFailed,
    );

    return _ConfirmationButtonRows(
      ref: ref,
      context: context,
      handler: actionHandler,
    );
  }
}

class const _ConfirmationActionHandler({
  required final String workspaceId,
  required final String conversationId,
  required final MessageToolCallEntity toolCall,
  required final String messageId,
  required final _StartApprovalDecision onDecisionStarted,
  required final _StartApprovalDecision onStopAllStarted,
  required final _RestoreApprovalCalls onDecisionFailed,
}) {
  bool get _isCloudCall =>
      toolCall.turnId != null &&
      toolCall.turnRevision != null &&
      toolCall.argumentsDigest != null;
}

extension _ConfirmationApprovalActions on _ConfirmationActionHandler {
  Future<void> allowOnce(WidgetRef ref, BuildContext context) {
    return _runAction((
      context: context,
      errorMessageKey: LocaleKeys.tool_approval_errors_approve_once,
      action: () => _approve(ref, agent.AgentToolGrantLevel.once),
      onStarted: onDecisionStarted,
      onFailed: onDecisionFailed,
    ));
  }

  Future<void> allowForConversation(WidgetRef ref, BuildContext context) {
    return _runAction((
      context: context,
      errorMessageKey: LocaleKeys.tool_approval_errors_approve_conversation,
      action: () => _approve(ref, agent.AgentToolGrantLevel.conversation),
      onStarted: onDecisionStarted,
      onFailed: onDecisionFailed,
    ));
  }

  Future<void> skip(WidgetRef ref, BuildContext context) {
    return _runAction((
      context: context,
      errorMessageKey: LocaleKeys.tool_approval_errors_skip,
      action: () => _skip(ref),
      onStarted: onDecisionStarted,
      onFailed: onDecisionFailed,
    ));
  }

  Future<void> stopAll(WidgetRef ref, BuildContext context) {
    return _runAction((
      context: context,
      errorMessageKey: LocaleKeys.tool_approval_errors_stop_all,
      action: () => _stopAll(ref),
      onStarted: onStopAllStarted,
      onFailed: onDecisionFailed,
    ));
  }
}

extension _ConfirmationToolActions on _ConfirmationActionHandler {
  Future<void> _approve(WidgetRef ref, agent.AgentToolGrantLevel level) async {
    if (await _decideCloud(ref, approved: true)) return;

    await ref
        .read(auraAgentServiceProvider)
        .tools
        .approve(
          toolCallId: toolCall.id,
          messageId: messageId,
          conversationId: conversationId,
          level: level,
          approvalDigest: agent.toolCallApprovalDigest(
            messageId: messageId,
            toolName: toolCall.name,
            argumentsRaw: toolCall.argumentsRaw,
          ),
        );
  }

  Future<void> _skip(WidgetRef ref) async {
    if (await _decideCloud(ref, approved: false)) return;

    await ref
        .read(auraAgentServiceProvider)
        .tools
        .skip(
          toolCallId: toolCall.id,
          messageId: messageId,
          conversationId: conversationId,
        );
  }

  Future<void> _stopAll(WidgetRef ref) async {
    if (await _decideCloud(ref, approved: false, stopAll: true)) return;

    await ref
        .read(auraAgentServiceProvider)
        .tools
        .stopPending(messageId: messageId, conversationId: conversationId);
  }
}

typedef _CloudDecisionData = ({
  String conversationId,
  String turnId,
  int revision,
  String argumentsDigest,
});

class _CloudDecisionRequest {
  new({
    required this.cloud,
    required _CloudDecisionData decision,
    required MessageToolCallEntity toolCall,
    required this.approved,
    required this.stopAll,
  }) : conversationId = decision.conversationId,
       turnId = decision.turnId,
       toolCallId = toolCall.id,
       argumentsDigest = decision.argumentsDigest,
       revision = decision.revision,
       editedArgumentsJson = approved ? toolCall.argumentsRaw : null;

  final CloudTurnUsecase cloud;
  final String conversationId;
  final String turnId;
  final String toolCallId;
  final String argumentsDigest;
  final int revision;
  final bool approved;
  final String? editedArgumentsJson;
  final bool stopAll;
}

typedef _CloudExecutionRequest = ({
  WidgetRef ref,
  _CloudDecisionData decision,
  bool approved,
  bool stopAll,
});

typedef _RunApprovalActionRequest = ({
  BuildContext context,
  String errorMessageKey,
  Future<void> Function() action,
  _StartApprovalDecision onStarted,
  _RestoreApprovalCalls onFailed,
});

extension _ConfirmationCloudActions on _ConfirmationActionHandler {
  _CloudDecisionData? _cloudDecisionData() {
    final turnId = toolCall.turnId;
    final revision = toolCall.turnRevision;
    final argumentsDigest = toolCall.argumentsDigest;
    if (turnId == null || revision == null || argumentsDigest == null) {
      return null;
    }

    return (
      conversationId: conversationId,
      turnId: turnId,
      revision: revision,
      argumentsDigest: argumentsDigest,
    );
  }

  Future<CloudTurnUsecase> _cloudTurn(WidgetRef ref) async {
    final cloud = await ref.read(cloudTurnUsecaseProvider(workspaceId).future);
    if (cloud == null) throw StateError('Cloud turn unavailable');

    return cloud;
  }

  Future<bool> _decideCloud(
    WidgetRef ref, {
    required bool approved,
    bool stopAll = false,
  }) {
    final decision = _cloudDecisionData();
    if (decision == null) return Future.value(false);

    return _runCloudDecision((
      ref: ref,
      decision: decision,
      approved: approved,
      stopAll: stopAll,
    ));
  }

  Future<bool> _runCloudDecision(_CloudExecutionRequest request) async {
    final cloud = await _cloudTurn(request.ref);

    final _ = await _submitCloudDecision(
      .new(
        cloud: cloud,
        decision: request.decision,
        toolCall: toolCall,
        approved: request.approved,
        stopAll: request.stopAll,
      ),
    );

    return true;
  }
}

Future<Object?> _submitCloudDecision(_CloudDecisionRequest request) =>
    request.cloud.decide((
      conversationId: request.conversationId,
      turnId: request.turnId,
      toolCallId: request.toolCallId,
      argumentsDigest: request.argumentsDigest,
      revision: request.revision,
      approved: request.approved,
      editedArgumentsJson: request.editedArgumentsJson,
      stopAll: request.stopAll,
    ));

extension _ConfirmationActionExecution on _ConfirmationActionHandler {
  Future<void> _runAction(_RunApprovalActionRequest request) async {
    final hiddenKeys = request.onStarted();
    if (hiddenKeys == null) return;

    try {
      await request.action();
    } on Object catch (error, stackTrace) {
      request.onFailed(hiddenKeys);
      if (!request.context.mounted) return;
      _showApprovalActionError((
        context: request.context,
        errorMessageKey: request.errorMessageKey,
        error: error,
        stackTrace: stackTrace,
      ));
    }
  }
}

class const _ConfirmationButtonRows({
  required final WidgetRef ref,
  required final BuildContext context,
  required final _ConfirmationActionHandler handler,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _AllowButtons(ref: ref, actionContext: this.context, handler: handler),
        _DecisionButtons(
          ref: ref,
          actionContext: this.context,
          handler: handler,
        ),
      ],
      spacing: .sm,
    );
  }
}

class const _AllowButtons({
  required final WidgetRef ref,
  required final BuildContext actionContext,
  required final _ConfirmationActionHandler handler,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: _AllowButtonChildren(
      ref: ref,
      actionContext: actionContext,
      handler: handler,
    ).values,
  );
}

class _AllowButtonChildren {
  new({
    required WidgetRef ref,
    required BuildContext actionContext,
    required _ConfirmationActionHandler handler,
  }) : values = [
         Expanded(
           child: Semantics(
             key: const ValueKey<String>('tool_approval_allow_once'),
             child: AuraButton(
               onPressed: () =>
                   unawaited(handler.allowOnce(ref, actionContext)),
               child: const TextLocale(LocaleKeys.tool_confirmation_allow_once),
               variant: .outlined,
               size: .small,
             ),
             identifier: 'tool_approval_allow_once',
           ),
         ),
         if (!handler._isCloudCall)
           Expanded(
             child: Semantics(
               key: const ValueKey<String>('tool_approval_allow_conversation'),
               child: AuraButton(
                 onPressed: () => unawaited(
                   handler.allowForConversation(ref, actionContext),
                 ),
                 child: const TextLocale(
                   LocaleKeys.tool_confirmation_allow_conversation,
                 ),
                 variant: .outlined,
                 size: .small,
               ),
               identifier: 'tool_approval_allow_conversation',
             ),
           ),
       ];

  final List<Widget> values;
}

class const _DecisionButtons({
  required final WidgetRef ref,
  required final BuildContext actionContext,
  required final _ConfirmationActionHandler handler,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: _DecisionButtonChildren(
      ref: ref,
      actionContext: actionContext,
      handler: handler,
    ).values,
  );
}

class _DecisionButtonChildren {
  new({
    required WidgetRef ref,
    required BuildContext actionContext,
    required _ConfirmationActionHandler handler,
  }) : values = [
         Expanded(
           child: Semantics(
             key: const ValueKey<String>('tool_approval_skip'),
             child: AuraButton(
               onPressed: () => unawaited(handler.skip(ref, actionContext)),
               child: const TextLocale(LocaleKeys.tool_confirmation_skip),
               variant: .outlined,
               tint: .primary,
               size: .small,
             ),
             identifier: 'tool_approval_skip',
           ),
         ),
         Expanded(
           child: Semantics(
             key: const ValueKey<String>('tool_approval_stop_all'),
             child: AuraButton(
               onPressed: () => unawaited(handler.stopAll(ref, actionContext)),
               child: const TextLocale(LocaleKeys.tool_confirmation_stop_all),
               variant: .outlined,
               tint: .error,
               size: .small,
             ),
             identifier: 'tool_approval_stop_all',
           ),
         ),
       ];

  final List<Widget> values;
}
