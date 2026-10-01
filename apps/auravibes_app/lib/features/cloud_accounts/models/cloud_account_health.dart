class const CloudAccountHealth({
  required final CloudAccountHealthStatus status,
  final DateTime? checkedAt,
});

enum CloudAccountHealthStatus { verified, needsSignIn, unknown }
