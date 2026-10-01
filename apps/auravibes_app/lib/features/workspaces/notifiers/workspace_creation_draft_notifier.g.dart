// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_creation_draft_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorkspaceCreationDraftNotifier)
final workspaceCreationDraftProvider = WorkspaceCreationDraftNotifierFamily._();

final class WorkspaceCreationDraftNotifierProvider
    extends
        $NotifierProvider<
          WorkspaceCreationDraftNotifier,
          WorkspaceCreationDraft
        > {
  WorkspaceCreationDraftNotifierProvider._({
    required WorkspaceCreationDraftNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceCreationDraftProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceCreationDraftNotifierHash();

  @override
  String toString() {
    return r'workspaceCreationDraftProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WorkspaceCreationDraftNotifier create() => WorkspaceCreationDraftNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceCreationDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceCreationDraft>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceCreationDraftNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceCreationDraftNotifierHash() =>
    r'4f1de3ec74f13191f0416ea6dcfb3322733b191c';

final class WorkspaceCreationDraftNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          WorkspaceCreationDraftNotifier,
          WorkspaceCreationDraft,
          WorkspaceCreationDraft,
          WorkspaceCreationDraft,
          String
        > {
  WorkspaceCreationDraftNotifierFamily._()
    : super(
        retry: null,
        name: r'workspaceCreationDraftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceCreationDraftNotifierProvider call(String taskId) =>
      WorkspaceCreationDraftNotifierProvider._(argument: taskId, from: this);

  @override
  String toString() => r'workspaceCreationDraftProvider';
}

abstract class _$WorkspaceCreationDraftNotifier
    extends $Notifier<WorkspaceCreationDraft> {
  late final _$args = ref.$arg as String;
  String get taskId => _$args;

  WorkspaceCreationDraft build(String taskId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<WorkspaceCreationDraft, WorkspaceCreationDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkspaceCreationDraft, WorkspaceCreationDraft>,
              WorkspaceCreationDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
