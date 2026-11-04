import 'package:meta/meta.dart';

/// The source category for context supplied to an agent.
enum AgentContextOrigin {
  unknown,
  applicationPrompt,
  userConversation,
  userAgentConfiguration,
  applicationSkill,
  importedSkill,
  toolResult,
  compactionSummary,
}

/// The authority carried by context, independent of its message role.
enum AgentContextTrust {
  unknown,
  appControlled,
  userProvided,
  userAuthorized,
  externalUntrusted,
}

const agentContextProvenanceMetadataKey = 'agentContextProvenance';

/// Typed, content-free provenance for prompt context.
@immutable
class const AgentContextProvenance({
  required final AgentContextOrigin origin,
  required final AgentContextTrust trust,
}) {
  static const unknown = AgentContextProvenance(
    origin: .unknown,
    trust: .unknown,
  );
  static const applicationPrompt = AgentContextProvenance(
    origin: .applicationPrompt,
    trust: .appControlled,
  );
  static const userConversation = AgentContextProvenance(
    origin: .userConversation,
    trust: .userProvided,
  );
  static const userAgentConfiguration = AgentContextProvenance(
    origin: .userAgentConfiguration,
    trust: .userAuthorized,
  );
  static const applicationSkill = AgentContextProvenance(
    origin: .applicationSkill,
    trust: .appControlled,
  );
  static const importedSkill = AgentContextProvenance(
    origin: .importedSkill,
    trust: .externalUntrusted,
  );
  static const toolResult = AgentContextProvenance(
    origin: .toolResult,
    trust: .externalUntrusted,
  );
  static const compactionSummary = AgentContextProvenance(
    origin: .compactionSummary,
    trust: .externalUntrusted,
  );

  bool get mayUseSystemRole =>
      (origin == AgentContextOrigin.applicationPrompt &&
          trust == AgentContextTrust.appControlled) ||
      (origin == AgentContextOrigin.applicationSkill &&
          trust == AgentContextTrust.appControlled) ||
      (origin == AgentContextOrigin.userAgentConfiguration &&
          trust == AgentContextTrust.userAuthorized);

  Map<String, String> toJson() => {'origin': origin.name, 'trust': trust.name};

  /// Replaces any existing provenance metadata with this typed value.
  Map<String, Object?> withMetadata(Map<String, Object?> metadata) => {
    ...metadata,
    agentContextProvenanceMetadataKey: toJson(),
  };

  static AgentContextProvenance fromMetadata(Map<String, Object?>? metadata) =>
      fromJson(metadata?[agentContextProvenanceMetadataKey]);

  static AgentContextProvenance fromJson(Object? value) {
    if (value is! Map ||
        value.length != 2 ||
        !value.containsKey('origin') ||
        !value.containsKey('trust')) {
      return unknown;
    }
    final originName = value['origin'];
    final trustName = value['trust'];
    if (originName is! String || trustName is! String) return unknown;

    return switch ((originName, trustName)) {
      ('unknown', 'unknown') => unknown,
      ('applicationPrompt', 'appControlled') => applicationPrompt,
      ('userConversation', 'userProvided') => userConversation,
      ('userAgentConfiguration', 'userAuthorized') => userAgentConfiguration,
      ('applicationSkill', 'appControlled') => applicationSkill,
      ('importedSkill', 'externalUntrusted') => importedSkill,
      ('toolResult', 'externalUntrusted') => toolResult,
      ('compactionSummary', 'externalUntrusted') => compactionSummary,
      _ => unknown,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is AgentContextProvenance &&
      other.origin == origin &&
      other.trust == trust;

  @override
  int get hashCode => Object.hash(origin, trust);
}
