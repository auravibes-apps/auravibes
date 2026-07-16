// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_tool_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversationToolsRepository)
final conversationToolsRepositoryProvider =
    ConversationToolsRepositoryProvider._();

final class ConversationToolsRepositoryProvider
    extends
        $FunctionalProvider<
          ConversationToolsRepository,
          ConversationToolsRepository,
          ConversationToolsRepository
        >
    with $Provider<ConversationToolsRepository> {
  ConversationToolsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationToolsRepositoryProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          workspaceSessionProvider,
          workspaceToolsRepositoryProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ConversationToolsRepositoryProvider.$allTransitiveDependencies0,
          ConversationToolsRepositoryProvider.$allTransitiveDependencies1,
          ConversationToolsRepositoryProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = workspaceSessionProvider;
  static final $allTransitiveDependencies1 = workspaceToolsRepositoryProvider;
  static final $allTransitiveDependencies2 =
      WorkspaceToolsRepositoryProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$conversationToolsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ConversationToolsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConversationToolsRepository create(Ref ref) {
    return conversationToolsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConversationToolsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConversationToolsRepository>(value),
    );
  }
}

String _$conversationToolsRepositoryHash() =>
    r'0df8a9b52e950da5d1a2ac823aaa8153b9a57b0c';

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.

