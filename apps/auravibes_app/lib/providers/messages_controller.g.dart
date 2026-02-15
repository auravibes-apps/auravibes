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
    r'7cf6f55938ef820989392d931f3d0b4332dc0962';

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
