// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grouped_tools_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the tools groups repository.

@ProviderFor(toolsGroupsRepository)
final toolsGroupsRepositoryProvider = ToolsGroupsRepositoryProvider._();

/// Provider for the tools groups repository.

final class ToolsGroupsRepositoryProvider
    extends
        $FunctionalProvider<
          ToolsGroupsRepositoryContract,
          ToolsGroupsRepositoryContract,
          ToolsGroupsRepositoryContract
        >
    with $Provider<ToolsGroupsRepositoryContract> {
  /// Provider for the tools groups repository.
  ToolsGroupsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toolsGroupsRepositoryProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          workspaceSessionProvider,
          cloudWorkspaceStateGatewayProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ToolsGroupsRepositoryProvider.$allTransitiveDependencies0,
          ToolsGroupsRepositoryProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = workspaceSessionProvider;
  static final $allTransitiveDependencies1 = cloudWorkspaceStateGatewayProvider;

  @override
  String debugGetCreateSourceHash() => _$toolsGroupsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ToolsGroupsRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ToolsGroupsRepositoryContract create(Ref ref) {
    return toolsGroupsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToolsGroupsRepositoryContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToolsGroupsRepositoryContract>(
        value,
      ),
    );
  }
}

String _$toolsGroupsRepositoryHash() =>
    r'21fb43ba53e76cd895854e3a4b3a525f6353e6a7';

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all tools groups for the current workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Sorts groups: Default first, then MCP errors, then by creation date

