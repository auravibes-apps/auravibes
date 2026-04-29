// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_selection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversationSelected)
final conversationSelectedProvider = ConversationSelectedProvider._();

final class ConversationSelectedProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  ConversationSelectedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationSelectedProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$conversationSelectedHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return conversationSelected(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$conversationSelectedHash() =>
    r'a3f466f5adb9dd87edf059c218679e4bda562bd6';
