// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_editor_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorkflowEditorNotifier)
final workflowEditorProvider = WorkflowEditorNotifierFamily._();

final class WorkflowEditorNotifierProvider
    extends $NotifierProvider<WorkflowEditorNotifier, WorkflowEditorState> {
  WorkflowEditorNotifierProvider._({
    required WorkflowEditorNotifierFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'workflowEditorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workflowEditorNotifierHash();

  @override
  String toString() {
    return r'workflowEditorProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  WorkflowEditorNotifier create() => WorkflowEditorNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkflowEditorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkflowEditorState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkflowEditorNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workflowEditorNotifierHash() =>
    r'c175cba770f5ab208b1afe498c0d9a378813ec90';

final class WorkflowEditorNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          WorkflowEditorNotifier,
          WorkflowEditorState,
          WorkflowEditorState,
          WorkflowEditorState,
          (String, String?)
        > {
  WorkflowEditorNotifierFamily._()
    : super(
        retry: null,
        name: r'workflowEditorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkflowEditorNotifierProvider call(String workspaceId, String? workflowId) =>
      WorkflowEditorNotifierProvider._(
        argument: (workspaceId, workflowId),
        from: this,
      );

  @override
  String toString() => r'workflowEditorProvider';
}

abstract class _$WorkflowEditorNotifier extends $Notifier<WorkflowEditorState> {
  late final _$args = ref.$arg as (String, String?);
  String get workspaceId => _$args.$1;
  String? get workflowId => _$args.$2;

  WorkflowEditorState build(String workspaceId, String? workflowId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WorkflowEditorState, WorkflowEditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkflowEditorState, WorkflowEditorState>,
              WorkflowEditorState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
