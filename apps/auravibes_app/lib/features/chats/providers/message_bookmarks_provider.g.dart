// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_bookmarks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cloudMessageBookmarks)
final cloudMessageBookmarksProvider = CloudMessageBookmarksProvider._();

final class CloudMessageBookmarksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MessageBookmarkEntity>>,
          List<MessageBookmarkEntity>,
          FutureOr<List<MessageBookmarkEntity>>
        >
    with
        $FutureModifier<List<MessageBookmarkEntity>>,
        $FutureProvider<List<MessageBookmarkEntity>> {
  CloudMessageBookmarksProvider._()
    : super(
        from: null,
        argument: null,
        retry: _doNotRetry,
        name: r'cloudMessageBookmarksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudMessageBookmarksHash();

  @$internal
  @override
  $FutureProviderElement<List<MessageBookmarkEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MessageBookmarkEntity>> create(Ref ref) {
    return cloudMessageBookmarks(ref);
  }
}

String _$cloudMessageBookmarksHash() =>
    r'2561b2faaaa6b8c3001429ebab0f15f40e457a19';

@ProviderFor(messageBookmarks)
final messageBookmarksProvider = MessageBookmarksFamily._();

final class MessageBookmarksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MessageBookmarkEntity>>,
          List<MessageBookmarkEntity>,
          Stream<List<MessageBookmarkEntity>>
        >
    with
        $FutureModifier<List<MessageBookmarkEntity>>,
        $StreamProvider<List<MessageBookmarkEntity>> {
  MessageBookmarksProvider._({
    required MessageBookmarksFamily super.from,
    required String super.argument,
  }) : super(
         retry: _doNotRetry,
         name: r'messageBookmarksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageBookmarksHash();

  @override
  String toString() {
    return r'messageBookmarksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MessageBookmarkEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MessageBookmarkEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return messageBookmarks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageBookmarksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageBookmarksHash() => r'cef43ef46ea703eb6b4e49617194394f2df67e5d';

final class MessageBookmarksFamily extends $Family
    with
        $FunctionalFamilyOverride<Stream<List<MessageBookmarkEntity>>, String> {
  MessageBookmarksFamily._()
    : super(
        retry: _doNotRetry,
        name: r'messageBookmarksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MessageBookmarksProvider call(String workspaceId) =>
      MessageBookmarksProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'messageBookmarksProvider';
}
