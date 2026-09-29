# Fix: Autofocus single-purpose cloud-auth steps

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/autofocus-single-field
- **Needs new dependency**: none

## Why

Two conditional cloud-auth steps present one field but require an extra tap: the password-reset email step and registration verification-code step. Other one-field dialogs already set `autofocus: true`.

## Where

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_register_form.dart:45-73`

```dart
    final isCodeStep = _registrationRequestId != null;

    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: .sm,
      children: [
        if (isCodeStep) ...[
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_check_email_title),
            style: AuraTextStyle.heading4,
          ),
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_check_email_body),
          ),
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_dev_code_hint),
            style: AuraTextStyle.bodySmall,
          ),
          AuraInput(
            controller: _code,
            label: Text(LocaleKeys.workspace_management_cloud_code.tr()),
            placeholder: Text(LocaleKeys.workspace_management_cloud_code.tr()),
            textInputAction: .done,
            onSubmitted: (_) => _registerStep(),
            autofocus: true,
            enabled: !_isSubmitting,
          ),
```

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_forgot_password_form.dart:42-91`

```dart
    final isCodeStep = _passwordResetRequestId != null;

    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: .sm,
      children: [
        if (isCodeStep) ...[
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_check_email_title),
            style: AuraTextStyle.heading4,
          ),
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_password_reset_body),
          ),
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_dev_code_hint),
            style: AuraTextStyle.bodySmall,
          ),
          AuraInput(
            controller: _code,
            label: Text(LocaleKeys.workspace_management_cloud_code.tr()),
            placeholder: Text(LocaleKeys.workspace_management_cloud_code.tr()),
            enabled: !_isSubmitting,
          ),
          AuraInput(
            controller: _password,
            label: Text(LocaleKeys.cloud_accounts_new_password.tr()),
            placeholder: Text(LocaleKeys.cloud_accounts_new_password.tr()),
            hint: const TextLocale(LocaleKeys.cloud_accounts_password_hint),
            obscureText: true,
            enabled: !_isSubmitting,
          ),
        ] else ...[
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_password_reset_intro),
          ),
          AuraInput(
            controller: _email,
            label: Text(LocaleKeys.workspace_management_cloud_email.tr()),
            placeholder: Text(LocaleKeys.workspace_management_cloud_email.tr()),
            autofocus: true,
            textInputAction: .done,
            onSubmitted: (_) => _submit(),
            enabled: !_isSubmitting,
          ),
```

Existing correct single-field dialogs:

`apps/auravibes_app/lib/features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart:436`

```dart
      content: TextField(controller: controller, autofocus: true),
```

`apps/auravibes_app/lib/features/chats/widgets/rename_conversation_dialog.dart:79`

```dart
  Widget build(BuildContext context) => TextField(
```

`apps/auravibes_app/lib/features/chats/widgets/rename_conversation_dialog.dart:85`

```dart
    autofocus: true,
```

## The fix

Set the article's literal property on registration's code input:

```dart
AuraInput(
  controller: _code,
  label: Text(LocaleKeys.workspace_management_cloud_code.tr()),
  placeholder: Text(LocaleKeys.workspace_management_cloud_code.tr()),
  autofocus: true,
  enabled: !_isSubmitting,
),
```

Set the same property on password reset's initial email input:

```dart
AuraInput(
  controller: _email,
  label: Text(LocaleKeys.workspace_management_cloud_email.tr()),
  placeholder: Text(LocaleKeys.workspace_management_cloud_email.tr()),
  autofocus: true,
  enabled: !_isSubmitting,
),
```

Do not autofocus the password-reset code step because it displays both code and new-password fields. Do not add a `FocusNode`, a post-frame callback, or change `AuraInput.autofocus` globally; Flutter's built-in autofocus request is the article's fix.

## Steps

1. Add the two explicit autofocus flags.
2. Add widget tests for initial reset focus, registration transition focus, and no autofocus on the two-field reset step.
3. Verify desktop focus and mobile keyboard behavior in normal debug mode, not Flutter Driver mode.

## Check it

```sh
fvm flutter test test/features/cloud_accounts --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- Multi-field login/register/reset steps.
- Global focus policy.
- OTP auto-submit unless the server contract defines an exact code length.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: Confirmed password-reset initial email and registration
  verification-code inputs use `autofocus: true`; reset's code + new-password
  step does not. Tests assert initial reset focus and no autofocus on the
  registration initial multi-field step. The plan's registration-transition
  focus and reset-code-step assertions are absent; mobile keyboard behavior
  remains unverified. Included cloud-account tests passed in the grouped run.

- 2026-09-28: Re-read the canonical article; it supports autofocus only when
  the field is the page's sole choice. Current form gates match that condition.
  `cloud_account_autofocus_test.dart` passed (6 tests). The dynamic
  registration-transition focus assertion and real-device keyboard check
  remain unverified.
- 2026-09-28: Rechecked after merging `origin/main`: both required single-field
  inputs still have `autofocus: true`, and reset's two-field code/password step
  remains unfocused. `fvm flutter test test/features/cloud_accounts --no-pub`
  passed (11 tests). Transition and reset-code-step assertions remain absent;
  reaching those states in a widget test currently invokes extension methods
  that construct a real Serverpod client from a compile-time URL. Adding a
  test seam/refactor violates this plan's scope. Native keyboard check remains
  blocked: iPhone Mirroring reports the device in use; the connected app lacks
  Flutter Driver, and no device state was changed.

## STOP if

- The code field is intentionally populated by platform autofill before mount. Confirm autofill behavior before forcing a selection/cursor move.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report focus assertions and real-keyboard checks.
