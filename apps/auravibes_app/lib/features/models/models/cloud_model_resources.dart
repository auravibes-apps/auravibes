import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudModelConnection {
  const CloudModelConnection({
    required this.id,
    required this.revision,
    required this.name,
    required this.providerId,
    required this.hasSecret,
    required this.createdAt,
    required this.updatedAt,
    this.url,
    this.keySuffix,
  });

  factory CloudModelConnection.fromView(ModelConnectionView view) {
    return CloudModelConnection(
      id: view.id,
      revision: view.revision,
      name: view.name,
      providerId: view.providerId,
      hasSecret: view.hasSecret,
      createdAt: view.createdAt,
      updatedAt: view.updatedAt,
      url: view.url,
      keySuffix: view.keySuffix,
    );
  }

  final String id;
  final int revision;
  final String name;
  final String providerId;
  final bool hasSecret;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? url;
  final String? keySuffix;
}
