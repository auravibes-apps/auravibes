// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversationByIdStream)
final conversationByIdStreamProvider = ConversationByIdStreamFamily._();

final class ConversationByIdStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<ConversationEntity?>,
          ConversationEntity?,
          Stream<ConversationEntity?>
        >
    with
        $FutureModifier<ConversationEntity?>,
        $StreamProvider<ConversationEntity?> {
  ConversationByIdStreamProvider._({
    required ConversationByIdStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationByIdStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationByIdStreamHash();

  @override
  String toString() {
    return r'conversationByIdStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ConversationEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ConversationEntity?> create(Ref ref) {
    final argument = this.argument as String;
    return conversationByIdStream(ref, conversationId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationByIdStreamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationByIdStreamHash() =>
    r'82375b6f8df126d4eed95d6cd1787d0a27f18615';

final class ConversationByIdStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ConversationEntity?>, String> {
  ConversationByIdStreamFamily._()
    : super(
        retry: null,
        name: r'conversationByIdStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationByIdStreamProvider call({required String conversationId}) =>
      ConversationByIdStreamProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'conversationByIdStreamProvider';
}

@ProviderFor(conversationsStream)
final conversationsStreamProvider = ConversationsStreamFamily._();

final class ConversationsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ConversationEntity>>,
          List<ConversationEntity>,
          Stream<List<ConversationEntity>>
        >
    with
        $FutureModifier<List<ConversationEntity>>,
        $StreamProvider<List<ConversationEntity>> {
  ConversationsStreamProvider._({
    required ConversationsStreamFamily super.from,
    required ({String workspaceId, int? limit}) super.argument,
  }) : super(
         retry: null,
         name: r'conversationsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationsStreamHash();

  @override
  String toString() {
    return r'conversationsStreamProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<ConversationEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ConversationEntity>> create(Ref ref) {
    final argument = this.argument as ({String workspaceId, int? limit});
    return conversationsStream(
      ref,
      workspaceId: argument.workspaceId,
      limit: argument.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationsStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationsStreamHash() =>
    r'4939febced1f8eaff5c13364502380c1991e679d';

final class ConversationsStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<ConversationEntity>>,
          ({String workspaceId, int? limit})
        > {
  ConversationsStreamFamily._()
    : super(
        retry: null,
        name: r'conversationsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationsStreamProvider call({required String workspaceId, int? limit}) =>
      ConversationsStreamProvider._(
        argument: (workspaceId: workspaceId, limit: limit),
        from: this,
      );

  @override
  String toString() => r'conversationsStreamProvider';
}

@ProviderFor(streamingTitle)
final streamingTitleProvider = StreamingTitleFamily._();

final class StreamingTitleProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  StreamingTitleProvider._({
    required StreamingTitleFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'streamingTitleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$streamingTitleHash();

  @override
  String toString() {
    return r'streamingTitleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    final argument = this.argument as String;
    return streamingTitle(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StreamingTitleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$streamingTitleHash() => r'ce04017ffc0d13629630fad1aae83f4108509951';

final class StreamingTitleFamily extends $Family
    with $FunctionalFamilyOverride<String?, String> {
  StreamingTitleFamily._()
    : super(
        retry: null,
        name: r'streamingTitleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StreamingTitleProvider call(String conversationId) =>
      StreamingTitleProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'streamingTitleProvider';
}
