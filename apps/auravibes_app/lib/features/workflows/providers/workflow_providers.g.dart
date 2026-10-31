// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workflowRepository)
final workflowRepositoryProvider = WorkflowRepositoryFamily._();

final class WorkflowRepositoryProvider
    extends
        $FunctionalProvider<
          WorkflowRepository,
          WorkflowRepository,
          WorkflowRepository
        >
    with $Provider<WorkflowRepository> {
  WorkflowRepositoryProvider._({
    required WorkflowRepositoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workflowRepositoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workflowRepositoryHash();

  @override
  String toString() {
    return r'workflowRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<WorkflowRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkflowRepository create(Ref ref) {
    final argument = this.argument as String;
    return workflowRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkflowRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkflowRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkflowRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workflowRepositoryHash() =>
    r'7ef088bc519c076e7550e0636a15e6147c75658b';

final class WorkflowRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<WorkflowRepository, String> {
  WorkflowRepositoryFamily._()
    : super(
        retry: null,
        name: r'workflowRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkflowRepositoryProvider call(String workspaceId) =>
      WorkflowRepositoryProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workflowRepositoryProvider';
}

@ProviderFor(workflows)
final workflowsProvider = WorkflowsFamily._();

final class WorkflowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceWorkflow>>,
          List<WorkspaceWorkflow>,
          Stream<List<WorkspaceWorkflow>>
        >
    with
        $FutureModifier<List<WorkspaceWorkflow>>,
        $StreamProvider<List<WorkspaceWorkflow>> {
  WorkflowsProvider._({
    required WorkflowsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workflowsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workflowsHash();

  @override
  String toString() {
    return r'workflowsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<WorkspaceWorkflow>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WorkspaceWorkflow>> create(Ref ref) {
    final argument = this.argument as String;
    return workflows(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkflowsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workflowsHash() => r'85ba30f07a721f424872d32c2c7bb5f629adf25a';

final class WorkflowsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<WorkspaceWorkflow>>, String> {
  WorkflowsFamily._()
    : super(
        retry: null,
        name: r'workflowsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkflowsProvider call(String workspaceId) =>
      WorkflowsProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workflowsProvider';
}

@ProviderFor(workflow)
final workflowProvider = WorkflowFamily._();

final class WorkflowProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceWorkflow?>,
          WorkspaceWorkflow?,
          FutureOr<WorkspaceWorkflow?>
        >
    with
        $FutureModifier<WorkspaceWorkflow?>,
        $FutureProvider<WorkspaceWorkflow?> {
  WorkflowProvider._({
    required WorkflowFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workflowProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workflowHash();

  @override
  String toString() {
    return r'workflowProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceWorkflow?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceWorkflow?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return workflow(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkflowProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workflowHash() => r'10be5f6fa9d72e3d59449aa7f5222b5794102448';

final class WorkflowFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceWorkflow?>,
          (String, String)
        > {
  WorkflowFamily._()
    : super(
        retry: null,
        name: r'workflowProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkflowProvider call(String workspaceId, String workflowId) =>
      WorkflowProvider._(argument: (workspaceId, workflowId), from: this);

  @override
  String toString() => r'workflowProvider';
}

@ProviderFor(saveWorkflowUsecase)
final saveWorkflowUsecaseProvider = SaveWorkflowUsecaseFamily._();

final class SaveWorkflowUsecaseProvider
    extends
        $FunctionalProvider<
          SaveWorkflowUsecase,
          SaveWorkflowUsecase,
          SaveWorkflowUsecase
        >
    with $Provider<SaveWorkflowUsecase> {
  SaveWorkflowUsecaseProvider._({
    required SaveWorkflowUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'saveWorkflowUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$saveWorkflowUsecaseHash();

  @override
  String toString() {
    return r'saveWorkflowUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<SaveWorkflowUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveWorkflowUsecase create(Ref ref) {
    final argument = this.argument as String;
    return saveWorkflowUsecase(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveWorkflowUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveWorkflowUsecase>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SaveWorkflowUsecaseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$saveWorkflowUsecaseHash() =>
    r'838b1f1633e1a0e0c761fa70088f937dda369d8a';

final class SaveWorkflowUsecaseFamily extends $Family
    with $FunctionalFamilyOverride<SaveWorkflowUsecase, String> {
  SaveWorkflowUsecaseFamily._()
    : super(
        retry: null,
        name: r'saveWorkflowUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SaveWorkflowUsecaseProvider call(String workspaceId) =>
      SaveWorkflowUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'saveWorkflowUsecaseProvider';
}
