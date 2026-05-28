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
          ToolsGroupsRepository,
          ToolsGroupsRepository,
          ToolsGroupsRepository
        >
    with $Provider<ToolsGroupsRepository> {
  /// Provider for the tools groups repository.
  ToolsGroupsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toolsGroupsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toolsGroupsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ToolsGroupsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ToolsGroupsRepository create(Ref ref) {
    return toolsGroupsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToolsGroupsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToolsGroupsRepository>(value),
    );
  }
}

String _$toolsGroupsRepositoryHash() =>
    r'5f6c759f37826b765d3f11898e4dabb4e1e42afb';

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
    r'7d5e97c3537198b10c9b1f1f06fcaf6d9affaebc';

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
        dependencies: null,
        $allTransitiveDependencies: null,
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
  void runBuild() {
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
    element.handleCreate(ref, () => build(_$args));
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

String _$enabledToolsCountHash() => r'8b2b496ae84eee9417a256708a5c99890327af31';

/// Provider that returns the count of enabled tools across all groups.

final class EnabledToolsCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  EnabledToolsCountFamily._()
    : super(
        retry: null,
        name: r'enabledToolsCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
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

String _$totalToolsCountHash() => r'65fe5867268d59f0c7816a38e7f644c7467e3435';

/// Provider that returns the total count of tools across all groups.

final class TotalToolsCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  TotalToolsCountFamily._()
    : super(
        retry: null,
        name: r'totalToolsCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider that returns the total count of tools across all groups.

  TotalToolsCountProvider call(String workspaceId) =>
      TotalToolsCountProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'totalToolsCountProvider';
}
