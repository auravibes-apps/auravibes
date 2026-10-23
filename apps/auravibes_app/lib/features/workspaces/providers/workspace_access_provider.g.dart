// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_access_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceAccess)
final workspaceAccessProvider = WorkspaceAccessFamily._();

final class WorkspaceAccessProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceAccess>,
          WorkspaceAccess,
          FutureOr<WorkspaceAccess>
        >
    with $FutureModifier<WorkspaceAccess>, $FutureProvider<WorkspaceAccess> {
  WorkspaceAccessProvider._({
    required WorkspaceAccessFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceAccessProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceAccessHash();

  @override
  String toString() {
    return r'workspaceAccessProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceAccess> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceAccess> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceAccess(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceAccessProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceAccessHash() => r'54a1cc8e11e42bff8a54132353778a7ccd8ea5de';

final class WorkspaceAccessFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkspaceAccess>, String> {
  WorkspaceAccessFamily._()
    : super(
        retry: null,
        name: r'workspaceAccessProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceAccessProvider call(String workspaceId) =>
      WorkspaceAccessProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceAccessProvider';
}

@ProviderFor(canManageWorkspace)
final canManageWorkspaceProvider = CanManageWorkspaceFamily._();

final class CanManageWorkspaceProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  CanManageWorkspaceProvider._({
    required CanManageWorkspaceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'canManageWorkspaceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canManageWorkspaceHash();

  @override
  String toString() {
    return r'canManageWorkspaceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return canManageWorkspace(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CanManageWorkspaceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canManageWorkspaceHash() =>
    r'6146c19f31115406f7e77304681f3c0b9c6b7d31';

final class CanManageWorkspaceFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  CanManageWorkspaceFamily._()
    : super(
        retry: null,
        name: r'canManageWorkspaceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CanManageWorkspaceProvider call(String workspaceId) =>
      CanManageWorkspaceProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'canManageWorkspaceProvider';
}
