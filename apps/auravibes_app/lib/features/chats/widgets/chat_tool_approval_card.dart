// Required: Existing thresholds and limits use numeric values.
// Required: Existing argument values intentionally repeat.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:convert';
import 'dart:math' as math;

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/providers/aura_agent_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_turn_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_app/utils/tool_metadata_decoder.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    as agent
    show AgentResolvedToolName, AgentToolGrantLevel, callSkillToolName;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

final _logger = Logger('chat_tool_approval_card');

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
    final asyncCalls = pendingCalls == null
        ? ref.watch(pendingToolCallsProvider(workspaceId, conversationId))
        : null;

    return _PendingToolCallsResult(
      workspaceId: workspaceId,
      pendingCalls: pendingCalls,
      asyncCalls: asyncCalls,
    );
  }
}

class const _PendingToolCallsResult({
  required final String workspaceId,
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
      pendingCalls: pendingCalls ?? asyncCalls?.value ?? const [],
    );
  }
}

class const _PendingToolCallsList({
  required final String workspaceId,
  required final List<PendingToolCall> pendingCalls,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => pendingCalls.isEmpty
      ? const SizedBox.shrink()
      : _PendingToolCallsPager(
          workspaceId: workspaceId,
          pendingCalls: pendingCalls,
        );
}

class const _PendingToolCallsPager({
  required final String workspaceId,
  required final List<PendingToolCall> pendingCalls,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(0);
    final lastIndex = pendingCalls.length - 1;
    useEffect(() => _resetPagerIndexEffect(currentIndex, lastIndex), [
      lastIndex,
    ]);

    return _PendingToolCallsPagerPage(
      workspaceId: workspaceId,
      pendingCalls: pendingCalls,
      currentIndex: currentIndex,
    );
  }
}

void _resetPagerIndex(ValueNotifier<int> currentIndex, int lastIndex) {
  if (currentIndex.value > lastIndex) currentIndex.value = lastIndex;
}

Dispose? _resetPagerIndexEffect(
  ValueNotifier<int> currentIndex,
  int lastIndex,
) {
  _resetPagerIndex(currentIndex, lastIndex);

  return null;
}

class const _PendingToolCallsPagerPage({
  required final String workspaceId,
  required final List<PendingToolCall> pendingCalls,
  required final ValueNotifier<int> currentIndex,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final page = _PendingToolCallsPageData(
      workspaceId: workspaceId,
      pendingCalls: pendingCalls,
      currentIndex: currentIndex,
    );

    return _PendingToolCallsPagerContent(request: page.request);
  }
}

class _PendingToolCallsPageData {
  new({
    required String workspaceId,
    required List<PendingToolCall> pendingCalls,
    required ValueNotifier<int> currentIndex,
  }) : request = _ApprovalCardRequest(
         workspaceId: workspaceId,
         pendingCalls: pendingCalls,
         currentIndexNotifier: currentIndex,
         selection: .new(pendingCalls, currentIndex),
       );

  final _ApprovalCardRequest request;
}

class _PendingToolCallsPageSelection {
  new(List<PendingToolCall> pendingCalls, ValueNotifier<int> currentIndex)
    : lastIndex = pendingCalls.length - 1,
      clamped = math.min(currentIndex.value, pendingCalls.length - 1);

  final int lastIndex;
  final int clamped;
}

class _ApprovalCardRequest {
  new({
    required this.workspaceId,
    required List<PendingToolCall> pendingCalls,
    required ValueNotifier<int> currentIndexNotifier,
    required _PendingToolCallsPageSelection selection,
  }) : current = pendingCalls[selection.clamped],
       currentIndex = selection.clamped,
       totalCount = pendingCalls.length,
       hasPrev = selection.clamped > 0,
       hasNext = selection.clamped < selection.lastIndex,
       onPrev = (() => currentIndexNotifier.value = selection.clamped - 1),
       onNext = (() => currentIndexNotifier.value = selection.clamped + 1);

  final String workspaceId;
  final PendingToolCall current;
  final int currentIndex;
  final int totalCount;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
}

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
    workspaceId: request.workspaceId,
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
          onPrev: request.onPrev,
          onNext: request.onNext,
        ),
        _ToolCallInfo(
          displayName: displayName,
          toolName: request.current.toolCall.name,
          argumentsRaw: request.current.toolCall.argumentsRaw,
          sourceLabel: request.current.sourceLabel,
        ),
        _ConfirmationButtons(
          workspaceId: request.workspaceId,
          toolCall: request.current.toolCall,
          messageId: request.current.messageId,
        ),
      ];

  final List<Widget> values;
}

class const _NavigationHeader({
  required final int currentIndex,
  required final int totalCount,
  required final bool hasPrev,
  required final bool hasNext,
  required final VoidCallback onPrev,
  required final VoidCallback onNext,
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
  required final VoidCallback onPrev,
  required final VoidCallback onNext,
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
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) : values = [
         _NavButton(
           icon: Icons.chevron_left,
           onPressed: hasPrev ? onPrev : null,
         ),
         const AuraSizedBox(width: .xs),
         _NavButton(
           icon: Icons.chevron_right,
           onPressed: hasNext ? onNext : null,
         ),
       ];

  final List<Widget> values;
}

