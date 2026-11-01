// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_connector_tool_sample_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workflowConnectorToolSampleUsecase)
final workflowConnectorToolSampleUsecaseProvider =
    WorkflowConnectorToolSampleUsecaseFamily._();

final class WorkflowConnectorToolSampleUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkflowConnectorToolSampleUsecase>,
          WorkflowConnectorToolSampleUsecase,
          FutureOr<WorkflowConnectorToolSampleUsecase>
        >
    with
        $FutureModifier<WorkflowConnectorToolSampleUsecase>,
        $FutureProvider<WorkflowConnectorToolSampleUsecase> {
  WorkflowConnectorToolSampleUsecaseProvider._({
    required WorkflowConnectorToolSampleUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workflowConnectorToolSampleUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$workflowConnectorToolSampleUsecaseHash();

  @override
  String toString() {
    return r'workflowConnectorToolSampleUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkflowConnectorToolSampleUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkflowConnectorToolSampleUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workflowConnectorToolSampleUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkflowConnectorToolSampleUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workflowConnectorToolSampleUsecaseHash() =>
    r'a73d494c55093e2ab46534778cfc9a9a32ca0e6b';

final class WorkflowConnectorToolSampleUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkflowConnectorToolSampleUsecase>,
          String
        > {
  WorkflowConnectorToolSampleUsecaseFamily._()
    : super(
        retry: null,
        name: r'workflowConnectorToolSampleUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkflowConnectorToolSampleUsecaseProvider call(String workspaceId) =>
      WorkflowConnectorToolSampleUsecaseProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'workflowConnectorToolSampleUsecaseProvider';
}
