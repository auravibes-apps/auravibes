// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_directory_workflows_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceDirectoryWorkflows)
final workspaceDirectoryWorkflowsProvider =
    WorkspaceDirectoryWorkflowsFamily._();

final class WorkspaceDirectoryWorkflowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceWorkflow>>,
          List<WorkspaceWorkflow>,
          Stream<List<WorkspaceWorkflow>>
        >
    with
        $FutureModifier<List<WorkspaceWorkflow>>,
        $StreamProvider<List<WorkspaceWorkflow>> {
  WorkspaceDirectoryWorkflowsProvider._({
    required WorkspaceDirectoryWorkflowsFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceDirectoryWorkflowsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceDirectoryWorkflowsHash();

  @override
  String toString() {
    return r'workspaceDirectoryWorkflowsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<WorkspaceWorkflow>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WorkspaceWorkflow>> create(Ref ref) {
    final argument = this.argument as (String, String?);
    return workspaceDirectoryWorkflows(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceDirectoryWorkflowsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceDirectoryWorkflowsHash() =>
    r'ca00c8b115b68e66e8fcc98c6546ee6f17e91606';

final class WorkspaceDirectoryWorkflowsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<WorkspaceWorkflow>>,
          (String, String?)
        > {
  WorkspaceDirectoryWorkflowsFamily._()
    : super(
        retry: null,
        name: r'workspaceDirectoryWorkflowsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceDirectoryWorkflowsProvider call(
    String workspaceId,
    String? parentId,
  ) => WorkspaceDirectoryWorkflowsProvider._(
    argument: (workspaceId, parentId),
    from: this,
  );

  @override
  String toString() => r'workspaceDirectoryWorkflowsProvider';
}
