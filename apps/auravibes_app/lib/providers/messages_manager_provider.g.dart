// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_manager_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MessagesManagerNotifier)
const messagesManagerProvider = MessagesManagerNotifierProvider._();

final class MessagesManagerNotifierProvider
    extends $NotifierProvider<MessagesManagerNotifier, List<StreamingMessage>> {
  const MessagesManagerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagesManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagesManagerNotifierHash();

  @$internal
  @override
  MessagesManagerNotifier create() => MessagesManagerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<StreamingMessage> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<StreamingMessage>>(value),
    );
  }
}

String _$messagesManagerNotifierHash() =>
    r'4ec534ecd0a2b8c3832c69ec25913b113e67540c';

abstract class _$MessagesManagerNotifier
    extends $Notifier<List<StreamingMessage>> {
  List<StreamingMessage> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
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
    element.handleValue(ref, created);
  }
}
