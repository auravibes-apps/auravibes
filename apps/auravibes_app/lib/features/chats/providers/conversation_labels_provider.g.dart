// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_labels_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversationLabelsStream)
final conversationLabelsStreamProvider = ConversationLabelsStreamFamily._();

final class ConversationLabelsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ConversationLabelEntity>>,
          List<ConversationLabelEntity>,
          Stream<List<ConversationLabelEntity>>
        >
    with
        $FutureModifier<List<ConversationLabelEntity>>,
        $StreamProvider<List<ConversationLabelEntity>> {
  ConversationLabelsStreamProvider._({
    required ConversationLabelsStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationLabelsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationLabelsStreamHash();

  @override
  String toString() {
    return r'conversationLabelsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ConversationLabelEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ConversationLabelEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return conversationLabelsStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationLabelsStreamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationLabelsStreamHash() =>
    r'53e83eafa9711f770eb2d450198ef4e0ffa59b44';

final class ConversationLabelsStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<ConversationLabelEntity>>,
          String
        > {
  ConversationLabelsStreamFamily._()
    : super(
        retry: null,
        name: r'conversationLabelsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationLabelsStreamProvider call(String workspaceId) =>
      ConversationLabelsStreamProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'conversationLabelsStreamProvider';
}

@ProviderFor(conversationLabelActions)
final conversationLabelActionsProvider = ConversationLabelActionsProvider._();

final class ConversationLabelActionsProvider
    extends
        $FunctionalProvider<
          ConversationLabelActions,
          ConversationLabelActions,
          ConversationLabelActions
        >
    with $Provider<ConversationLabelActions> {
  ConversationLabelActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationLabelActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationLabelActionsHash();

  @$internal
  @override
  $ProviderElement<ConversationLabelActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConversationLabelActions create(Ref ref) {
    return conversationLabelActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConversationLabelActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConversationLabelActions>(value),
    );
  }
}

String _$conversationLabelActionsHash() =>
    r'0f19e39fc0acf2802377c20d49750537975f86f0';
