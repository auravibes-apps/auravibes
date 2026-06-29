// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chatbot_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider that creates a ChatbotService without tools.
/// (for title generation, etc.)

@ProviderFor(chatbotService)
final chatbotServiceProvider = ChatbotServiceProvider._();

/// Provider that creates a ChatbotService without tools.
/// (for title generation, etc.)

final class ChatbotServiceProvider
    extends $FunctionalProvider<ChatbotService, ChatbotService, ChatbotService>
    with $Provider<ChatbotService> {
  /// Provider that creates a ChatbotService without tools.
  /// (for title generation, etc.)
  ChatbotServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatbotServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatbotServiceHash();

  @$internal
  @override
  $ProviderElement<ChatbotService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatbotService create(Ref ref) {
    return chatbotService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatbotService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatbotService>(value),
    );
  }
}

String _$chatbotServiceHash() => r'f7a70c0dc8e6dc72b04893f2066c028aa77a3521';
