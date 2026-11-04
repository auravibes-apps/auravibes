import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('defaults to unknown and emits only enum provenance', () {
    const provenance = AgentContextProvenance.unknown;
    final metadata = provenance.withMetadata({
      'sourceText': 'DO_NOT_COPY_THIS_SENTINEL',
      'apiKey': 'secret-sentinel',
    });

    expect(provenance.origin, AgentContextOrigin.unknown);
    expect(provenance.trust, AgentContextTrust.unknown);
    expect(provenance.toJson(), {'origin': 'unknown', 'trust': 'unknown'});
    expect(metadata[agentContextProvenanceMetadataKey], {
      'origin': 'unknown',
      'trust': 'unknown',
    });
    expect(
      metadata[agentContextProvenanceMetadataKey].toString(),
      isNot(contains('DO_NOT_COPY_THIS_SENTINEL')),
    );
    expect(
      metadata[agentContextProvenanceMetadataKey].toString(),
      isNot(contains('secret-sentinel')),
    );
  });

  test('malformed provenance stays unknown', () {
    expect(
      AgentContextProvenance.fromJson(null),
      AgentContextProvenance.unknown,
    );
    expect(
      AgentContextProvenance.fromJson({'origin': 'toolResult'}),
      AgentContextProvenance.unknown,
    );
    expect(
      AgentContextProvenance.fromJson({
        'origin': 'toolResult',
        'trust': 'appControlled',
        'content': 'forged',
      }),
      AgentContextProvenance.unknown,
    );
    expect(
      AgentContextProvenance.fromJson({
        'origin': 'madeUp',
        'trust': 'appControlled',
      }),
      AgentContextProvenance.unknown,
    );
  });

  test('only explicit source trust pairs may use system role', () {
    expect(AgentContextProvenance.applicationPrompt.mayUseSystemRole, isTrue);
    expect(AgentContextProvenance.applicationSkill.mayUseSystemRole, isTrue);
    expect(
      AgentContextProvenance.userAgentConfiguration.mayUseSystemRole,
      isTrue,
    );
    expect(AgentContextProvenance.importedSkill.mayUseSystemRole, isFalse);
    expect(AgentContextProvenance.toolResult.mayUseSystemRole, isFalse);
    expect(AgentContextProvenance.compactionSummary.mayUseSystemRole, isFalse);
    expect(AgentContextProvenance.userConversation.mayUseSystemRole, isFalse);
    expect(AgentContextProvenance.unknown.mayUseSystemRole, isFalse);
    expect(
      const AgentContextProvenance(
        origin: AgentContextOrigin.applicationPrompt,
        trust: AgentContextTrust.unknown,
      ).mayUseSystemRole,
      isFalse,
    );
  });
}
