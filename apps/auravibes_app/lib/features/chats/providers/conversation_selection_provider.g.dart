// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_selection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversationSelected)
final conversationSelectedProvider = ConversationSelectedFamily._();

final class ConversationSelectedProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  ConversationSelectedProvider._({
    required ConversationSelectedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationSelectedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationSelectedHash();

  @override
  String toString() {
    return r'conversationSelectedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    final argument = this.argument as String;
    return conversationSelected(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationSelectedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationSelectedHash() =>
    r'd308c96d1b65b44fc17236a493e3341e85854877';

final class ConversationSelectedFamily extends $Family
    with $FunctionalFamilyOverride<String, String> {
  ConversationSelectedFamily._()
    : super(
        retry: null,
        name: r'conversationSelectedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationSelectedProvider call(String conversationId) =>
      ConversationSelectedProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'conversationSelectedProvider';
}
