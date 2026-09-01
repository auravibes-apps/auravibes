part of 'service_connection_operations_provider.dart';

class const ServiceConnectionOperations({
  required final Future<void> Function({
    required String workspaceId,
    required String appSkillServiceId,
    required String name,
    required String apiKey,
  })
  createAppSkillCredential,
  required final Future<GenericServiceConnectionForEdit?> Function(String id)
  getGenericForEdit,
  required final Future<void> Function(
    GenericServiceConnectionForEdit connection,
    GenericServiceConnectionUpdate update,
  )
  updateGeneric,
});
