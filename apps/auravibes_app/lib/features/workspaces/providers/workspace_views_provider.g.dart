// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_views_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceViewUsecase)
final workspaceViewUsecaseProvider = WorkspaceViewUsecaseFamily._();

final class WorkspaceViewUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<ManageWorkspaceViewsUsecase>,
          ManageWorkspaceViewsUsecase,
          FutureOr<ManageWorkspaceViewsUsecase>
        >
    with
        $FutureModifier<ManageWorkspaceViewsUsecase>,
        $FutureProvider<ManageWorkspaceViewsUsecase> {
  WorkspaceViewUsecaseProvider._({
    required WorkspaceViewUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceViewUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceViewUsecaseHash();

  @override
  String toString() {
    return r'workspaceViewUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ManageWorkspaceViewsUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ManageWorkspaceViewsUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceViewUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceViewUsecaseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceViewUsecaseHash() =>
    r'08b0fa7b15949f5c78a6af1aedf9167efd659a25';

final class WorkspaceViewUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ManageWorkspaceViewsUsecase>,
          String
        > {
  WorkspaceViewUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceViewUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceViewUsecaseProvider call(String workspaceId) =>
      WorkspaceViewUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceViewUsecaseProvider';
}

@ProviderFor(workspaceViews)
final workspaceViewsProvider = WorkspaceViewsFamily._();

final class WorkspaceViewsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceView>>,
          List<WorkspaceView>,
          FutureOr<List<WorkspaceView>>
        >
    with
        $FutureModifier<List<WorkspaceView>>,
        $FutureProvider<List<WorkspaceView>> {
  WorkspaceViewsProvider._({
    required WorkspaceViewsFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceViewsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceViewsHash();

  @override
  String toString() {
    return r'workspaceViewsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<WorkspaceView>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WorkspaceView>> create(Ref ref) {
    final argument = this.argument as (String, String?);
    return workspaceViews(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceViewsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceViewsHash() => r'aa51ccb5e9203f862d81a3b1097cd684b9fd24fa';

final class WorkspaceViewsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<WorkspaceView>>,
          (String, String?)
        > {
  WorkspaceViewsFamily._()
    : super(
        retry: null,
        name: r'workspaceViewsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceViewsProvider call(String workspaceId, String? parentId) =>
      WorkspaceViewsProvider._(argument: (workspaceId, parentId), from: this);

  @override
  String toString() => r'workspaceViewsProvider';
}

@ProviderFor(workspaceViewData)
final workspaceViewDataProvider = WorkspaceViewDataFamily._();

final class WorkspaceViewDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceViewData>,
          WorkspaceViewData,
          FutureOr<WorkspaceViewData>
        >
    with
        $FutureModifier<WorkspaceViewData>,
        $FutureProvider<WorkspaceViewData> {
  WorkspaceViewDataProvider._({
    required WorkspaceViewDataFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceViewDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceViewDataHash();

  @override
  String toString() {
    return r'workspaceViewDataProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceViewData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceViewData> create(Ref ref) {
    final argument = this.argument as (String, String);
    return workspaceViewData(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceViewDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceViewDataHash() => r'f656396a38e7207f2ece6ebad51671f2b6196ee3';

final class WorkspaceViewDataFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceViewData>,
          (String, String)
        > {
  WorkspaceViewDataFamily._()
    : super(
        retry: null,
        name: r'workspaceViewDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceViewDataProvider call(String workspaceId, String viewId) =>
      WorkspaceViewDataProvider._(argument: (workspaceId, viewId), from: this);

  @override
  String toString() => r'workspaceViewDataProvider';
}
