// lib/domain/usecases/tools/filter_tools_by_permission_usecase.dart
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/check_tool_permission_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/update_message_metadata_usecase.dart';

/// Result of filtering tools by permission
class FilteredToolsResult {
  FilteredToolsResult({
    required this.grantedTools,
    required this.resolvedUpdates,
    required this.hasPendingTools,
  });

  final List<ToolToCall> grantedTools;
  final List<ToolResultUpdate> resolvedUpdates;
  final bool hasPendingTools;
}

/// Use case for filtering tools by permission.
///
/// This is a simple class with constructor injection - no Riverpod.
class FilterToolsByPermissionUseCase {
  const FilterToolsByPermissionUseCase(
    this._checkPermissionUseCase,
    this._updateMetadataUseCase,
  );

  final CheckToolPermissionUseCase _checkPermissionUseCase;
  final UpdateMessageMetadataUseCase _updateMetadataUseCase;

  /// Categorizes tools by permission and returns granted tools +
  /// resolved updates
  Future<FilteredToolsResult> call({
    required List<ToolToCall> tools,
    required String conversationId,
    required String workspaceId,
    required String responseMessageId,
  }) async {
    final grantedTools = <ToolToCall>[];
    final resolvedUpdates = <ToolResultUpdate>[];
    var hasPendingTools = false;

    for (final toolToCall in tools) {
      // Validate built-in tool exists
      if (toolToCall.tool.isBuiltIn && toolToCall.tool.builtInTool == null) {
        resolvedUpdates.add(
          ToolResultUpdate(
            toolCallId: toolToCall.id,
            resultStatus: ToolCallResultStatus.toolNotFound,
          ),
        );
        continue;
      }

      // Check permission
      final permission = await _checkPermissionUseCase(
        conversationId: conversationId,
        workspaceId: workspaceId,
        resolvedTool: toolToCall.tool,
      );

      switch (permission) {
        case ToolPermissionResult.granted:
          grantedTools.add(toolToCall);

        case ToolPermissionResult.needsConfirmation:
          hasPendingTools = true;
          // Don't add to resolved - leave as pending
          continue;

        case ToolPermissionResult.notConfigured:
          resolvedUpdates.add(
            ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.notConfigured,
            ),
          );

        case ToolPermissionResult.disabledInConversation:
          resolvedUpdates.add(
            ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.disabledInConversation,
            ),
          );

        case ToolPermissionResult.disabledInWorkspace:
          resolvedUpdates.add(
            ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.disabledInWorkspace,
            ),
          );
      }
    }

    // Persist resolved updates immediately
    if (resolvedUpdates.isNotEmpty) {
      await _updateMetadataUseCase.call(
        messageId: responseMessageId,
        updates: resolvedUpdates,
      );
    }

    return FilteredToolsResult(
      grantedTools: grantedTools,
      resolvedUpdates: resolvedUpdates,
      hasPendingTools: hasPendingTools,
    );
  }
}
