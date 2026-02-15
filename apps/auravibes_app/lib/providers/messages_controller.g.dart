// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MessagesController)
final messagesControllerProvider = MessagesControllerProvider._();

final class MessagesControllerProvider
    extends $NotifierProvider<MessagesController, List<StreamingMessage>> {
  MessagesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagesControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagesControllerHash();

  @$internal
  @override
  MessagesController create() => MessagesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<StreamingMessage> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<StreamingMessage>>(value),
    );
  }
}

String _$messagesControllerHash() =>
    r'b25b67b94a5cae362625a218d9615f8c7db02fbb';

abstract class _$MessagesController extends $Notifier<List<StreamingMessage>> {
  List<StreamingMessage> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<List<StreamingMessage>, List<StreamingMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<StreamingMessage>, List<StreamingMessage>>,
              List<StreamingMessage>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
