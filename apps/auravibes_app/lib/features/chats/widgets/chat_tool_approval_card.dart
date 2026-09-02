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
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_app/utils/try_decode_tool_metadata.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    as agent
    show AgentToolGrantLevel;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

final _logger = Logger('chat_tool_approval_card');

class ChatToolApprovalCard extends HookConsumerWidget {
  const ChatToolApprovalCard({
    required this.workspaceId,
    required this.conversationId,
    this.pendingCalls,
    super.key,
  });

  final String workspaceId;
  final String conversationId;
  final List<PendingToolCall>? pendingCalls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectedCalls = pendingCalls;
    final asyncCalls = projectedCalls == null
        ? ref.watch(pendingToolCallsProvider(workspaceId, conversationId))
        : null;
    if (asyncCalls case AsyncError(:final error, :final stackTrace)) {
      _logger.warning('Pending tool calls failed', error, stackTrace);

      return const SizedBox.shrink();
    }
    final resolvedPendingCalls =
        projectedCalls ?? asyncCalls?.value ?? const <PendingToolCall>[];
    if (resolvedPendingCalls.isEmpty) return const SizedBox.shrink();

    final currentIndex = useState(0);
    final lastIndex = resolvedPendingCalls.length - 1;
    useEffect(
      () {
        if (currentIndex.value > lastIndex) {
          currentIndex.value = lastIndex;
        }

        return null;
      },
      [lastIndex],
    );

    final clamped = math.min(currentIndex.value, lastIndex);

    final item = resolvedPendingCalls[clamped];
    final total = resolvedPendingCalls.length;

    return _ApprovalCardContent(
      workspaceId: workspaceId,
      current: item,
      currentIndex: clamped,
      totalCount: total,
      hasPrev: clamped > 0,
      hasNext: clamped < total - 1,
      onPrev: () => currentIndex.value = clamped - 1,
      onNext: () => currentIndex.value = clamped + 1,
    );
  }
}

