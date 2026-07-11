// ignore_for_file: type=lint

import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_login_form.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_management_mode.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CloudAccountRegisterForm extends ConsumerStatefulWidget {
  const CloudAccountRegisterForm({this.onSignedIn, super.key});

  final ValueChanged<CloudAccountSession>? onSignedIn;

  @override
  ConsumerState<CloudAccountRegisterForm> createState() =>
      _CloudAccountRegisterFormState();
}

class _CloudAccountRegisterFormState
    extends ConsumerState<CloudAccountRegisterForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  UuidValue? _registrationRequestId;
  String? _registrationToken;
  String? _errorKey;
  var _isSubmitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            enabled: !_isSubmitting,
          ),
        ] else ...[
          AuraInput(
            controller: _email,
            label: Text(LocaleKeys.workspace_management_cloud_email.tr()),
            placeholder: Text(LocaleKeys.workspace_management_cloud_email.tr()),
            enabled: !_isSubmitting,
          ),
          AuraInput(
            controller: _password,
            label: Text(LocaleKeys.workspace_management_cloud_password.tr()),
            placeholder: Text(
              LocaleKeys.workspace_management_cloud_password.tr(),
            ),
            hint: const TextLocale(LocaleKeys.cloud_accounts_password_hint),
            obscureText: true,
            enabled: !_isSubmitting,
          ),
        ],
        if (_errorKey case final errorKey?)
          AuraText(
            style: AuraTextStyle.bodySmall,
            child: TextLocale(errorKey),
          ),
        AuraButton(
          onPressed: _registerStep,
          child: TextLocale(
            isCodeStep
                ? LocaleKeys.workspace_management_cloud_finish_register
                : LocaleKeys.workspace_management_cloud_register,
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
              _registrationRequestId = null;
              _registrationToken = null;
              _code.clear();
            }),
            variant: AuraButtonVariant.outlined,
            child: const TextLocale(LocaleKeys.cloud_accounts_edit_email),
            disabled: _isSubmitting,
          ),
        ],
      ],
    );
  }

  Future<void> _registerStep() async {
    if (_isSubmitting) return;

    setState(() {
      _errorKey = null;
      _isSubmitting = true;
    });
    try {
      await cloudAccountMutation.run(ref, (_) async {
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
        widget.onSignedIn?.call(account);
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorKey = _registrationErrorKey(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendCode() async {
    if (_isSubmitting) return;

    setState(() {
      _errorKey = null;
      _isSubmitting = true;
    });

    try {
      final requestId = await ref
          .read(cloudAccountUseCasesProvider)
          .startRegistration(email: _email.text.trim());
      if (!mounted) return;
      setState(() {
        _registrationRequestId = requestId;
        _registrationToken = null;
        _code.clear();
        _errorKey = LocaleKeys.cloud_accounts_code_resent;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorKey = _registrationErrorKey(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _registrationErrorKey(Object error) {
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
    if (message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Failed host lookup') ||
        message.contains('server is not configured')) {
      return LocaleKeys.cloud_accounts_server_unreachable_error;
    }

    return cloudAccountErrorKey(error);
  }
}
