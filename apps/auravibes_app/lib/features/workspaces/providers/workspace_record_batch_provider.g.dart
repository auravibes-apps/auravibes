// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_record_batch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceRecordBatchUsecase)
final workspaceRecordBatchUsecaseProvider =
    WorkspaceRecordBatchUsecaseFamily._();

final class WorkspaceRecordBatchUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<EditWorkspaceRecordsUsecase>,
          EditWorkspaceRecordsUsecase,
          FutureOr<EditWorkspaceRecordsUsecase>
        >
    with
        $FutureModifier<EditWorkspaceRecordsUsecase>,
        $FutureProvider<EditWorkspaceRecordsUsecase> {
  WorkspaceRecordBatchUsecaseProvider._({
    required WorkspaceRecordBatchUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceRecordBatchUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceRecordBatchUsecaseHash();

  @override
  String toString() {
    return r'workspaceRecordBatchUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<EditWorkspaceRecordsUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EditWorkspaceRecordsUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceRecordBatchUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceRecordBatchUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceRecordBatchUsecaseHash() =>
    r'366d999a576c1adc36a9a487984b821a44e8f824';

final class WorkspaceRecordBatchUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<EditWorkspaceRecordsUsecase>,
          String
        > {
  WorkspaceRecordBatchUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceRecordBatchUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceRecordBatchUsecaseProvider call(String workspaceId) =>
      WorkspaceRecordBatchUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceRecordBatchUsecaseProvider';
}
