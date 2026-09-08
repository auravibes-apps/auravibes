// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_deletion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversationDeletion)
final conversationDeletionProvider = ConversationDeletionFamily._();

final class ConversationDeletionProvider
    extends
        $FunctionalProvider<
          AsyncValue<DeleteConversation>,
          DeleteConversation,
          FutureOr<DeleteConversation>
        >
    with
        $FutureModifier<DeleteConversation>,
        $FutureProvider<DeleteConversation> {
  ConversationDeletionProvider._({
    required ConversationDeletionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationDeletionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationDeletionHash();

  @override
  String toString() {
    return r'conversationDeletionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DeleteConversation> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DeleteConversation> create(Ref ref) {
    final argument = this.argument as String;
    return conversationDeletion(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationDeletionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationDeletionHash() =>
    r'02175b734745fde4a28eb4ee75ee341c6a1b2237';

final class ConversationDeletionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DeleteConversation>, String> {
  ConversationDeletionFamily._()
    : super(
        retry: null,
        name: r'conversationDeletionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationDeletionProvider call(String workspaceId) =>
      ConversationDeletionProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'conversationDeletionProvider';
}
