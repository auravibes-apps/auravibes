/// API providers ordered by product popularity.
abstract final class PopularApiProviders {
  /// Provider ids in priority order.
  static const values = [
    'openai',
    'anthropic',
    'groq',
    'xai',
    'togetherai',
    'deepseek',
  ];
}
