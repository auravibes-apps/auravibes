import 'package:auravibes_app/features/settings/models/workspace_settings_draft_guards.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cleaning either section preserves the other section dirty state', () {
    final parent = DraftExitGuard();
    final guards = WorkspaceSettingsDraftGuards(parent);
    addTearDown(() {
      guards.dispose();
      parent.dispose();
    });
    guards.compaction.update(isDirty: true, isSaving: false);
    guards.verification.update(isDirty: true, isSaving: false);
    guards.compaction.update(isDirty: false, isSaving: false);
    expect(parent.isDirty, isTrue);
    expect(parent.canPop, isFalse);
    guards.verification.update(isDirty: false, isSaving: false);
    expect(parent.isDirty, isFalse);
    expect(parent.canPop, isTrue);
  });

  test(
    'saving in either section blocks navigation through a clean sibling',
    () {
      final parent = DraftExitGuard();
      final guards = WorkspaceSettingsDraftGuards(parent);
      addTearDown(() {
        guards.dispose();
        parent.dispose();
      });
      guards.verification.update(isDirty: false, isSaving: true);
      guards.compaction.update(isDirty: false, isSaving: false);
      expect(parent.isSaving, isTrue);
      expect(parent.canPop, isFalse);
    },
  );

  test('independent child bindings stay live in the parent readers', () {
    final parent = DraftExitGuard();
    final guards = WorkspaceSettingsDraftGuards(parent);
    addTearDown(() {
      guards.dispose();
      parent.dispose();
    });
    var compactionDirty = false;
    var verificationDirty = false;
    guards.compaction.bind(
      readers: (isDirty: () => compactionDirty, isSaving: () => false),
    );
    guards.verification.bind(
      readers: (isDirty: () => verificationDirty, isSaving: () => false),
    );
    compactionDirty = true;
    expect(parent.isDirty, isTrue);
    compactionDirty = false;
    verificationDirty = true;
    expect(parent.isDirty, isTrue);
    verificationDirty = false;
    expect(parent.canPop, isTrue);
  });

  test('disposing removes section readers from the route guard', () {
    final parent = DraftExitGuard();
    final guards = WorkspaceSettingsDraftGuards(parent);
    guards.verification.update(isDirty: true, isSaving: false);
    guards.dispose();
    expect(parent.isDirty, isFalse);
    expect(parent.isSaving, isFalse);
    parent.dispose();
  });
}
