# Fix: Add capability-checked haptics to key interactions

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/haptic-feedback
- **Needs new dependency**: add `haptic_feedback` to `packages/auravibes_ui`

## Why

The app and Aura UI package have no haptic calls. Tabs, switches, and cloud-auth success/error states change silently on supported phones.

## Where

`packages/auravibes_ui/lib/src/molecules/aura_tabs.dart:168-191`

```dart
  void _select(int index) {
    if (widget._mode == _AuraTabsMode.selector) {
      final options = widget.options;
      final selectedIndex = _selectedOptionIndex(options);
      if (index == selectedIndex) return;

      if (widget.value == null) {
        setState(() => _selectedIndex = index);
      }
      widget._selectorOnChanged?.call(options[index].value);

      return;
    }

    final selectedIndex = _normalizeIndex(
      widget.selectedIndex ?? _selectedIndex,
      widget.items.length,
    );
    if (index == selectedIndex) return;

    if (widget.selectedIndex == null) {
      setState(() => _selectedIndex = index);
    }
    widget.onChanged?.call(index);
```

`packages/auravibes_ui/lib/src/organisms/aura_switch.dart:70-75`

```dart
  @override
  Widget build(BuildContext context) =>
      _AuraSwitchBuildData(this, context).child;

  void _toggle() => widget.onChanged?.call(!widget.value);

```

