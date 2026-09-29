sealed class const AgentTranscriptContextDecodeException()
    implements Exception {
  String get diagnostic;

  @override
  String toString() => 'Transcript context decode failed: $diagnostic';
}

final class const UnsupportedTranscriptVersionException(final int version)
    extends AgentTranscriptContextDecodeException {
  @override
  String get diagnostic => 'unsupported schema version $version';
}

final class const MalformedTranscriptContextException()
    extends AgentTranscriptContextDecodeException {
  @override
  String get diagnostic => 'malformed stored update';
}
