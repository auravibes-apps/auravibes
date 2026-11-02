import 'package:auravibes_app/features/settings/models/scoped_verification_form_draft.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults stay disabled and incomplete enable is rejected', () {
    final draft = ScopedVerificationFormDraft(ScopedVerificationSettings());
    addTearDown(draft.dispose);
    expect(draft.read().enabled, isFalse);
    expect(draft.isDirty, isFalse);
    draft.enabled = true;
    expect(draft.isDirty, isTrue);
    expect(draft.read, throwsFormatException);
  });

  test('argv round trips including blank and spaced arguments', () {
    final saved = _settings(
      arguments: ['', ' spaced ', r'$(touch marker)', '--flag'],
    );
    final draft = ScopedVerificationFormDraft(saved);
    addTearDown(draft.dispose);
    expect(draft.read().toJson(), saved.toJson());
    draft.checks.single.arguments.text = 'analyze\n--fatal-infos';
    expect(draft.read().checks.single.arguments, ['analyze', '--fatal-infos']);
    expect(draft.isDirty, isTrue);
  });

  test('fractional seconds preserve exact milliseconds', () {
    final saved = _settings(timeout: const Duration(milliseconds: 1500));
    final draft = ScopedVerificationFormDraft(saved);
    addTearDown(draft.dispose);
    expect(draft.timeout.text, '1.5');
    expect(draft.read().timeout, saved.timeout);
    draft.timeout.text = '0.001';
    expect(draft.read().timeout, const Duration(milliseconds: 1));
    draft.timeout.text = '9223372036854775807';
    expect(draft.read, throwsFormatException);
  });

  test('invalid bounds and duplicate check IDs stay in the draft', () {
    final draft = ScopedVerificationFormDraft(_settings());
    addTearDown(draft.dispose);
    draft.output.text = '65537';
    expect(draft.read, throwsFormatException);
    expect(draft.output.text, '65537');
    draft.output.text = '16384';
    draft.repairs.text = '3';
    expect(draft.read, throwsFormatException);
    draft.repairs.text = '1';
    draft.checks.add(ScopedVerificationCheckDraft(draft.read().checks.single));
    expect(draft.read, throwsFormatException);
  });
}

ScopedVerificationSettings _settings({
  List<String> arguments = const ['analyze'],
  Duration timeout = const Duration(seconds: 30),
}) => ScopedVerificationSettings(
  enabled: true,
  runnerToolId: 'runner',
  mcpServerId: 'server',
  workspaceRoot: 'checkout',
  editToolIds: const {'edit'},
  checks: [
    ScopedVerificationCheck(
      id: 'analyze',
      executable: 'dart',
      arguments: arguments,
      pathSuffixes: const ['.dart'],
    ),
  ],
  timeout: timeout,
);
