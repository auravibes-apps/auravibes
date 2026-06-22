import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_providers_type.freezed.dart';
part 'model_providers_type.g.dart';

enum ModelProvidersType {
  openai('openai'),
  anthropic('anthropic'),
  openrouter('openrouter');

  const ModelProvidersType(this.value);
  final String value;
}

/// Entity representing an API model provider in the Aura application.
///
/// A provider is a company or service that offers AI models,
/// such as OpenAI, Anthropic, Google, etc.
@freezed
abstract class ApiModelProviderEntity with _$ApiModelProviderEntity {
  /// Creates a new ApiModelProviderEntity instance.
  const factory ApiModelProviderEntity({
    /// Unique identifier for the provider.
    required String id,

    /// Human-readable name of the provider.
    required String name,

    required ModelProvidersType? type,

    /// API endpoint URL for the provider.
    String? url,

    /// Documentation URL for the provider.
    String? doc,
  }) = _ApiModelProviderEntity;

  factory ApiModelProviderEntity.fromJson(Map<String, dynamic> json) =>
      ApiModelProviderEntity(
        id: json['id'] as String,
        name: json['name'] as String,
        type: _getType(json),
        url: json['api'] as String?,
        doc: json['doc'] as String?,
      );
  const ApiModelProviderEntity._();

  static ModelProvidersType? _getType(Map<String, dynamic> json) {
    final npm = json['npm'] as String?;

    switch (npm) {
      case '@ai-sdk/openai':
      case '@ai-sdk/openai-compatible':
        return ModelProvidersType.openai;
      case '@ai-sdk/anthropic':
        return ModelProvidersType.anthropic;
      case '@openrouter/ai-sdk-provider':
        return ModelProvidersType.openrouter;
    }

    return null;
  }

  /// Returns true if the provider has a URL.
  bool get hasUrl => url?.isNotEmpty ?? false;

  /// Returns true if the provider has documentation.
  bool get hasDocumentation => doc?.isNotEmpty ?? false;
}
