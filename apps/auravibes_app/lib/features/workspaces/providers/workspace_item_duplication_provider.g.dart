// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_item_duplication_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceItemDuplicationUsecase)
final workspaceItemDuplicationUsecaseProvider =
    WorkspaceItemDuplicationUsecaseFamily._();

final class WorkspaceItemDuplicationUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<DuplicateWorkspaceItemUsecase>,
          DuplicateWorkspaceItemUsecase,
          FutureOr<DuplicateWorkspaceItemUsecase>
        >
    with
        $FutureModifier<DuplicateWorkspaceItemUsecase>,
        $FutureProvider<DuplicateWorkspaceItemUsecase> {
  WorkspaceItemDuplicationUsecaseProvider._({
    required WorkspaceItemDuplicationUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceItemDuplicationUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceItemDuplicationUsecaseHash();

  @override
  String toString() {
    return r'workspaceItemDuplicationUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DuplicateWorkspaceItemUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DuplicateWorkspaceItemUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceItemDuplicationUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceItemDuplicationUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceItemDuplicationUsecaseHash() =>
    r'2edf6b0e27b60948b146ba9feda76103f405c0f8';

final class WorkspaceItemDuplicationUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<DuplicateWorkspaceItemUsecase>,
          String
        > {
  WorkspaceItemDuplicationUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceItemDuplicationUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceItemDuplicationUsecaseProvider call(String workspaceId) =>
      WorkspaceItemDuplicationUsecaseProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'workspaceItemDuplicationUsecaseProvider';
}
