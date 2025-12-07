import 'package:auravibes_app/utils/json.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_model_provider.freezed.dart';
part 'api_model_provider.g.dart';

enum ModelProvidersType {
  openai('openai'),
  anthropic('anthropic')
  ;

  const ModelProvidersType(this.value);
  final String value;
}

/// Entity representing an API model provider in the Aura application.
///
/// A provider is a company or service that offers AI models,
/// such as OpenAI, Anthropic, Google, etc.
@freezed
abstract class ApiModelProviderEntity with _$ApiModelProviderEntity {
  /// Creates a new ApiModelProviderEntity instance
  const factory ApiModelProviderEntity({
    /// Unique identifier for the provider
    required String id,

    /// Human-readable name of the provider
    required String name,

    required ModelProvidersType? type,

    /// API endpoint URL for the provider
    String? url,

    /// Documentation URL for the provider
    String? doc,
  }) = _ApiModelProviderEntity;

  factory ApiModelProviderEntity.fromJson(Map<String, dynamic> json) =>
      ApiModelProviderEntity(
        id: json.get('id'),
        name: json.get('name'),
        type: _getType(json),
        url: json.get('api'),
        doc: json.get('doc'),
      );
  const ApiModelProviderEntity._();

  static ModelProvidersType? _getType(Map<String, dynamic> json) {
    final npm = json.get<String?>('npm');

    switch (npm) {
      case '@ai-sdk/openai-compatible':
        return ModelProvidersType.openai;
      case '@ai-sdk/anthropic':
        return ModelProvidersType.anthropic;
    }
    return null;
  }

  /// Returns true if the provider has a URL
  bool get hasUrl => url != null && url!.isNotEmpty;

  /// Returns true if the provider has documentation
  bool get hasDocumentation => doc != null && doc!.isNotEmpty;
}
