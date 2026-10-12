// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_archive_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversationArchiveIncompleteContext)
final conversationArchiveIncompleteContextProvider =
    ConversationArchiveIncompleteContextFamily._();

final class ConversationArchiveIncompleteContextProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  ConversationArchiveIncompleteContextProvider._({
    required ConversationArchiveIncompleteContextFamily super.from,
    required ConversationArchiveIncompleteContextKey super.argument,
  }) : super(
         retry: null,
         name: r'conversationArchiveIncompleteContextProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$conversationArchiveIncompleteContextHash();

  @override
  String toString() {
    return r'conversationArchiveIncompleteContextProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as ConversationArchiveIncompleteContextKey;
    return conversationArchiveIncompleteContext(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationArchiveIncompleteContextProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationArchiveIncompleteContextHash() =>
    r'6bd12d870daece78f6575c9ade23896a1595d96f';

final class ConversationArchiveIncompleteContextFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<bool>,
          ConversationArchiveIncompleteContextKey
        > {
  ConversationArchiveIncompleteContextFamily._()
    : super(
        retry: null,
        name: r'conversationArchiveIncompleteContextProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationArchiveIncompleteContextProvider call(
    ConversationArchiveIncompleteContextKey key,
  ) =>
      ConversationArchiveIncompleteContextProvider._(argument: key, from: this);

  @override
  String toString() => r'conversationArchiveIncompleteContextProvider';
}
