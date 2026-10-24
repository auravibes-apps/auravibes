// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_references_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceReferencesUsecase)
final workspaceReferencesUsecaseProvider = WorkspaceReferencesUsecaseFamily._();

final class WorkspaceReferencesUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<BrowseWorkspaceReferencesUsecase>,
          BrowseWorkspaceReferencesUsecase,
          FutureOr<BrowseWorkspaceReferencesUsecase>
        >
    with
        $FutureModifier<BrowseWorkspaceReferencesUsecase>,
        $FutureProvider<BrowseWorkspaceReferencesUsecase> {
  WorkspaceReferencesUsecaseProvider._({
    required WorkspaceReferencesUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceReferencesUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceReferencesUsecaseHash();

  @override
  String toString() {
    return r'workspaceReferencesUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<BrowseWorkspaceReferencesUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BrowseWorkspaceReferencesUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceReferencesUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceReferencesUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceReferencesUsecaseHash() =>
    r'b451ace99bd11cf164e428db2b01004afb2f2b7f';

final class WorkspaceReferencesUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<BrowseWorkspaceReferencesUsecase>,
          String
        > {
  WorkspaceReferencesUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceReferencesUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceReferencesUsecaseProvider call(String workspaceId) =>
      WorkspaceReferencesUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceReferencesUsecaseProvider';
}

@ProviderFor(workspaceReferencedRecord)
final workspaceReferencedRecordProvider = WorkspaceReferencedRecordFamily._();

final class WorkspaceReferencedRecordProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceRecord>,
          WorkspaceRecord,
          FutureOr<WorkspaceRecord>
        >
    with $FutureModifier<WorkspaceRecord>, $FutureProvider<WorkspaceRecord> {
  WorkspaceReferencedRecordProvider._({
    required WorkspaceReferencedRecordFamily super.from,
    required (String, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceReferencedRecordProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceReferencedRecordHash();

  @override
  String toString() {
    return r'workspaceReferencedRecordProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceRecord> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceRecord> create(Ref ref) {
    final argument = this.argument as (String, String, String);
    return workspaceReferencedRecord(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceReferencedRecordProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceReferencedRecordHash() =>
    r'a0d4507611726c4ee83f4673ec0000fc55a3e06e';

final class WorkspaceReferencedRecordFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceRecord>,
          (String, String, String)
        > {
  WorkspaceReferencedRecordFamily._()
    : super(
        retry: null,
        name: r'workspaceReferencedRecordProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceReferencedRecordProvider call(
    String workspaceId,
    String tableId,
    String id,
  ) => WorkspaceReferencedRecordProvider._(
    argument: (workspaceId, tableId, id),
    from: this,
  );

  @override
  String toString() => r'workspaceReferencedRecordProvider';
}
