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
    r'd942ee6b8eef41dd32f7a4554e2c6874181ca193';

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
