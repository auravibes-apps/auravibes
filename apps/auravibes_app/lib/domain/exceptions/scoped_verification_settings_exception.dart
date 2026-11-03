/// A localized configuration failure that preserves the owner's draft.
class const ScopedVerificationSettingsException(final String localeKey)
    implements Exception {
  @override
  String toString() => localeKey;
}
