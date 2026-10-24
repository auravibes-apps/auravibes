// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_record_query_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceRecordQueryUsecase)
final workspaceRecordQueryUsecaseProvider =
    WorkspaceRecordQueryUsecaseFamily._();

final class WorkspaceRecordQueryUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<QueryWorkspaceRecordsUsecase>,
          QueryWorkspaceRecordsUsecase,
          FutureOr<QueryWorkspaceRecordsUsecase>
        >
    with
        $FutureModifier<QueryWorkspaceRecordsUsecase>,
        $FutureProvider<QueryWorkspaceRecordsUsecase> {
  WorkspaceRecordQueryUsecaseProvider._({
    required WorkspaceRecordQueryUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceRecordQueryUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceRecordQueryUsecaseHash();

  @override
  String toString() {
    return r'workspaceRecordQueryUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<QueryWorkspaceRecordsUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QueryWorkspaceRecordsUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceRecordQueryUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceRecordQueryUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceRecordQueryUsecaseHash() =>
    r'3f1e30c344daed2f1e5bfd16947d2dbda3977c05';

final class WorkspaceRecordQueryUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<QueryWorkspaceRecordsUsecase>,
          String
        > {
  WorkspaceRecordQueryUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceRecordQueryUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceRecordQueryUsecaseProvider call(String workspaceId) =>
      WorkspaceRecordQueryUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceRecordQueryUsecaseProvider';
}

@ProviderFor(workspaceRecordQuery)
final workspaceRecordQueryProvider = WorkspaceRecordQueryFamily._();

final class WorkspaceRecordQueryProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceRecordPage>,
          WorkspaceRecordPage,
          FutureOr<WorkspaceRecordPage>
        >
    with
        $FutureModifier<WorkspaceRecordPage>,
        $FutureProvider<WorkspaceRecordPage> {
  WorkspaceRecordQueryProvider._({
    required WorkspaceRecordQueryFamily super.from,
    required (String, String, WorkspaceRecordQuery) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceRecordQueryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceRecordQueryHash();

  @override
  String toString() {
    return r'workspaceRecordQueryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceRecordPage> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceRecordPage> create(Ref ref) {
    final argument = this.argument as (String, String, WorkspaceRecordQuery);
    return workspaceRecordQuery(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceRecordQueryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceRecordQueryHash() =>
    r'4d12b72470d5ceb0825126edeb32803f5700d2cf';

final class WorkspaceRecordQueryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceRecordPage>,
          (String, String, WorkspaceRecordQuery)
        > {
  WorkspaceRecordQueryFamily._()
    : super(
        retry: null,
        name: r'workspaceRecordQueryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceRecordQueryProvider call(
    String workspaceId,
    String tableId,
    WorkspaceRecordQuery query,
  ) => WorkspaceRecordQueryProvider._(
    argument: (workspaceId, tableId, query),
    from: this,
  );

  @override
  String toString() => r'workspaceRecordQueryProvider';
}
