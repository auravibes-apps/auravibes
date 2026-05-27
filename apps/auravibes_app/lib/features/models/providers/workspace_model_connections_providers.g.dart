// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_model_connections_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(listWorkspaceModelConnections)
final listWorkspaceModelConnectionsProvider =
    ListWorkspaceModelConnectionsFamily._();

final class ListWorkspaceModelConnectionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ModelConnectionEntity>>,
          List<ModelConnectionEntity>,
          FutureOr<List<ModelConnectionEntity>>
        >
    with
        $FutureModifier<List<ModelConnectionEntity>>,
        $FutureProvider<List<ModelConnectionEntity>> {
  ListWorkspaceModelConnectionsProvider._({
    required ListWorkspaceModelConnectionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'listWorkspaceModelConnectionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listWorkspaceModelConnectionsHash();

  @override
  String toString() {
    return r'listWorkspaceModelConnectionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ModelConnectionEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ModelConnectionEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return listWorkspaceModelConnections(ref, workspaceId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ListWorkspaceModelConnectionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listWorkspaceModelConnectionsHash() =>
    r'ab275522e286fbe960a4553eae616d7cbb92215f';

final class ListWorkspaceModelConnectionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ModelConnectionEntity>>,
          String
        > {
  ListWorkspaceModelConnectionsFamily._()
    : super(
        retry: null,
        name: r'listWorkspaceModelConnectionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ListWorkspaceModelConnectionsProvider call({required String workspaceId}) =>
      ListWorkspaceModelConnectionsProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'listWorkspaceModelConnectionsProvider';
}
