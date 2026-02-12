// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_execution_controller.dart';

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

@ProviderFor(ToolExecutionController)
final toolExecutionControllerProvider = ToolExecutionControllerProvider._();

final class ToolExecutionControllerProvider
    extends $NotifierProvider<ToolExecutionController, List<TrackedToolCall>> {
  ToolExecutionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toolExecutionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toolExecutionControllerHash();

  @$internal
  @override
  ToolExecutionController create() => ToolExecutionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TrackedToolCall> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TrackedToolCall>>(value),
    );
  }
}

String _$toolExecutionControllerHash() =>
    r'df5df6065ce873e6fe93d22b4b47fe3f049e9f1c';

abstract class _$ToolExecutionController
    extends $Notifier<List<TrackedToolCall>> {
  List<TrackedToolCall> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<TrackedToolCall>, List<TrackedToolCall>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<TrackedToolCall>, List<TrackedToolCall>>,
              List<TrackedToolCall>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
