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
    r'3993c20cd3ad498267aecc6701b20c256d90ef80';

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
