// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_folders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceFolderUsecase)
final workspaceFolderUsecaseProvider = WorkspaceFolderUsecaseFamily._();

final class WorkspaceFolderUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrganizeWorkspaceFoldersUsecase>,
          OrganizeWorkspaceFoldersUsecase,
          FutureOr<OrganizeWorkspaceFoldersUsecase>
        >
    with
        $FutureModifier<OrganizeWorkspaceFoldersUsecase>,
        $FutureProvider<OrganizeWorkspaceFoldersUsecase> {
  WorkspaceFolderUsecaseProvider._({
    required WorkspaceFolderUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceFolderUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceFolderUsecaseHash();

  @override
  String toString() {
    return r'workspaceFolderUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OrganizeWorkspaceFoldersUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OrganizeWorkspaceFoldersUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceFolderUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceFolderUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceFolderUsecaseHash() =>
    r'7751314721dcc8dd271d902f5e3b50e4d4f9d7c7';

final class WorkspaceFolderUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<OrganizeWorkspaceFoldersUsecase>,
          String
        > {
  WorkspaceFolderUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceFolderUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceFolderUsecaseProvider call(String workspaceId) =>
      WorkspaceFolderUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceFolderUsecaseProvider';
}

@ProviderFor(workspaceFolders)
final workspaceFoldersProvider = WorkspaceFoldersFamily._();

final class WorkspaceFoldersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceFolder>>,
          List<WorkspaceFolder>,
          FutureOr<List<WorkspaceFolder>>
        >
    with
        $FutureModifier<List<WorkspaceFolder>>,
        $FutureProvider<List<WorkspaceFolder>> {
  WorkspaceFoldersProvider._({
    required WorkspaceFoldersFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceFoldersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceFoldersHash();

  @override
  String toString() {
    return r'workspaceFoldersProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<WorkspaceFolder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WorkspaceFolder>> create(Ref ref) {
    final argument = this.argument as (String, String?);
    return workspaceFolders(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceFoldersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceFoldersHash() => r'6338c41271fb7c4ce50fe88d5c9c2fb349f620ed';

final class WorkspaceFoldersFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<WorkspaceFolder>>,
          (String, String?)
        > {
  WorkspaceFoldersFamily._()
    : super(
        retry: null,
        name: r'workspaceFoldersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceFoldersProvider call(String workspaceId, String? parentId) =>
      WorkspaceFoldersProvider._(argument: (workspaceId, parentId), from: this);

  @override
  String toString() => r'workspaceFoldersProvider';
}
