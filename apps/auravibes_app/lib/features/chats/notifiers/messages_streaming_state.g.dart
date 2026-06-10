// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_streaming_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MessagesStreamingNotifier)
final messagesStreamingProvider = MessagesStreamingNotifierProvider._();

final class MessagesStreamingNotifierProvider
    extends
        $NotifierProvider<
          MessagesStreamingNotifier,
          Map<String, MessagesStreamingState>
        > {
  MessagesStreamingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagesStreamingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagesStreamingNotifierHash();

  @$internal
  @override
  MessagesStreamingNotifier create() => MessagesStreamingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, MessagesStreamingState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, MessagesStreamingState>>(
        value,
      ),
    );
  }
}

String _$messagesStreamingNotifierHash() =>
    r'd009190e085d950dac5caead17e88bfa30fee281';

abstract class _$MessagesStreamingNotifier
    extends $Notifier<Map<String, MessagesStreamingState>> {
  Map<String, MessagesStreamingState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, MessagesStreamingState>,
              Map<String, MessagesStreamingState>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, MessagesStreamingState>,
                Map<String, MessagesStreamingState>
              >,
              Map<String, MessagesStreamingState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
