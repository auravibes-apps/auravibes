import 'package:auravibes_app/domain/models/credential_definition_schema.dart';
import 'package:auravibes_app/domain/models/credential_dependency.dart';

class const CredentialDefinitionUsage({
  final List<CredentialDependency> credentials = const [],
  final List<CredentialDependency> skills = const [],
  final List<CredentialDependency> tools = const [],
}) {
  bool get isEmpty => credentials.isEmpty && skills.isEmpty && tools.isEmpty;

  void ensureCanDelete() {
    if (isEmpty) return;
    throw CredentialDefinitionConflictException(
      reason: .deletion,
      credentialCount: credentials.length,
      skillCount: skills.length,
      toolCount: tools.length,
    );
  }
}
