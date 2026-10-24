// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_open_view_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorkspaceOpenViewNotifier)
final workspaceOpenViewProvider = WorkspaceOpenViewNotifierFamily._();

final class WorkspaceOpenViewNotifierProvider
    extends $NotifierProvider<WorkspaceOpenViewNotifier, WorkspaceChatItem?> {
  WorkspaceOpenViewNotifierProvider._({
    required WorkspaceOpenViewNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceOpenViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceOpenViewNotifierHash();

  @override
  String toString() {
    return r'workspaceOpenViewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  WorkspaceOpenViewNotifier create() => WorkspaceOpenViewNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceChatItem? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceChatItem?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceOpenViewNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceOpenViewNotifierHash() =>
    r'897f50591dd8413ceb88376058038f9b7469b89c';

final class WorkspaceOpenViewNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          WorkspaceOpenViewNotifier,
          WorkspaceChatItem?,
          WorkspaceChatItem?,
          WorkspaceChatItem?,
          (String, String)
        > {
  WorkspaceOpenViewNotifierFamily._()
    : super(
        retry: null,
        name: r'workspaceOpenViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceOpenViewNotifierProvider call(
    String workspaceId,
    String conversationId,
  ) => WorkspaceOpenViewNotifierProvider._(
    argument: (workspaceId, conversationId),
    from: this,
  );

  @override
  String toString() => r'workspaceOpenViewProvider';
}

abstract class _$WorkspaceOpenViewNotifier
    extends $Notifier<WorkspaceChatItem?> {
  late final _$args = ref.$arg as (String, String);
  String get workspaceId => _$args.$1;
  String get conversationId => _$args.$2;

  WorkspaceChatItem? build(String workspaceId, String conversationId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WorkspaceChatItem?, WorkspaceChatItem?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkspaceChatItem?, WorkspaceChatItem?>,
              WorkspaceChatItem?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