class _ApprovalCardContent extends ConsumerWidget {
  const _ApprovalCardContent({
    required this.workspaceId,
    required this.current,
    required this.currentIndex,
    required this.totalCount,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  final String workspaceId;

  final PendingToolCall current;
  final int currentIndex;
  final int totalCount;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auraColors = context.auraColors;
    final toolCall = current.toolCall;

    final displayNameAsync = ref.watch(
      toolDisplayNameProvider(workspaceId, toolCall.name),
    );
    final displayName = displayNameAsync.maybeWhen(
      data: (name) => name,
      orElse: () => ToolNameFormatter.formatDisplayName(
        ToolNameFormatter.parse(toolCall.name),
        rawName: toolCall.name,
      ),
    );

    return Container(
      padding: EdgeInsets.all(
        context.auraTheme.fromSpacing(.md),
      ),
      decoration: BoxDecoration(
        color: auraColors.warning.withValues(alpha: 0.08),
        border: Border.all(
          color: auraColors.warning.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(
            context.auraTheme.fromBorderRadius(.lg),
          ),
        ),
      ),
      width: double.infinity,
      margin: EdgeInsets.all(
        context.auraTheme.fromSpacing(.md),
      ),
      child: AuraColumn(
        children: [
          _NavigationHeader(
            currentIndex: currentIndex,
            totalCount: totalCount,
            hasPrev: hasPrev,
            hasNext: hasNext,
            onPrev: onPrev,
            onNext: onNext,
          ),
          _ToolCallInfo(
            displayName: displayName,
            toolName: toolCall.name,
            argumentsRaw: toolCall.argumentsRaw,
            sourceLabel: current.sourceLabel,
          ),
          _ConfirmationButtons(
            workspaceId: workspaceId,
            toolCall: toolCall,
            messageId: current.messageId,
          ),
        ],
        spacing: .sm,
      ),
    );
  }
}

class _NavigationHeader extends StatelessWidget {
  const _NavigationHeader({
    required this.currentIndex,
    required this.totalCount,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  final int currentIndex;
  final int totalCount;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Row(
      children: [
        Icon(
          Icons.build_outlined,
          size: 16,
          color: auraColors.warning,
        ),
        const AuraSizedBox(width: .xs),
        Expanded(
          child: Text(
            LocaleKeys.tool_approval_pending_count.tr(
              args: [(currentIndex + 1).toString(), totalCount.toString()],
            ),
            style: TextStyle(
              color: auraColors.onSurface,
              fontSize: context.auraTheme.typography.fontSizeSm,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_left,
          onPressed: hasPrev ? onPrev : null,
        ),
        const AuraSizedBox(width: .xs),
        _NavButton(
          icon: Icons.chevron_right,
          onPressed: hasNext ? onNext : null,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: icon,
      onPressed: onPressed,
      disabled: onPressed == null,
      size: AuraIconSize.small,
    );
  }
}

class _ToolCallInfo extends StatelessWidget {
  const _ToolCallInfo({
    required this.displayName,
    required this.toolName,
    required this.argumentsRaw,
    required this.sourceLabel,
  });

  final String displayName;
  final String toolName;
  final String argumentsRaw;
  final String? sourceLabel;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final decodedArgs = _approvalArgumentsPreview(
      toolName: toolName,
      argumentsRaw: argumentsRaw,
    );

    return Container(
      padding: EdgeInsets.all(
        context.auraTheme.fromSpacing(.sm),
      ),
      decoration: BoxDecoration(
        color: auraColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.all(
          Radius.circular(
            context.auraTheme.fromBorderRadius(.sm),
          ),
        ),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: TextStyle(
              color: auraColors.onSurface,
              fontSize: context.auraTheme.typography.fontSizeSm,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (sourceLabel case final sourceLabel? when sourceLabel.isNotEmpty)
            Text(
              sourceLabel,
              style: TextStyle(
                color: auraColors.onSurfaceVariant,
                fontSize: context.auraTheme.typography.fontSizeXs,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          if (decodedArgs != null) ...[
            const AuraSizedBox(height: .xs),
            Text(
              decodedArgs,
              style: TextStyle(
                color: auraColors.onSurfaceVariant,
                fontSize: context.auraTheme.typography.fontSizeXs,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }
}

const JsonEncoder _approvalArgumentsEncoder = JsonEncoder.withIndent('  ');
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

String? _approvalArgumentsPreview({
  required String toolName,
  required String argumentsRaw,
}) {
  Object? decoded;
  try {
    decoded = jsonDecode(argumentsRaw);
  } on Exception catch (_) {
    return tryDecodeToolMetadata(argumentsRaw);
  }

  final urlSummary = _urlRequestSummary(decoded);
  final preview = <String, Object?>{
    if (urlSummary == null) 'arguments': _redactCredentialValues(decoded),
  };
  final skillTool = ToolNameFormatter.parseSkillToolName(toolName);
  if (skillTool != null) {
    preview['skill'] = {
      'source': skillTool.source,
      'skill': skillTool.skillSlug.toHumanReadable(),
      'tool': skillTool.toolSlug.toHumanReadable(),
    };
  }
  if (urlSummary != null) {
    preview['request'] = urlSummary;
  }

  return _approvalArgumentsEncoder.convert(preview);
}

Object? _redactCredentialValues(Object? value) {
  if (value is List) {
    return value.map(_redactCredentialValues).toList();
  }

  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key: _isSensitiveKey(entry.key)
            ? _redactedValue
            : _redactCredentialValues(entry.value),
    };
  }

  if (value is String) {
    final decoded = _tryDecodeJsonString(value);
    if (decoded == null) return value;

    return _redactCredentialValues(decoded);
  }

  return value;
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
  if (arguments is! Map) return null;

  var request = arguments;
  final input = arguments['input'];
  if (arguments['url'] is! String && input is String) {
    try {
      final decodedInput = jsonDecode(input);
      if (decodedInput is Map) request = decodedInput;
    } on Exception catch (_) {}
  }

  final url = request['url'];
  if (url is! String) return null;

  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return null;

  final method = request['method'];

  return {
    'method': method is String ? method.toUpperCase() : 'GET',
    'host': uri.host,
    'path': uri.path.isEmpty ? '/' : uri.path,
  };
}

class _ConfirmationButtons extends ConsumerWidget {
  const _ConfirmationButtons({
    required this.workspaceId,
    required this.toolCall,
    required this.messageId,
  });

  final String workspaceId;
  final MessageToolCallEntity toolCall;
  final String messageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCloudCall =
        toolCall.turnId != null &&
        toolCall.turnRevision != null &&
        toolCall.argumentsDigest != null;

    return AuraColumn(
      children: [
        AuraRow(
          children: [
            Expanded(
              child: AuraButton(
                onPressed: () => _onAllowOnce(ref, context),
                child: const TextLocale(
                  LocaleKeys.tool_confirmation_allow_once,
                ),
                variant: AuraButtonVariant.outlined,
                size: AuraButtonSize.small,
              ),
            ),
            if (!isCloudCall)
              Expanded(
                child: AuraButton(
                  onPressed: () => _onAllowForConversation(ref, context),
                  child: const TextLocale(
                    LocaleKeys.tool_confirmation_allow_conversation,
                  ),
                  variant: AuraButtonVariant.outlined,
                  size: AuraButtonSize.small,
                ),
              ),
          ],
        ),
        AuraRow(
          children: [
            Expanded(
              child: AuraButton(
                onPressed: () => _onSkip(ref, context),
                child: const TextLocale(LocaleKeys.tool_confirmation_skip),
                variant: AuraButtonVariant.outlined,
                tint: .primary,
                size: AuraButtonSize.small,
              ),
            ),
            Expanded(
              child: AuraButton(
                onPressed: () => _onStopAll(ref, context),
                child: const TextLocale(
                  LocaleKeys.tool_confirmation_stop_all,
                ),
                variant: AuraButtonVariant.outlined,
                tint: .error,
                size: AuraButtonSize.small,
              ),
            ),
          ],
        ),
      ],
      spacing: .sm,
    );
  }

  Future<void> _onAllowOnce(WidgetRef ref, BuildContext context) async {
    await _runAction(
      context,
      errorMessageKey: LocaleKeys.tool_approval_errors_approve_once,
      action: () async {
        final turnId = toolCall.turnId;
        final revision = toolCall.turnRevision;
        final argumentsDigest = toolCall.argumentsDigest;
        if (turnId != null && revision != null && argumentsDigest != null) {
          final cloud = await ref.read(
            cloudTurnUsecaseProvider(workspaceId).future,
          );
          if (cloud == null) throw StateError('Cloud turn unavailable');

          return switch (await cloud.decide(
            turnId: turnId,
            toolCallId: toolCall.id,
            argumentsDigest: argumentsDigest,
            revision: revision,
            approved: true,
            editedArgumentsJson: toolCall.argumentsRaw,
          )) {
            _ => null,
          };
        }

        return ref
            .read(auraAgentServiceProvider)
            .tools
            .approve(
              toolCallId: toolCall.id,
              messageId: messageId,
              level: agent.AgentToolGrantLevel.once,
            );
      },
    );
  }

  Future<void> _onAllowForConversation(
    WidgetRef ref,
    BuildContext context,
  ) async {
    await _runAction(
      context,
      errorMessageKey: LocaleKeys.tool_approval_errors_approve_conversation,
      action: () async {
        final turnId = toolCall.turnId;
        final revision = toolCall.turnRevision;
        final argumentsDigest = toolCall.argumentsDigest;
        if (turnId != null && revision != null && argumentsDigest != null) {
          final cloud = await ref.read(
            cloudTurnUsecaseProvider(workspaceId).future,
          );
          if (cloud == null) throw StateError('Cloud turn unavailable');

          return switch (await cloud.decide(
            turnId: turnId,
            toolCallId: toolCall.id,
            argumentsDigest: argumentsDigest,
            revision: revision,
            approved: true,
            editedArgumentsJson: toolCall.argumentsRaw,
          )) {
            _ => null,
          };
        }

        return ref
            .read(auraAgentServiceProvider)
            .tools
            .approve(
              toolCallId: toolCall.id,
              messageId: messageId,
              level: agent.AgentToolGrantLevel.conversation,
            );
      },
    );
  }

  Future<void> _onSkip(WidgetRef ref, BuildContext context) async {
    await _runAction(
      context,
      errorMessageKey: LocaleKeys.tool_approval_errors_skip,
      action: () async {
        final turnId = toolCall.turnId;
        final revision = toolCall.turnRevision;
        final argumentsDigest = toolCall.argumentsDigest;
        if (turnId != null && revision != null && argumentsDigest != null) {
          final cloud = await ref.read(
            cloudTurnUsecaseProvider(workspaceId).future,
          );
          if (cloud == null) throw StateError('Cloud turn unavailable');

          return switch (await cloud.decide(
            turnId: turnId,
            toolCallId: toolCall.id,
            argumentsDigest: argumentsDigest,
            revision: revision,
            approved: false,
          )) {
            _ => null,
          };
        }

        return ref
            .read(auraAgentServiceProvider)
            .tools
            .skip(
              toolCallId: toolCall.id,
              messageId: messageId,
            );
      },
    );
  }

  Future<void> _onStopAll(WidgetRef ref, BuildContext context) async {
    final turnId = toolCall.turnId;
    final revision = toolCall.turnRevision;
    final argumentsDigest = toolCall.argumentsDigest;
    if (turnId != null && revision != null && argumentsDigest != null) {
      return _runAction(
        context,
        errorMessageKey: LocaleKeys.tool_approval_errors_stop_all,
        action: () async {
          final cloud = await ref.read(
            cloudTurnUsecaseProvider(workspaceId).future,
          );
          if (cloud == null) throw StateError('Cloud turn unavailable');
          final _ = await cloud.decide(
            turnId: turnId,
            toolCallId: toolCall.id,
            argumentsDigest: argumentsDigest,
            revision: revision,
            approved: false,
            stopAll: true,
          );
        },
      );
    }
    await _runAction(
      context,
      errorMessageKey: LocaleKeys.tool_approval_errors_stop_all,
      action: () {
        return ref
            .read(auraAgentServiceProvider)
            .tools
            .stopPending(
              messageId: messageId,
            );
      },
    );
  }

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
      final _ = showAuraSnackBar(
        context: context,
        content: TextLocale(errorMessageKey),
        variant: AuraSnackBarVariant.error,
      );
    }
  }
}
