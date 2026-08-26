// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grouped_tools_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the tools groups repository.

@ProviderFor(toolsGroupsRepository)
final toolsGroupsRepositoryProvider = ToolsGroupsRepositoryFamily._();

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
  ToolsGroupsRepositoryProvider._({
    required ToolsGroupsRepositoryFamily super.from,
    required WorkspaceSession super.argument,
  }) : super(
         retry: null,
         name: r'toolsGroupsRepositoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$toolsGroupsRepositoryHash();

  @override
  String toString() {
    return r'toolsGroupsRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ToolsGroupsRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ToolsGroupsRepositoryContract create(Ref ref) {
    final argument = this.argument as WorkspaceSession;
    return toolsGroupsRepository(ref, argument);
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

  @override
  bool operator ==(Object other) {
    return other is ToolsGroupsRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$toolsGroupsRepositoryHash() =>
    r'4d0d5e678317838b6c32e9b6b03c228188e3f4c2';

/// Provider for the tools groups repository.

final class ToolsGroupsRepositoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          ToolsGroupsRepositoryContract,
          WorkspaceSession
        > {
  ToolsGroupsRepositoryFamily._()
    : super(
        retry: null,
        name: r'toolsGroupsRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for the tools groups repository.

  ToolsGroupsRepositoryProvider call(WorkspaceSession session) =>
      ToolsGroupsRepositoryProvider._(argument: session, from: this);

  @override
  String toString() => r'toolsGroupsRepositoryProvider';
}

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider fetches tool groups for the current workspace, groups tools
/// by workspaceToolsGroupId, creates a Built-in Tools group for ungrouped
/// tools, enriches MCP groups with connection state, and sorts default, error,
/// and newest groups first.

@ProviderFor(GroupedToolsNotifier)
final groupedToolsProvider = GroupedToolsNotifierFamily._();

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider fetches tool groups for the current workspace, groups tools
/// by workspaceToolsGroupId, creates a Built-in Tools group for ungrouped
/// tools, enriches MCP groups with connection state, and sorts default, error,
/// and newest groups first.
final class GroupedToolsNotifierProvider
    extends
        $AsyncNotifierProvider<
          GroupedToolsNotifier,
          List<ToolsGroupWithTools>
        > {
  /// Provider that groups tools by their workspaceToolsGroupId.
  ///
  /// This provider fetches tool groups for the current workspace, groups tools
  /// by workspaceToolsGroupId, creates a Built-in Tools group for ungrouped
  /// tools, enriches MCP groups with connection state, and sorts default, error,
  /// and newest groups first.
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
    r'55ad6848629ebad1b2f79cf165ec50d552cc5b77';

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider fetches tool groups for the current workspace, groups tools
/// by workspaceToolsGroupId, creates a Built-in Tools group for ungrouped
/// tools, enriches MCP groups with connection state, and sorts default, error,
/// and newest groups first.

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
  /// This provider fetches tool groups for the current workspace, groups tools
  /// by workspaceToolsGroupId, creates a Built-in Tools group for ungrouped
  /// tools, enriches MCP groups with connection state, and sorts default, error,
  /// and newest groups first.

  GroupedToolsNotifierProvider call(String workspaceId) =>
      GroupedToolsNotifierProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'groupedToolsProvider';
}

/// Provider that groups tools by their workspaceToolsGroupId.
///
/// This provider fetches tool groups for the current workspace, groups tools
/// by workspaceToolsGroupId, creates a Built-in Tools group for ungrouped
/// tools, enriches MCP groups with connection state, and sorts default, error,
/// and newest groups first.

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
