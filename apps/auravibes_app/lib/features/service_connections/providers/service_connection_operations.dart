part of 'service_connection_operations_provider.dart';

class ServiceConnectionOperations {
  const ServiceConnectionOperations({
    required this.createAppSkillCredential,
    required this.getGenericForEdit,
    required this.updateGeneric,
  });

  final Future<void> Function({
    required String workspaceId,
    required String appSkillServiceId,
    required String name,
    required String apiKey,
  })
  createAppSkillCredential;
  final Future<GenericServiceConnectionForEdit?> Function(String id)
  getGenericForEdit;
  final Future<void> Function(
    GenericServiceConnectionForEdit connection,
    GenericServiceConnectionUpdate update,
  )
  updateGeneric;
}
