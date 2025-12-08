// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grouped_conversation_tools_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider that groups conversation tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all conversation tool states for the workspace/conversation
/// - Fetches all tools groups for the workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Filters out empty groups
/// - Sorts groups: Default first, then MCP errors, then by creation date

@ProviderFor(GroupedConversationToolsNotifier)
const groupedConversationToolsProvider =
    GroupedConversationToolsNotifierFamily._();

/// Provider that groups conversation tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all conversation tool states for the workspace/conversation
/// - Fetches all tools groups for the workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Filters out empty groups
/// - Sorts groups: Default first, then MCP errors, then by creation date
final class GroupedConversationToolsNotifierProvider
    extends
        $AsyncNotifierProvider<
          GroupedConversationToolsNotifier,
          List<ConversationToolsGroupWithTools>
        > {
  /// Provider that groups conversation tools by their workspaceToolsGroupId.
  ///
  /// This provider:
  /// - Fetches all conversation tool states for the workspace/conversation
  /// - Fetches all tools groups for the workspace
  /// - Groups tools by their workspaceToolsGroupId
  /// - Creates a "Built-in Tools" virtual group for tools without a group
  /// - Enriches MCP groups with their connection state
  /// - Filters out empty groups
  /// - Sorts groups: Default first, then MCP errors, then by creation date
  const GroupedConversationToolsNotifierProvider._({
    required GroupedConversationToolsNotifierFamily super.from,
    required ({String workspaceId, String? conversationId}) super.argument,
  }) : super(
         retry: null,
         name: r'groupedConversationToolsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupedConversationToolsNotifierHash();

  @override
  String toString() {
    return r'groupedConversationToolsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GroupedConversationToolsNotifier create() =>
      GroupedConversationToolsNotifier();

  @override
  bool operator ==(Object other) {
    return other is GroupedConversationToolsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupedConversationToolsNotifierHash() =>
    r'a3c5feb8affd2cfa50f8ecd5850ac644ed501603';

/// Provider that groups conversation tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all conversation tool states for the workspace/conversation
/// - Fetches all tools groups for the workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Filters out empty groups
/// - Sorts groups: Default first, then MCP errors, then by creation date

final class GroupedConversationToolsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GroupedConversationToolsNotifier,
          AsyncValue<List<ConversationToolsGroupWithTools>>,
          List<ConversationToolsGroupWithTools>,
          FutureOr<List<ConversationToolsGroupWithTools>>,
          ({String workspaceId, String? conversationId})
        > {
  const GroupedConversationToolsNotifierFamily._()
    : super(
        retry: null,
        name: r'groupedConversationToolsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider that groups conversation tools by their workspaceToolsGroupId.
  ///
  /// This provider:
  /// - Fetches all conversation tool states for the workspace/conversation
  /// - Fetches all tools groups for the workspace
  /// - Groups tools by their workspaceToolsGroupId
  /// - Creates a "Built-in Tools" virtual group for tools without a group
  /// - Enriches MCP groups with their connection state
  /// - Filters out empty groups
  /// - Sorts groups: Default first, then MCP errors, then by creation date

  GroupedConversationToolsNotifierProvider call({
    required String workspaceId,
    String? conversationId,
  }) => GroupedConversationToolsNotifierProvider._(
    argument: (workspaceId: workspaceId, conversationId: conversationId),
    from: this,
  );

  @override
  String toString() => r'groupedConversationToolsProvider';
}

/// Provider that groups conversation tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all conversation tool states for the workspace/conversation
/// - Fetches all tools groups for the workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Filters out empty groups
/// - Sorts groups: Default first, then MCP errors, then by creation date

abstract class _$GroupedConversationToolsNotifier
    extends $AsyncNotifier<List<ConversationToolsGroupWithTools>> {
  late final _$args =
      ref.$arg as ({String workspaceId, String? conversationId});
  String get workspaceId => _$args.workspaceId;
  String? get conversationId => _$args.conversationId;

  FutureOr<List<ConversationToolsGroupWithTools>> build({
    required String workspaceId,
    String? conversationId,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      workspaceId: _$args.workspaceId,
      conversationId: _$args.conversationId,
    );
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ConversationToolsGroupWithTools>>,
              List<ConversationToolsGroupWithTools>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ConversationToolsGroupWithTools>>,
                List<ConversationToolsGroupWithTools>
              >,
              AsyncValue<List<ConversationToolsGroupWithTools>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
