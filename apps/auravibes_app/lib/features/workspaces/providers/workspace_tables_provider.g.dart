// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_tables_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceTableUsecase)
final workspaceTableUsecaseProvider = WorkspaceTableUsecaseFamily._();

final class WorkspaceTableUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrganizeWorkspaceTablesUsecase>,
          OrganizeWorkspaceTablesUsecase,
          FutureOr<OrganizeWorkspaceTablesUsecase>
        >
    with
        $FutureModifier<OrganizeWorkspaceTablesUsecase>,
        $FutureProvider<OrganizeWorkspaceTablesUsecase> {
  WorkspaceTableUsecaseProvider._({
    required WorkspaceTableUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceTableUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceTableUsecaseHash();

  @override
  String toString() {
    return r'workspaceTableUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OrganizeWorkspaceTablesUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OrganizeWorkspaceTablesUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceTableUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceTableUsecaseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceTableUsecaseHash() =>
    r'0effe52c07895132b271432b9382466af6094969';

final class WorkspaceTableUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<OrganizeWorkspaceTablesUsecase>,
          String
        > {
  WorkspaceTableUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceTableUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceTableUsecaseProvider call(String workspaceId) =>
      WorkspaceTableUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceTableUsecaseProvider';
}

@ProviderFor(workspaceTables)
final workspaceTablesProvider = WorkspaceTablesFamily._();

final class WorkspaceTablesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceTable>>,
          List<WorkspaceTable>,
          FutureOr<List<WorkspaceTable>>
        >
    with
        $FutureModifier<List<WorkspaceTable>>,
        $FutureProvider<List<WorkspaceTable>> {
  WorkspaceTablesProvider._({
    required WorkspaceTablesFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceTablesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceTablesHash();

  @override
  String toString() {
    return r'workspaceTablesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<WorkspaceTable>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WorkspaceTable>> create(Ref ref) {
    final argument = this.argument as (String, String?);
    return workspaceTables(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceTablesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceTablesHash() => r'65583d4a98cf5b11742eb3e575d3dacc84e556cb';

final class WorkspaceTablesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<WorkspaceTable>>,
          (String, String?)
        > {
  WorkspaceTablesFamily._()
    : super(
        retry: null,
        name: r'workspaceTablesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceTablesProvider call(String workspaceId, String? parentId) =>
      WorkspaceTablesProvider._(argument: (workspaceId, parentId), from: this);

  @override
  String toString() => r'workspaceTablesProvider';
}

@ProviderFor(workspaceTable)
final workspaceTableProvider = WorkspaceTableFamily._();

final class WorkspaceTableProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceTable>,
          WorkspaceTable,
          FutureOr<WorkspaceTable>
        >
    with $FutureModifier<WorkspaceTable>, $FutureProvider<WorkspaceTable> {
  WorkspaceTableProvider._({
    required WorkspaceTableFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceTableProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceTableHash();

  @override
  String toString() {
    return r'workspaceTableProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceTable> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceTable> create(Ref ref) {
    final argument = this.argument as (String, String);
    return workspaceTable(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceTableProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceTableHash() => r'b2610eec3aff6675172b19a8f8a05957b7784f58';

final class WorkspaceTableFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkspaceTable>, (String, String)> {
  WorkspaceTableFamily._()
    : super(
        retry: null,
        name: r'workspaceTableProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceTableProvider call(String workspaceId, String tableId) =>
      WorkspaceTableProvider._(argument: (workspaceId, tableId), from: this);

  @override
  String toString() => r'workspaceTableProvider';
}

@ProviderFor(workspaceTableRecords)
final workspaceTableRecordsProvider = WorkspaceTableRecordsFamily._();

final class WorkspaceTableRecordsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceRecord>>,
          List<WorkspaceRecord>,
          FutureOr<List<WorkspaceRecord>>
        >
    with
        $FutureModifier<List<WorkspaceRecord>>,
        $FutureProvider<List<WorkspaceRecord>> {
  WorkspaceTableRecordsProvider._({
    required WorkspaceTableRecordsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceTableRecordsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceTableRecordsHash();

  @override
  String toString() {
    return r'workspaceTableRecordsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<WorkspaceRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WorkspaceRecord>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return workspaceTableRecords(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceTableRecordsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceTableRecordsHash() =>
    r'7848277135179231e05f64f804bce73546448f27';

final class WorkspaceTableRecordsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<WorkspaceRecord>>,
          (String, String)
        > {
  WorkspaceTableRecordsFamily._()
    : super(
        retry: null,
        name: r'workspaceTableRecordsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceTableRecordsProvider call(String workspaceId, String tableId) =>
      WorkspaceTableRecordsProvider._(
        argument: (workspaceId, tableId),
        from: this,
      );

  @override
  String toString() => r'workspaceTableRecordsProvider';
}

@ProviderFor(workspaceTableAccessUsecase)
final workspaceTableAccessUsecaseProvider =
    WorkspaceTableAccessUsecaseFamily._();

final class WorkspaceTableAccessUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<ManageWorkspaceTableAccessUsecase>,
          ManageWorkspaceTableAccessUsecase,
          FutureOr<ManageWorkspaceTableAccessUsecase>
        >
    with
        $FutureModifier<ManageWorkspaceTableAccessUsecase>,
        $FutureProvider<ManageWorkspaceTableAccessUsecase> {
  WorkspaceTableAccessUsecaseProvider._({
    required WorkspaceTableAccessUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceTableAccessUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceTableAccessUsecaseHash();

  @override
  String toString() {
    return r'workspaceTableAccessUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ManageWorkspaceTableAccessUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ManageWorkspaceTableAccessUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceTableAccessUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceTableAccessUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceTableAccessUsecaseHash() =>
    r'098892fd721bddb9b45800c3618fa3a9531f8eed';

final class WorkspaceTableAccessUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ManageWorkspaceTableAccessUsecase>,
          String
        > {
  WorkspaceTableAccessUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceTableAccessUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceTableAccessUsecaseProvider call(String workspaceId) =>
      WorkspaceTableAccessUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceTableAccessUsecaseProvider';
}