@ProviderFor(ConversationToolsNotifier)
final conversationToolsProvider = ConversationToolsNotifierFamily._();

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.
final class ConversationToolsNotifierProvider
    extends
        $AsyncNotifierProvider<
          ConversationToolsNotifier,
          List<ConversationToolState>
        > {
  /// Provider for managing conversation tool settings
  ///
  /// Returns a list of all workspace tools with their conversation-level states.
  ConversationToolsNotifierProvider._({
    required ConversationToolsNotifierFamily super.from,
    required ({String workspaceId, String? conversationId}) super.argument,
  }) : super(
         retry: null,
         name: r'conversationToolsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 =
      conversationToolsRepositoryProvider;
  static final $allTransitiveDependencies1 =
      ConversationToolsRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      ConversationToolsRepositoryProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      ConversationToolsRepositoryProvider.$allTransitiveDependencies2;

  @override
  String debugGetCreateSourceHash() => _$conversationToolsNotifierHash();

  @override
  String toString() {
    return r'conversationToolsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ConversationToolsNotifier create() => ConversationToolsNotifier();

  @override
  bool operator ==(Object other) {
    return other is ConversationToolsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationToolsNotifierHash() =>
    r'83b6a201c65641c9630d31918c1b6407d03755d8';

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.

final class ConversationToolsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ConversationToolsNotifier,
          AsyncValue<List<ConversationToolState>>,
          List<ConversationToolState>,
          FutureOr<List<ConversationToolState>>,
          ({String workspaceId, String? conversationId})
        > {
  ConversationToolsNotifierFamily._()
    : super(
        retry: null,
        name: r'conversationToolsProvider',
        dependencies: <ProviderOrFamily>[
          conversationToolsRepositoryProvider,
          workspaceToolsRepositoryProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ConversationToolsNotifierProvider.$allTransitiveDependencies0,
          ConversationToolsNotifierProvider.$allTransitiveDependencies1,
          ConversationToolsNotifierProvider.$allTransitiveDependencies2,
          ConversationToolsNotifierProvider.$allTransitiveDependencies3,
        },
        isAutoDispose: true,
      );

  /// Provider for managing conversation tool settings
  ///
  /// Returns a list of all workspace tools with their conversation-level states.

  ConversationToolsNotifierProvider call({
    required String workspaceId,
    String? conversationId,
  }) => ConversationToolsNotifierProvider._(
    argument: (workspaceId: workspaceId, conversationId: conversationId),
    from: this,
  );

  @override
  String toString() => r'conversationToolsProvider';
}

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.

abstract class _$ConversationToolsNotifier
    extends $AsyncNotifier<List<ConversationToolState>> {
  late final _$args =
      ref.$arg as ({String workspaceId, String? conversationId});
  String get workspaceId => _$args.workspaceId;
  String? get conversationId => _$args.conversationId;

  FutureOr<List<ConversationToolState>> build({
    required String workspaceId,
    String? conversationId,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ConversationToolState>>,
              List<ConversationToolState>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ConversationToolState>>,
                List<ConversationToolState>
              >,
              AsyncValue<List<ConversationToolState>>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        workspaceId: _$args.workspaceId,
        conversationId: _$args.conversationId,
      ),
    );
  }
}

/// Provider to get context-aware tools for chat.
/// (conversation -> workspace -> app defaults)

@ProviderFor(ContextAwareToolsNotifier)
final contextAwareToolsProvider = ContextAwareToolsNotifierFamily._();

/// Provider to get context-aware tools for chat.
/// (conversation -> workspace -> app defaults)
final class ContextAwareToolsNotifierProvider
    extends $AsyncNotifierProvider<ContextAwareToolsNotifier, List<String>> {
  /// Provider to get context-aware tools for chat.
  /// (conversation -> workspace -> app defaults)
  ContextAwareToolsNotifierProvider._({
    required ContextAwareToolsNotifierFamily super.from,
    required ({String conversationId, String workspaceId}) super.argument,
  }) : super(
         retry: null,
         name: r'contextAwareToolsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 =
      conversationToolsRepositoryProvider;
  static final $allTransitiveDependencies1 =
      ConversationToolsRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      ConversationToolsRepositoryProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      ConversationToolsRepositoryProvider.$allTransitiveDependencies2;

  @override
  String debugGetCreateSourceHash() => _$contextAwareToolsNotifierHash();

  @override
  String toString() {
    return r'contextAwareToolsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ContextAwareToolsNotifier create() => ContextAwareToolsNotifier();

  @override
  bool operator ==(Object other) {
    return other is ContextAwareToolsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contextAwareToolsNotifierHash() =>
    r'6576c875173a03eac4625ba198945b0a7cd5180c';

/// Provider to get context-aware tools for chat.
/// (conversation -> workspace -> app defaults)

final class ContextAwareToolsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ContextAwareToolsNotifier,
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>,
          ({String conversationId, String workspaceId})
        > {
  ContextAwareToolsNotifierFamily._()
    : super(
        retry: null,
        name: r'contextAwareToolsProvider',
        dependencies: <ProviderOrFamily>[conversationToolsRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ContextAwareToolsNotifierProvider.$allTransitiveDependencies0,
          ContextAwareToolsNotifierProvider.$allTransitiveDependencies1,
          ContextAwareToolsNotifierProvider.$allTransitiveDependencies2,
          ContextAwareToolsNotifierProvider.$allTransitiveDependencies3,
        },
        isAutoDispose: true,
      );

  /// Provider to get context-aware tools for chat.
  /// (conversation -> workspace -> app defaults)

  ContextAwareToolsNotifierProvider call({
    required String conversationId,
    required String workspaceId,
  }) => ContextAwareToolsNotifierProvider._(
    argument: (conversationId: conversationId, workspaceId: workspaceId),
    from: this,
  );

  @override
  String toString() => r'contextAwareToolsProvider';
}

/// Provider to get context-aware tools for chat.
/// (conversation -> workspace -> app defaults)

abstract class _$ContextAwareToolsNotifier
    extends $AsyncNotifier<List<String>> {
  late final _$args = ref.$arg as ({String conversationId, String workspaceId});
  String get conversationId => _$args.conversationId;
  String get workspaceId => _$args.workspaceId;

  FutureOr<List<String>> build({
    required String conversationId,
    required String workspaceId,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        conversationId: _$args.conversationId,
        workspaceId: _$args.workspaceId,
      ),
    );
  }
}

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)

@ProviderFor(ContextAwareToolEntitiesNotifier)
final contextAwareToolEntitiesProvider =
    ContextAwareToolEntitiesNotifierFamily._();

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)
final class ContextAwareToolEntitiesNotifierProvider
    extends
        $AsyncNotifierProvider<
          ContextAwareToolEntitiesNotifier,
          List<WorkspaceToolEntity>
        > {
  /// Provider to get context-aware tools as full entities for chat.
  ///
  /// Returns [WorkspaceToolEntity] list with table IDs needed for
  /// generating composite tool IDs.
  /// (conversation -> workspace -> app defaults)
  ContextAwareToolEntitiesNotifierProvider._({
    required ContextAwareToolEntitiesNotifierFamily super.from,
    required ({String conversationId, String workspaceId}) super.argument,
  }) : super(
         retry: null,
         name: r'contextAwareToolEntitiesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 =
      conversationToolsRepositoryProvider;
  static final $allTransitiveDependencies1 =
      ConversationToolsRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      ConversationToolsRepositoryProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      ConversationToolsRepositoryProvider.$allTransitiveDependencies2;

  @override
  String debugGetCreateSourceHash() => _$contextAwareToolEntitiesNotifierHash();

  @override
  String toString() {
    return r'contextAwareToolEntitiesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ContextAwareToolEntitiesNotifier create() =>
      ContextAwareToolEntitiesNotifier();

  @override
  bool operator ==(Object other) {
    return other is ContextAwareToolEntitiesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contextAwareToolEntitiesNotifierHash() =>
    r'ca18c0cca72abc385e168be50f041589c8f6a769';

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)

final class ContextAwareToolEntitiesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ContextAwareToolEntitiesNotifier,
          AsyncValue<List<WorkspaceToolEntity>>,
          List<WorkspaceToolEntity>,
          FutureOr<List<WorkspaceToolEntity>>,
          ({String conversationId, String workspaceId})
        > {
  ContextAwareToolEntitiesNotifierFamily._()
    : super(
        retry: null,
        name: r'contextAwareToolEntitiesProvider',
        dependencies: <ProviderOrFamily>[conversationToolsRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ContextAwareToolEntitiesNotifierProvider.$allTransitiveDependencies0,
          ContextAwareToolEntitiesNotifierProvider.$allTransitiveDependencies1,
          ContextAwareToolEntitiesNotifierProvider.$allTransitiveDependencies2,
          ContextAwareToolEntitiesNotifierProvider.$allTransitiveDependencies3,
        },
        isAutoDispose: true,
      );

  /// Provider to get context-aware tools as full entities for chat.
  ///
  /// Returns [WorkspaceToolEntity] list with table IDs needed for
  /// generating composite tool IDs.
  /// (conversation -> workspace -> app defaults)

  ContextAwareToolEntitiesNotifierProvider call({
    required String conversationId,
    required String workspaceId,
  }) => ContextAwareToolEntitiesNotifierProvider._(
    argument: (conversationId: conversationId, workspaceId: workspaceId),
    from: this,
  );

  @override
  String toString() => r'contextAwareToolEntitiesProvider';
}

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)

abstract class _$ContextAwareToolEntitiesNotifier
    extends $AsyncNotifier<List<WorkspaceToolEntity>> {
  late final _$args = ref.$arg as ({String conversationId, String workspaceId});
  String get conversationId => _$args.conversationId;
  String get workspaceId => _$args.workspaceId;

  FutureOr<List<WorkspaceToolEntity>> build({
    required String conversationId,
    required String workspaceId,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<WorkspaceToolEntity>>,
              List<WorkspaceToolEntity>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<WorkspaceToolEntity>>,
                List<WorkspaceToolEntity>
              >,
              AsyncValue<List<WorkspaceToolEntity>>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        conversationId: _$args.conversationId,
        workspaceId: _$args.workspaceId,
      ),
    );
  }
}
