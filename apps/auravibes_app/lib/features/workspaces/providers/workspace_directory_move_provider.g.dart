// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_directory_move_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceDirectoryMoveUsecase)
final workspaceDirectoryMoveUsecaseProvider =
    WorkspaceDirectoryMoveUsecaseFamily._();

final class WorkspaceDirectoryMoveUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<MoveWorkspaceDirectoryItemsUsecase>,
          MoveWorkspaceDirectoryItemsUsecase,
          FutureOr<MoveWorkspaceDirectoryItemsUsecase>
        >
    with
        $FutureModifier<MoveWorkspaceDirectoryItemsUsecase>,
        $FutureProvider<MoveWorkspaceDirectoryItemsUsecase> {
  WorkspaceDirectoryMoveUsecaseProvider._({
    required WorkspaceDirectoryMoveUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceDirectoryMoveUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceDirectoryMoveUsecaseHash();

  @override
  String toString() {
    return r'workspaceDirectoryMoveUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MoveWorkspaceDirectoryItemsUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MoveWorkspaceDirectoryItemsUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceDirectoryMoveUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceDirectoryMoveUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceDirectoryMoveUsecaseHash() =>
    r'a3191806df72d731ba30749859bf7c5b111da319';

final class WorkspaceDirectoryMoveUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MoveWorkspaceDirectoryItemsUsecase>,
          String
        > {
  WorkspaceDirectoryMoveUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceDirectoryMoveUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceDirectoryMoveUsecaseProvider call(String workspaceId) =>
      WorkspaceDirectoryMoveUsecaseProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'workspaceDirectoryMoveUsecaseProvider';
}