class const _NavButton({
  required final IconData icon,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: icon,
      onPressed: onPressed,
      disabled: onPressed == null,
      size: .small,
    );
  }
}

class const _ToolCallInfo({
  required final String displayName,
  required final String toolName,
  required final String argumentsRaw,
  required final String? sourceLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final decodedArgs = _approvalArgumentsPreview(
      toolName: toolName,
      argumentsRaw: argumentsRaw,
    );

    return _ToolCallInfoFrame(
      child: _ToolCallInfoContent(
        displayName: displayName,
        sourceLabel: sourceLabel,
        decodedArgs: decodedArgs,
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
  required final String? decodedArgs,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        _ToolCallName(displayName: displayName),
        if (sourceLabel case final sourceLabel? when sourceLabel.isNotEmpty)
          _ToolCallSource(sourceLabel: sourceLabel),
        if (decodedArgs case final decodedArgs?)
          _ToolCallArgumentsPreview(value: decodedArgs),
      ],
    );
  }
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

class const _ToolCallSource({required final String sourceLabel})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final typography = context.auraTheme.typography;

    return Text(
      sourceLabel,
      style: .new(
        color: colors.onSurfaceVariant,
        fontSize: typography.fontSizeXs,
      ),
      overflow: .ellipsis,
    );
  }
}

class const _ToolCallArgumentsPreview({required final String value})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: _ToolCallArgumentsChildren(value: value, context: context).values,
  );
}

class _ToolCallArgumentsChildren {
  new({required String value, required BuildContext context})
    : values = [
        const AuraSizedBox(height: .xs),
        Text(
          value,
          style: _toolCallArgumentsStyle(context),
          overflow: .ellipsis,
          maxLines: 3,
        ),
      ];

  final List<Widget> values;
}

