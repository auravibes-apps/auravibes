// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_bookmark_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(messageBookmarkUseCase)
final messageBookmarkUseCaseProvider = MessageBookmarkUseCaseProvider._();

final class MessageBookmarkUseCaseProvider
    extends
        $FunctionalProvider<
          MessageBookmarkUseCase,
          MessageBookmarkUseCase,
          MessageBookmarkUseCase
        >
    with $Provider<MessageBookmarkUseCase> {
  MessageBookmarkUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageBookmarkUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageBookmarkUseCaseHash();

  @$internal
  @override
  $ProviderElement<MessageBookmarkUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageBookmarkUseCase create(Ref ref) {
    return messageBookmarkUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageBookmarkUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageBookmarkUseCase>(value),
    );
  }
}

String _$messageBookmarkUseCaseHash() =>
    r'1dec1d993402288b4e5cae2cabc01e7f5d4ac4ea';
