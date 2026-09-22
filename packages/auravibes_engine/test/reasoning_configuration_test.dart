import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  final options = [
    const ReasoningOption.toggle(),
    ReasoningOption.effort(['low', 'medium', 'high']),
    ReasoningOption.budgetTokens(1024, 32768),
  ];

  test('round trips configuration JSON', () {
    const configuration = ReasoningConfiguration(
      enabled: true,
      effort: 'high',
      budgetTokens: 8192,
    );

    expect(
      ReasoningConfiguration.fromJson(configuration.toJson()).toJson(),
      configuration.toJson(),
    );
    expect(
      ReasoningConfiguration.decode(configuration.encode())?.budgetTokens,
      8192,
    );
  });

  test('validates option values and disabled precedence', () {
    expect(
      const ReasoningConfiguration(effort: 'high').isValidFor(options),
      isTrue,
    );
    expect(
      const ReasoningConfiguration(effort: 'xhigh').isValidFor(options),
      isFalse,
    );
    expect(
      const ReasoningConfiguration(budgetTokens: 32769).isValidFor(options),
      isFalse,
    );
    expect(
      const ReasoningConfiguration(
        enabled: false,
        effort: 'unknown',
        budgetTokens: 1,
      ).isValidFor(options),
      isTrue,
    );
  });

  test('malformed JSON returns null through tolerant decoder', () {
    expect(ReasoningConfiguration.decode('{"budget_tokens":"bad"}'), isNull);
    expect(ReasoningConfiguration.decode(null), isNull);
  });
}
