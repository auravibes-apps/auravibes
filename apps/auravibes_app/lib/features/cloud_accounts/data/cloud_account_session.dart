class const CloudAccountSession({
  required final String serverUrl,
  required final String userId,
  required final String email,
}) {
  factory fromJson(Map<String, Object?> json) {
    return CloudAccountSession(
      serverUrl: json['serverUrl']! as String,
      userId: json['userId']! as String,
      email: json['email']! as String,
    );
  }

  Map<String, Object?> toJson() {
    return {'serverUrl': serverUrl, 'userId': userId, 'email': email};
  }
}
