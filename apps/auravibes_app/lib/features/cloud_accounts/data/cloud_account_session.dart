class CloudAccountSession {
  const CloudAccountSession({
    required this.serverUrl,
    required this.userId,
    required this.email,
  });

  factory CloudAccountSession.fromJson(Map<String, Object?> json) {
    return CloudAccountSession(
      serverUrl: json['serverUrl']! as String,
      userId: json['userId']! as String,
      email: json['email']! as String,
    );
  }

  final String serverUrl;
  final String userId;
  final String email;

  Map<String, Object?> toJson() {
    return {'serverUrl': serverUrl, 'userId': userId, 'email': email};
  }
}
