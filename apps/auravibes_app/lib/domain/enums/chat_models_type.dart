/// Enum representing the type of chat model.
enum CredentialsModelType {
  openai('openai'),
  anthropic('anthropic'),
  google('google');

  /// Creates a new CredentialsModelType with the given string value
  const CredentialsModelType(this.value);

  /// Creates a CredentialsModelType from a string value
  ///
  /// Throws [ArgumentError] if the value is not a valid chat model type
  factory CredentialsModelType.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'openai':
        return CredentialsModelType.openai;
      case 'anthropic':
        return CredentialsModelType.anthropic;
      case 'google':
        return CredentialsModelType.google;
      default:
        throw ArgumentError('Invalid chat model type: $value');
    }
  }
  final String value;

  @override
  String toString() => value;
}
