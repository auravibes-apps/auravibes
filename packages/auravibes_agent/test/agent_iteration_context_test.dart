import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:test/test.dart';

void main() {
  test('compares origin and ack message ids by value', () {
    const first = AgentIterationContext(
      origin: AgentIterationOrigin.manualContinue,
      ackMessageIds: ['m1', 'm2'],
    );
    const same = AgentIterationContext(
      origin: AgentIterationOrigin.manualContinue,
      ackMessageIds: ['m1', 'm2'],
    );
    const differentLength = AgentIterationContext(
      origin: AgentIterationOrigin.manualContinue,
      ackMessageIds: ['m1'],
    );
    const differentValue = AgentIterationContext(
      origin: AgentIterationOrigin.manualContinue,
      ackMessageIds: ['m2', 'm1'],
    );

    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(first, isNot(differentLength));
    expect(first, isNot(differentValue));
    expect(first, isNot('context'));
  });
}