@ProviderFor(GroupedToolsNotifier)
final groupedToolsProvider = GroupedToolsNotifierFamily._();

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all tools groups for the current workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Sorts groups: Default first, then MCP errors, then by creation date
final class GroupedToolsNotifierProvider
    extends
        $AsyncNotifierProvider<
          GroupedToolsNotifier,
          List<ToolsGroupWithTools>
        > {
  /// Provider that groups tools by their workspaceToolsGroupId.
  ///
  /// This provider:
  /// - Fetches all tools groups for the current workspace
  /// - Groups tools by their workspaceToolsGroupId
  /// - Creates a "Built-in Tools" virtual group for tools without a group
  /// - Enriches MCP groups with their connection state
  /// - Sorts groups: Default first, then MCP errors, then by creation date
  GroupedToolsNotifierProvider._({
    required GroupedToolsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'groupedToolsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = toolsGroupsRepositoryProvider;
  static final $allTransitiveDependencies1 =
      ToolsGroupsRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      ToolsGroupsRepositoryProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 = workspaceToolsProvider;
  static final $allTransitiveDependencies4 =
      WorkspaceToolsNotifierProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies5 = mcpConnectionProvider;
  static final $allTransitiveDependencies6 =
      McpConnectionNotifierProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$groupedToolsNotifierHash();

  @override
  String toString() {
    return r'groupedToolsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  GroupedToolsNotifier create() => GroupedToolsNotifier();

  @override
  bool operator ==(Object other) {
    return other is GroupedToolsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupedToolsNotifierHash() =>
    r'075af298075f5c6b50389ec512e0161447ab605c';

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all tools groups for the current workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Sorts groups: Default first, then MCP errors, then by creation date

final class GroupedToolsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GroupedToolsNotifier,
          AsyncValue<List<ToolsGroupWithTools>>,
          List<ToolsGroupWithTools>,
          FutureOr<List<ToolsGroupWithTools>>,
          String
        > {
  GroupedToolsNotifierFamily._()
    : super(
        retry: null,
        name: r'groupedToolsProvider',
        dependencies: <ProviderOrFamily>[
          toolsGroupsRepositoryProvider,
          workspaceToolsProvider,
          mcpConnectionProvider,
          mcpServersRepositoryProvider,
          workspaceSessionProvider,
          cloudWorkspaceStateGatewayProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          GroupedToolsNotifierProvider.$allTransitiveDependencies0,
          GroupedToolsNotifierProvider.$allTransitiveDependencies1,
          GroupedToolsNotifierProvider.$allTransitiveDependencies2,
          GroupedToolsNotifierProvider.$allTransitiveDependencies3,
          GroupedToolsNotifierProvider.$allTransitiveDependencies4,
          GroupedToolsNotifierProvider.$allTransitiveDependencies5,
          GroupedToolsNotifierProvider.$allTransitiveDependencies6,
        },
        isAutoDispose: true,
      );

  /// Provider that groups tools by their workspaceToolsGroupId.
  ///
  /// This provider:
  /// - Fetches all tools groups for the current workspace
  /// - Groups tools by their workspaceToolsGroupId
  /// - Creates a "Built-in Tools" virtual group for tools without a group
  /// - Enriches MCP groups with their connection state
  /// - Sorts groups: Default first, then MCP errors, then by creation date

  GroupedToolsNotifierProvider call(String workspaceId) =>
      GroupedToolsNotifierProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'groupedToolsProvider';
}

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all tools groups for the current workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Sorts groups: Default first, then MCP errors, then by creation date

abstract class _$GroupedToolsNotifier
    extends $AsyncNotifier<List<ToolsGroupWithTools>> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  FutureOr<List<ToolsGroupWithTools>> build(String workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ToolsGroupWithTools>>,
              List<ToolsGroupWithTools>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ToolsGroupWithTools>>,
                List<ToolsGroupWithTools>
              >,
              AsyncValue<List<ToolsGroupWithTools>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Provider that returns the count of enabled tools across all groups.

@ProviderFor(enabledToolsCount)
final enabledToolsCountProvider = EnabledToolsCountFamily._();

/// Provider that returns the count of enabled tools across all groups.

final class EnabledToolsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider that returns the count of enabled tools across all groups.
  EnabledToolsCountProvider._({
    required EnabledToolsCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'enabledToolsCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = groupedToolsProvider;
  static final $allTransitiveDependencies1 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies5 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies4;
  static final $allTransitiveDependencies6 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies5;
  static final $allTransitiveDependencies7 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies6;

  @override
  String debugGetCreateSourceHash() => _$enabledToolsCountHash();

  @override
  String toString() {
    return r'enabledToolsCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return enabledToolsCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EnabledToolsCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$enabledToolsCountHash() => r'fb71a22f446d6b290a8ceb5ce0dcd5018127363c';

/// Provider that returns the count of enabled tools across all groups.

final class EnabledToolsCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  EnabledToolsCountFamily._()
    : super(
        retry: null,
        name: r'enabledToolsCountProvider',
        dependencies: <ProviderOrFamily>[groupedToolsProvider],
        $allTransitiveDependencies: <ProviderOrFamily>{
          EnabledToolsCountProvider.$allTransitiveDependencies0,
          EnabledToolsCountProvider.$allTransitiveDependencies1,
          EnabledToolsCountProvider.$allTransitiveDependencies2,
          EnabledToolsCountProvider.$allTransitiveDependencies3,
          EnabledToolsCountProvider.$allTransitiveDependencies4,
          EnabledToolsCountProvider.$allTransitiveDependencies5,
          EnabledToolsCountProvider.$allTransitiveDependencies6,
          EnabledToolsCountProvider.$allTransitiveDependencies7,
        },
        isAutoDispose: true,
      );

  /// Provider that returns the count of enabled tools across all groups.

  EnabledToolsCountProvider call(String workspaceId) =>
      EnabledToolsCountProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'enabledToolsCountProvider';
}

/// Provider that returns the total count of tools across all groups.

@ProviderFor(totalToolsCount)
final totalToolsCountProvider = TotalToolsCountFamily._();

/// Provider that returns the total count of tools across all groups.

final class TotalToolsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider that returns the total count of tools across all groups.
  TotalToolsCountProvider._({
    required TotalToolsCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'totalToolsCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = groupedToolsProvider;
  static final $allTransitiveDependencies1 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies5 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies4;
  static final $allTransitiveDependencies6 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies5;
  static final $allTransitiveDependencies7 =
      GroupedToolsNotifierProvider.$allTransitiveDependencies6;

  @override
  String debugGetCreateSourceHash() => _$totalToolsCountHash();

  @override
  String toString() {
    return r'totalToolsCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return totalToolsCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TotalToolsCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$totalToolsCountHash() => r'73b828e83271a407339c56be8da9b998c033bb00';

/// Provider that returns the total count of tools across all groups.

final class TotalToolsCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  TotalToolsCountFamily._()
    : super(
        retry: null,
        name: r'totalToolsCountProvider',
        dependencies: <ProviderOrFamily>[groupedToolsProvider],
        $allTransitiveDependencies: <ProviderOrFamily>{
          TotalToolsCountProvider.$allTransitiveDependencies0,
          TotalToolsCountProvider.$allTransitiveDependencies1,
          TotalToolsCountProvider.$allTransitiveDependencies2,
          TotalToolsCountProvider.$allTransitiveDependencies3,
          TotalToolsCountProvider.$allTransitiveDependencies4,
          TotalToolsCountProvider.$allTransitiveDependencies5,
          TotalToolsCountProvider.$allTransitiveDependencies6,
          TotalToolsCountProvider.$allTransitiveDependencies7,
        },
        isAutoDispose: true,
      );

  /// Provider that returns the total count of tools across all groups.

  TotalToolsCountProvider call(String workspaceId) =>
      TotalToolsCountProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'totalToolsCountProvider';
}
