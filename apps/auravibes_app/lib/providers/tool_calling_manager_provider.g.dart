// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_calling_manager_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$ToolResponseItemToJson(_ToolResponseItem instance) =>
    <String, dynamic>{'id': instance.id, 'content': instance.content};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A trigger that increments whenever tool call results are updated.
///
/// UI components can watch this to know when to refresh message data
/// after tool calls are resolved (stopped, skipped, or completed).

@ProviderFor(ToolUpdateRefreshTrigger)
const toolUpdateRefreshTriggerProvider = ToolUpdateRefreshTriggerProvider._();

/// A trigger that increments whenever tool call results are updated.
///
/// UI components can watch this to know when to refresh message data
/// after tool calls are resolved (stopped, skipped, or completed).
final class ToolUpdateRefreshTriggerProvider
    extends $NotifierProvider<ToolUpdateRefreshTrigger, int> {
  /// A trigger that increments whenever tool call results are updated.
  ///
  /// UI components can watch this to know when to refresh message data
  /// after tool calls are resolved (stopped, skipped, or completed).
  const ToolUpdateRefreshTriggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toolUpdateRefreshTriggerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toolUpdateRefreshTriggerHash();

  @$internal
  @override
  ToolUpdateRefreshTrigger create() => ToolUpdateRefreshTrigger();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$toolUpdateRefreshTriggerHash() =>
    r'b63c1f5a0dad6e6479dd962d649e67c4874d9945';

/// A trigger that increments whenever tool call results are updated.
///
/// UI components can watch this to know when to refresh message data
/// after tool calls are resolved (stopped, skipped, or completed).

abstract class _$ToolUpdateRefreshTrigger extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ToolCallingManagerNotifier)
const toolCallingManagerProvider = ToolCallingManagerNotifierProvider._();

final class ToolCallingManagerNotifierProvider
    extends
        $NotifierProvider<ToolCallingManagerNotifier, List<TrackedToolCall>> {
  const ToolCallingManagerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toolCallingManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toolCallingManagerNotifierHash();

  @$internal
  @override
  ToolCallingManagerNotifier create() => ToolCallingManagerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TrackedToolCall> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TrackedToolCall>>(value),
    );
  }
}

String _$toolCallingManagerNotifierHash() =>
    r'6a69a85bab960b1b371b6855e9c4336d0316e98a';

abstract class _$ToolCallingManagerNotifier
    extends $Notifier<List<TrackedToolCall>> {
  List<TrackedToolCall> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<TrackedToolCall>, List<TrackedToolCall>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<TrackedToolCall>, List<TrackedToolCall>>,
              List<TrackedToolCall>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
