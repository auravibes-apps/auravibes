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
    extends $NotifierProvider<WorkspaceOpenViewNotifier, String?> {
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
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
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
    r'7a031d73dddb2248bbfcb990de9ebc2fa6b5d192';

final class WorkspaceOpenViewNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          WorkspaceOpenViewNotifier,
          String?,
          String?,
          String?,
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

abstract class _$WorkspaceOpenViewNotifier extends $Notifier<String?> {
  late final _$args = ref.$arg as (String, String);
  String get workspaceId => _$args.$1;
  String get conversationId => _$args.$2;

  String? build(String workspaceId, String conversationId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
