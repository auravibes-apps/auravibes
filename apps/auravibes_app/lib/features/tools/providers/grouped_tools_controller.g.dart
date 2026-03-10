// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grouped_tools_controller.dart';

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

@ProviderFor(GroupedToolsController)
final groupedToolsControllerProvider = GroupedToolsControllerProvider._();

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all tools groups for the current workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Sorts groups: Default first, then MCP errors, then by creation date
final class GroupedToolsControllerProvider
    extends
        $AsyncNotifierProvider<
          GroupedToolsController,
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
  GroupedToolsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupedToolsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupedToolsControllerHash();

  @$internal
  @override
  GroupedToolsController create() => GroupedToolsController();
}

String _$groupedToolsControllerHash() =>
    r'4e09948d5ab2a555659dba6431041f12bc75862b';

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider:
/// - Fetches all tools groups for the current workspace
/// - Groups tools by their workspaceToolsGroupId
/// - Creates a "Built-in Tools" virtual group for tools without a group
/// - Enriches MCP groups with their connection state
/// - Sorts groups: Default first, then MCP errors, then by creation date

abstract class _$GroupedToolsController
    extends $AsyncNotifier<List<ToolsGroupWithTools>> {
  FutureOr<List<ToolsGroupWithTools>> build();
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
    element.handleCreate(ref, build);
  }
}

/// Provider that returns the count of enabled tools across all groups.

@ProviderFor(enabledToolsCount)
final enabledToolsCountProvider = EnabledToolsCountProvider._();

/// Provider that returns the count of enabled tools across all groups.

final class EnabledToolsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider that returns the count of enabled tools across all groups.
  EnabledToolsCountProvider._()
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

String _$enabledToolsCountHash() => r'cf64c9228a6301665f23ab5b5a1afde79368765c';

/// Provider that returns the total count of tools across all groups.

@ProviderFor(totalToolsCount)
final totalToolsCountProvider = TotalToolsCountProvider._();

/// Provider that returns the total count of tools across all groups.

final class TotalToolsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider that returns the total count of tools across all groups.
  TotalToolsCountProvider._()
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

String _$totalToolsCountHash() => r'66877dd3d965d4a3475c8fbfe2cfc2a84a08b445';