TextStyle _toolCallArgumentsStyle(BuildContext context) {
  final typography = context.auraTheme.typography;

  return .new(
    color: context.auraColors.onSurfaceVariant,
    fontSize: typography.fontSizeXs,
  );
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

String? _approvalArgumentsPreview({
  required String toolName,
  required String argumentsRaw,
}) {
  final decoded = _decodeApprovalArguments(argumentsRaw);
  if (!decoded.success) return ToolMetadataDecoder.decode(argumentsRaw);

  return _approvalArgumentsEncoder.convert(
    _buildApprovalPreview(toolName, decoded.value),
  );
}

_ApprovalDecodeResult _decodeApprovalArguments(String argumentsRaw) {
  try {
    return (success: true, value: jsonDecode(argumentsRaw));
  } on Exception {
    return (success: false, value: null);
  }
}

Map<String, Object?> _buildApprovalPreview(String toolName, Object? decoded) {
  final urlSummary = _urlRequestSummary(decoded);
  final preview = <String, Object?>{};
  if (urlSummary == null) {
    preview['arguments'] = _redactCredentialValues(decoded);
  }

  _addSkillPreview(preview, toolName);
  _addRequestPreview(preview, urlSummary);

  return preview;
}

void _addSkillPreview(Map<String, Object?> preview, String toolName) {
  final skillTool = ToolNameFormatter.parseSkillToolName(toolName);
  if (skillTool == null) return;

  preview['skill'] = {
    'source': skillTool.source,
    'skill': skillTool.skillSlug.toHumanReadable(),
    'tool': skillTool.toolSlug.toHumanReadable(),
  };
}

void _addRequestPreview(
  Map<String, Object?> preview,
  Map<String, String>? urlSummary,
) {
  if (urlSummary != null) preview['request'] = urlSummary;
}

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

Map<String, String>? _urlRequestSummary(Object? arguments) {
  final request = _urlRequest(arguments);
  if (request == null) return null;

  final url = request['url'];
  if (url is! String) return null;

  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return null;

  return _formatUrlRequestSummary(request, uri);
}

Map<Object?, Object?>? _urlRequest(Object? arguments) {
  if (arguments is! Map) return null;

  final request = arguments.cast<Object?, Object?>();
  final input = request['input'];
  if (request['url'] is String || input is! String) return request;

  return _decodeUrlRequestInput(input) ?? request;
}

Map<Object?, Object?>? _decodeUrlRequestInput(String input) {
  try {
    final decoded = jsonDecode(input);

    return decoded is Map ? decoded.cast<Object?, Object?>() : null;
  } on Exception {
    return null;
  }
}

Map<String, String> _formatUrlRequestSummary(
  Map<Object?, Object?> request,
  Uri uri,
) {
  final method = request['method'];

  return {
    'method': method is String ? method.toUpperCase() : 'GET',
    'host': uri.host,
    'path': uri.path.isEmpty ? '/' : uri.path,
  };
}

class const _ConfirmationButtons({
  required final String workspaceId,
  required final MessageToolCallEntity toolCall,
  required final String messageId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionHandler = _ConfirmationActionHandler(
      workspaceId: workspaceId,
      toolCall: toolCall,
      messageId: messageId,
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
  required final MessageToolCallEntity toolCall,
  required final String messageId,
}) {
  bool get _isCloudCall =>
      toolCall.turnId != null &&
      toolCall.turnRevision != null &&
      toolCall.argumentsDigest != null;
}

extension _ConfirmationApprovalActions on _ConfirmationActionHandler {
  Future<void> allowOnce(WidgetRef ref, BuildContext context) {
    return _runAction(
      context,
      errorMessageKey: LocaleKeys.tool_approval_errors_approve_once,
      action: () => _approve(ref, agent.AgentToolGrantLevel.once),
    );
  }

  Future<void> allowForConversation(WidgetRef ref, BuildContext context) {
    return _runAction(
      context,
      errorMessageKey: LocaleKeys.tool_approval_errors_approve_conversation,
      action: () => _approve(ref, agent.AgentToolGrantLevel.conversation),
    );
  }

  Future<void> skip(WidgetRef ref, BuildContext context) {
    return _runAction(
      context,
      errorMessageKey: LocaleKeys.tool_approval_errors_skip,
      action: () => _skip(ref),
    );
  }

  Future<void> stopAll(WidgetRef ref, BuildContext context) {
    return _runAction(
      context,
      errorMessageKey: LocaleKeys.tool_approval_errors_stop_all,
      action: () => _stopAll(ref),
    );
  }
}

extension _ConfirmationToolActions on _ConfirmationActionHandler {
  Future<void> _approve(WidgetRef ref, agent.AgentToolGrantLevel level) async {
    if (await _decideCloud(ref, approved: true)) return;

    await ref
        .read(auraAgentServiceProvider)
        .tools
        .approve(toolCallId: toolCall.id, messageId: messageId, level: level);
  }

  Future<void> _skip(WidgetRef ref) async {
    if (await _decideCloud(ref, approved: false)) return;

    await ref
        .read(auraAgentServiceProvider)
        .tools
        .skip(toolCallId: toolCall.id, messageId: messageId);
  }

  Future<void> _stopAll(WidgetRef ref) async {
    if (await _decideCloud(ref, approved: false, stopAll: true)) return;

    await ref
        .read(auraAgentServiceProvider)
        .tools
        .stopPending(messageId: messageId);
  }
}

typedef _CloudDecisionData = ({
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
  }) : turnId = decision.turnId,
       toolCallId = toolCall.id,
       argumentsDigest = decision.argumentsDigest,
       revision = decision.revision,
       editedArgumentsJson = approved ? toolCall.argumentsRaw : null;

  final CloudTurnUsecase cloud;
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

extension _ConfirmationCloudActions on _ConfirmationActionHandler {
  _CloudDecisionData? _cloudDecisionData() {
    final turnId = toolCall.turnId;
    final revision = toolCall.turnRevision;
    final argumentsDigest = toolCall.argumentsDigest;
    if (turnId == null || revision == null || argumentsDigest == null) {
      return null;
    }

    return (
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
      turnId: request.turnId,
      toolCallId: request.toolCallId,
      argumentsDigest: request.argumentsDigest,
      revision: request.revision,
      approved: request.approved,
      editedArgumentsJson: request.editedArgumentsJson,
      stopAll: request.stopAll,
    ));

extension _ConfirmationActionExecution on _ConfirmationActionHandler {
  Future<void> _runAction(
    BuildContext context, {
    required String errorMessageKey,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } on Exception catch (error, stackTrace) {
      _logger.warning('Tool approval action failed', error, stackTrace);
      if (!context.mounted) return;
      final _ = AuraSnackBars.show(
        context: context,
        content: TextLocale(errorMessageKey),
        variant: .error,
      );
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
           child: AuraButton(
             onPressed: () => handler.allowOnce(ref, actionContext),
             child: const TextLocale(LocaleKeys.tool_confirmation_allow_once),
             variant: .outlined,
             size: .small,
           ),
         ),
         if (!handler._isCloudCall)
           Expanded(
             child: AuraButton(
               onPressed: () =>
                   handler.allowForConversation(ref, actionContext),
               child: const TextLocale(
                 LocaleKeys.tool_confirmation_allow_conversation,
               ),
               variant: .outlined,
               size: .small,
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
           child: AuraButton(
             onPressed: () => handler.skip(ref, actionContext),
             child: const TextLocale(LocaleKeys.tool_confirmation_skip),
             variant: .outlined,
             tint: .primary,
             size: .small,
           ),
         ),
         Expanded(
           child: AuraButton(
             onPressed: () => handler.stopAll(ref, actionContext),
             child: const TextLocale(LocaleKeys.tool_confirmation_stop_all),
             variant: .outlined,
             tint: .error,
             size: .small,
           ),
         ),
       ];

  final List<Widget> values;
}
