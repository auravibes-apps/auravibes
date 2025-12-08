// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grouped_tools_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the tools groups repository.

@ProviderFor(toolsGroupsRepository)
const toolsGroupsRepositoryProvider = ToolsGroupsRepositoryProvider._();

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
  const ToolsGroupsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toolsGroupsRepositoryProvider',
        isAutoDispose: true,
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
    r'2cd1bbd7e89ccf78b38467f66d2bb02ddfc91f8a';

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all tools groups for the current workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Sorts groups: Default first, then MCP errors, then by creation date

@ProviderFor(GroupedToolsNotifier)
const groupedToolsProvider = GroupedToolsNotifierProvider._();

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
  const GroupedToolsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupedToolsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupedToolsNotifierHash();

  @$internal
  @override
  GroupedToolsNotifier create() => GroupedToolsNotifier();
}

String _$groupedToolsNotifierHash() =>
    r'a5d5ac1dc750dd2cbeb3040ea09600ec9455c7bf';

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
  FutureOr<List<ToolsGroupWithTools>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
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
    element.handleValue(ref, created);
  }
}

/// Provider that returns the count of enabled tools across all groups.

@ProviderFor(enabledToolsCount)
const enabledToolsCountProvider = EnabledToolsCountProvider._();

/// Provider that returns the count of enabled tools across all groups.

final class EnabledToolsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider that returns the count of enabled tools across all groups.
  const EnabledToolsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'enabledToolsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$enabledToolsCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return enabledToolsCount(ref);
  }
}

String _$enabledToolsCountHash() => r'236aa0dd26328a7461e4efe5f77b6f203ffaf1c3';

/// Provider that returns the total count of tools across all groups.

@ProviderFor(totalToolsCount)
const totalToolsCountProvider = TotalToolsCountProvider._();

/// Provider that returns the total count of tools across all groups.

final class TotalToolsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider that returns the total count of tools across all groups.
  const TotalToolsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalToolsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalToolsCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return totalToolsCount(ref);
  }
}

String _$totalToolsCountHash() => r'9c10c31063d0fe6c0a09158c6ba18402fde69bbd';
