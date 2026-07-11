// ignore_for_file: type=lint

import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_login_form.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CloudAccountForgotPasswordForm extends ConsumerStatefulWidget {
  const CloudAccountForgotPasswordForm({this.onFinished, super.key});

  final VoidCallback? onFinished;

  @override
  ConsumerState<CloudAccountForgotPasswordForm> createState() =>
      _CloudAccountForgotPasswordFormState();
}

class _CloudAccountForgotPasswordFormState
    extends ConsumerState<CloudAccountForgotPasswordForm> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  UuidValue? _passwordResetRequestId;
  String? _finishToken;
  String? _errorKey;
  var _isSubmitting = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            enabled: !_isSubmitting,
          ),
        ],
        if (_errorKey case final errorKey?)
          AuraText(
            style: AuraTextStyle.bodySmall,
            child: TextLocale(errorKey),
          ),
        AuraButton(
          onPressed: _submit,
          child: TextLocale(
            isCodeStep
                ? LocaleKeys.cloud_accounts_finish_password_reset
                : LocaleKeys.cloud_accounts_send_password_reset_code,
          ),
          isLoading: _isSubmitting,
          disabled: _isSubmitting,
        ),
        if (isCodeStep) ...[
          AuraButton(
            onPressed: _resendCode,
            child: const TextLocale(LocaleKeys.cloud_accounts_resend_code),
            variant: AuraButtonVariant.outlined,
            disabled: _isSubmitting,
          ),
          AuraButton(
            onPressed: () => setState(() {
              _passwordResetRequestId = null;
              _finishToken = null;
              _code.clear();
              _password.clear();
            }),
            child: const TextLocale(LocaleKeys.cloud_accounts_edit_email),
            variant: AuraButtonVariant.outlined,
            disabled: _isSubmitting,
          ),
        ],
      ],
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorKey = null;
    });

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
      widget.onFinished?.call();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorKey = _passwordResetErrorKey(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendCode() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorKey = null;
    });

    try {
      final requestId = await ref
          .read(cloudAccountUseCasesProvider)
          .startPasswordReset(email: _email.text.trim());
      if (!mounted) return;
      setState(() {
        _passwordResetRequestId = requestId;
        _finishToken = null;
        _code.clear();
        _password.clear();
        _errorKey = LocaleKeys.cloud_accounts_code_resent;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorKey = _passwordResetErrorKey(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _passwordResetErrorKey(Object error) {
    final message = error.toString();
    if (message.contains('policyViolation')) {
      return LocaleKeys.cloud_accounts_password_policy_error;
    }
    if (message.contains('expired')) {
      return LocaleKeys.cloud_accounts_code_expired_error;
    }
    if (message.contains('tooManyAttempts')) {
      return LocaleKeys.cloud_accounts_too_many_attempts_error;
    }
    if (message.contains('invalid')) {
      return LocaleKeys.cloud_accounts_code_invalid_error;
    }

    return cloudAccountErrorKey(error);
  }
}