Cloud-auth completion/error branches currently call callbacks/set error keys without feedback:

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_login_form.dart:77-89`

```dart
    try {
      await WorkspaceManagementMutations.cloudAccount.run(ref, (_) async {
        final account = await ref
            .read(cloudAccountUseCasesProvider)
            .login(email: _email.text.trim(), password: _password.text);
        ref.invalidate(cloudAccountsProvider);
        widget.onSignedIn(account);
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorKey = cloudAccountErrorKey(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
```

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_register_form.dart:128-160`

```dart
    try {
      await WorkspaceManagementMutations.cloudAccount.run(ref, (_) async {
        final useCases = ref.read(cloudAccountUseCasesProvider);
        final requestId = _registrationRequestId;
        if (requestId == null) {
          final nextRequestId = await useCases.startRegistration(
            email: _email.text.trim(),
          );
          if (!mounted) return;
          setState(() => _registrationRequestId = nextRequestId);

          return;
        }

        final token =
            _registrationToken ??
            await useCases.verifyRegistrationCode(
              accountRequestId: requestId,
              code: _code.text.trim(),
            );
        _registrationToken = token;
        final account = await useCases.finishRegistration(
          registrationToken: token,
          password: _password.text,
        );
        ref.invalidate(cloudAccountsProvider);
        widget.onSignedIn(account);
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorKey = _registrationErrorKey(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
```

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_forgot_password_form.dart:128-159`

```dart
    try {
      final useCases = ref.read(cloudAccountUseCasesProvider);
      final requestId = _passwordResetRequestId;
      if (requestId == null) {
        final nextRequestId = await useCases.startPasswordReset(
          email: _email.text.trim(),
        );
        if (!mounted) return;
        setState(() => _passwordResetRequestId = nextRequestId);

        return;
      }

      final token =
          _finishToken ??
          await useCases.verifyPasswordResetCode(
            passwordResetRequestId: requestId,
            code: _code.text.trim(),
          );
      _finishToken = token;
      await useCases.finishPasswordReset(
        finishPasswordResetToken: token,
        newPassword: _password.text,
      );
      if (!mounted) return;
      widget.onFinished();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorKey = _passwordResetErrorKey(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
```

## The fix

Add and export the article's capability-checked helper from `auravibes_ui`, with a narrow platform-failure guard:

```dart
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:haptic_feedback/haptic_feedback.dart';

abstract final class AuraHaptics {
  static bool? _canVibrate;

  static Future<void> _vibrate(HapticsType type) async {
    try {
      _canVibrate ??= await Haptics.canVibrate();
      if (_canVibrate ?? false) await Haptics.vibrate(type);
    } on Object {
      _canVibrate = false;
    }
  }

  static Future<void> success() => _vibrate(HapticsType.success);
  static Future<void> warning() => _vibrate(HapticsType.warning);
  static Future<void> error() => _vibrate(HapticsType.error);
  static Future<void> light() => _vibrate(HapticsType.light);
  static Future<void> medium() => _vibrate(HapticsType.medium);
  static Future<void> heavy() => _vibrate(HapticsType.heavy);
  static Future<void> selection() => _vibrate(HapticsType.selection);

  @visibleForTesting
  static void resetForTesting() => _canVibrate = null;
}
```

`Haptics.canVibrate()` is the gate; do not duplicate platform lists in callers. A failed capability/vibration call disables later calls for the process instead of throwing into UI callbacks.

Pair only:

- `selection` after a real selector-option change;
- `light` after a real navigation-tab change;
- `light` after an enabled switch toggle;
- `success` after cloud auth/register/reset completes and a semantic success snackbar is shown;
- `error` after those user-triggered submissions fail and a semantic error snackbar is shown.

Direct Flutter snackbars outside `AuraSnackBars` need an explicit haptic at
their user-triggered error path. Default, warning, and info snackbars stay
silent.

Trigger after guards, never on disabled taps, rebuilds, initialization, or controlled-value updates. Call `unawaited(AuraHaptics.light())`/the mapped method so UI callbacks are not delayed.

## Steps

1. Add dependency with `fvm flutter pub add haptic_feedback` from `packages/auravibes_ui`.
2. Add/export `AuraHaptics`; mock the package platform channel in tests instead of adding a production abstraction.
3. Integrate tabs and switch at their central state-change points.
4. Integrate shared success/error snackbar variants and the three auth form outcomes through the exported helper.
5. Add tests for supported/unsupported devices, exactly-once calls, semantic snackbar variants, no haptic on same tab/disabled switch, and swallowed platform errors.

## Check it

```sh
cd packages/auravibes_ui && fvm flutter test --no-pub
cd ../../apps/auravibes_app && fvm flutter test test/features/cloud_accounts --no-pub
```

Manual check on a physical phone. Simulators are not evidence of vibration.

## Don't touch

- Every button tap.
- Background events.
- Desktop/web feedback.
- Sound effects.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The dependency version does not support the repository's Android/iOS deployment targets. Use Flutter's built-in `HapticFeedback` behind the same helper rather than changing platform targets.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report package version, tested physical device, and event-to-haptic mapping.

## Attempt log

### 2026-09-28 — implemented; physical verification blocked

- Added `haptic_feedback: ^0.8.0` and exported capability-checked `AuraHaptics` from `auravibes_ui`.
- Mapped selector change to selection, tab change and enabled switch change to light, and completed/failed cloud auth submissions to success/error.
- Focused UI tests passed: 54 tests across haptics, tabs, and switch; cloud-account tests passed: 11 tests. Haptics-only rerun passed: 6 tests.
- Fatal analyzer passed for all changed Dart files. Package-wide analyzer reported pre-existing warnings in `test/src/organisms/auravibes_input_test.dart`; it was not clean.
- Physical-device test not run. `fvm flutter devices` and `xcrun xctrace list devices` could not enumerate devices because their tool caches attempted writes outside writable workspace paths. Simulators are not accepted as vibration evidence.
- Status: code and automated checks complete; physical vibration verification remains open.

### 2026-09-28 — fresh catalog rescan follow-up

- The catalog rescan found a second user-triggered error path: failure to open a confirmed chat markdown link showed an error snackbar without haptic feedback.
- Added asynchronous error feedback to that path and extended its widget test to assert the `canVibrate` check and exactly one `error` haptic.
- Focused test passed: `fvm flutter test test/features/chats/widgets/chat_messages_widget_test.dart --plain-name 'shows link exception feedback' --no-pub` (1 test).
- Fatal analyzer passed for the changed widget and test files.
- Physical-device verification remains open; automated tests do not prove vibration on hardware.

### 2026-09-28 — centralized snackbar result haptics

- The fresh catalog scan found app-wide success/error snackbars beyond cloud auth. `AuraSnackBars` now maps only `.success` and `.error` variants to matching haptics after host acceptance; default, warning, and info stay silent.
- Combined haptic/snackbar suites passed (21 tests); haptic suite rerun after a test-only ordering fix passed (7 tests). Fatal analyzer passed for the snackbar source and haptic test.
- Physical-device vibration verification remains open.

### 2026-09-28 — shared choice-picker selection feedback

- Rechecked the source article: it maps selecting from dropdowns/options to `selection` feedback. `AuraChoicePicker` is used for app settings and workspace/agent choices.
- Added selection feedback at the shared option-change handler, after interactivity and no-change guards. Read-only, disabled, and unchanged selections stay silent.
- Added a regression test first; it failed with no haptic calls before the implementation. After the fix, the haptics suite passed (8 tests) and choice-picker suite passed (13 tests).
- Fatal analysis passed for the changed picker and haptic test; formatter check passed after formatting the test file.
- Physical-device vibration verification remains open; automated tests do not prove vibration on hardware.
