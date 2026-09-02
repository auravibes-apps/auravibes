import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudModelConnection({
  required final String id,
  required final int revision,
  required final String name,
  required final String providerId,
  required final bool hasSecret,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final String? url,
  final String? keySuffix,
}) {
  factory fromView(ModelConnectionView view) {
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
}
