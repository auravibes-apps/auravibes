// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NewChatController)
final newChatControllerProvider = NewChatControllerProvider._();

final class NewChatControllerProvider
    extends $NotifierProvider<NewChatController, NewChatState> {
  NewChatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newChatControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newChatControllerHash();

  @$internal
  @override
  NewChatController create() => NewChatController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewChatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewChatState>(value),
    );
  }
}

String _$newChatControllerHash() => r'638d9e126d44d02424a0c05c968b5e707dc5c896';

abstract class _$NewChatController extends $Notifier<NewChatState> {
  NewChatState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<NewChatState, NewChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NewChatState, NewChatState>,
              NewChatState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
