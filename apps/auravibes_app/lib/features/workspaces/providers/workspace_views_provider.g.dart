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
    r'd3a3ce5b4d05732d40b8a7af514eebd90e9e649a';

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

String _$workspaceViewsHash() => r'911f92615dc14f1fd4d86b44875f9bcf06a47273';

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
    required (String, String, {int offset}) super.argument,
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
    final argument = this.argument as (String, String, {int offset});
    return workspaceViewData(
      ref,
      argument.$1,
      argument.$2,
      offset: argument.offset,
    );
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

String _$workspaceViewDataHash() => r'b8c8e3067f3326032a0cf95873594f6ef0d58454';

final class WorkspaceViewDataFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceViewData>,
          (String, String, {int offset})
        > {
  WorkspaceViewDataFamily._()
    : super(
        retry: null,
        name: r'workspaceViewDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceViewDataProvider call(
    String workspaceId,
    String viewId, {
    int offset = 0,
  }) => WorkspaceViewDataProvider._(
    argument: (workspaceId, viewId, offset: offset),
    from: this,
  );

  @override
  String toString() => r'workspaceViewDataProvider';
}

@ProviderFor(workspaceViewChoices)
final workspaceViewChoicesProvider = WorkspaceViewChoicesFamily._();

final class WorkspaceViewChoicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceView>>,
          List<WorkspaceView>,
          FutureOr<List<WorkspaceView>>
        >
    with
        $FutureModifier<List<WorkspaceView>>,
        $FutureProvider<List<WorkspaceView>> {
  WorkspaceViewChoicesProvider._({
    required WorkspaceViewChoicesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceViewChoicesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceViewChoicesHash();

  @override
  String toString() {
    return r'workspaceViewChoicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<WorkspaceView>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WorkspaceView>> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceViewChoices(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceViewChoicesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceViewChoicesHash() =>
    r'c28bf69b68888c02246b0a1ab2c042a1c8221806';

final class WorkspaceViewChoicesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<WorkspaceView>>, String> {
  WorkspaceViewChoicesFamily._()
    : super(
        retry: null,
        name: r'workspaceViewChoicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceViewChoicesProvider call(String workspaceId) =>
      WorkspaceViewChoicesProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceViewChoicesProvider';
}

@ProviderFor(workspaceViewHistory)
final workspaceViewHistoryProvider = WorkspaceViewHistoryFamily._();

final class WorkspaceViewHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceView>>,
          List<WorkspaceView>,
          FutureOr<List<WorkspaceView>>
        >
    with
        $FutureModifier<List<WorkspaceView>>,
        $FutureProvider<List<WorkspaceView>> {
  WorkspaceViewHistoryProvider._({
    required WorkspaceViewHistoryFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceViewHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceViewHistoryHash();

  @override
  String toString() {
    return r'workspaceViewHistoryProvider'
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
    final argument = this.argument as (String, String);
    return workspaceViewHistory(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceViewHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceViewHistoryHash() =>
    r'a84865bd3910241b7571737cdd4716eb4cba8e32';

final class WorkspaceViewHistoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<WorkspaceView>>,
          (String, String)
        > {
  WorkspaceViewHistoryFamily._()
    : super(
        retry: null,
        name: r'workspaceViewHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceViewHistoryProvider call(String workspaceId, String viewId) =>
      WorkspaceViewHistoryProvider._(
        argument: (workspaceId, viewId),
        from: this,
      );

  @override
  String toString() => r'workspaceViewHistoryProvider';
}
