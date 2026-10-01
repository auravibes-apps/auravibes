import 'dart:async' show unawaited;

import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_failure.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_target.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_email_delivery_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// ignore_for_file: type=lint

class const CloudAccountForgotPasswordForm({
  required final VoidCallback onFinished,
  final CloudAuthTarget target = const CloudAuthTarget(),
  final ValueChanged<bool>? onPendingChanged,
  final ValueChanged<String>? onEmailChanged,
  final ValueChanged<bool>? onCodeStepChanged,
  super.key,
}) extends ConsumerStatefulWidget {
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

  var _epoch = 0;
  String? _statusKey;

  @override
  void initState() {
    super.initState();
    _email.text = widget.target.email ?? '';
  }

  @override
  void didUpdateWidget(covariant CloudAccountForgotPasswordForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target.owner == widget.target.owner) return;
    _epoch++;
    _email.text = widget.target.email ?? '';
    _password.clear();
    _code.clear();
    _passwordResetRequestId = null;
    _finishToken = null;
    _errorKey = null;
    _statusKey = null;
    _isSubmitting = false;
  }

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
      children: [
        if (ref.watch(cloudEmailDeliveryProvider) == .unavailable)
          const TextLocale(LocaleKeys.cloud_accounts_delivery_unavailable),
        if (isCodeStep) ...[
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_check_email_title),
            style: AuraTextStyle.heading4,
          ),
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_password_reset_body),
          ),
          Text(_email.text),
          if (ref.read(cloudEmailDeliveryProvider) == .developmentLog)
            const TextLocale(LocaleKeys.cloud_accounts_dev_code_hint),
          AuraInput(
            controller: _code,
            label: Text(LocaleKeys.workspace_management_cloud_code.tr()),
            placeholder: Text(LocaleKeys.workspace_management_cloud_code.tr()),
            textInputAction: .next,
            enabled: !_isSubmitting,
          ),
          AuraInput(
            controller: _password,
            label: Text(LocaleKeys.cloud_accounts_new_password.tr()),
            placeholder: Text(LocaleKeys.cloud_accounts_new_password.tr()),
            hint: const TextLocale(LocaleKeys.cloud_accounts_password_hint),
            obscureText: true,
            textInputAction: .done,
            onSubmitted: (_) => _submit(),
            enabled: !_isSubmitting,
          ),
        ] else ...[
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_password_reset_intro),
          ),
          AuraInput(
            controller: _email,
            onChanged: widget.onEmailChanged,
            label: Text(LocaleKeys.workspace_management_cloud_email.tr()),
            placeholder: Text(LocaleKeys.workspace_management_cloud_email.tr()),
            autofocus: true,
            textInputAction: .done,
            onSubmitted: (_) => _submit(),
            enabled: !_isSubmitting,
          ),
        ],
        if (_statusKey case final statusKey?)
          Semantics(liveRegion: true, child: TextLocale(statusKey)),
        if (_errorKey case final errorKey?)
          AuraText(child: TextLocale(errorKey), style: AuraTextStyle.bodySmall),
        AuraButton(
          onPressed: _submit,
          child: TextLocale(
            isCodeStep
                ? LocaleKeys.cloud_accounts_finish_password_reset
                : LocaleKeys.cloud_accounts_send_password_reset_code,
          ),
          isLoading: _isSubmitting,
          disabled:
              _isSubmitting ||
              ref.read(cloudEmailDeliveryProvider) == .unavailable,
        ),
        if (isCodeStep) ...[
          AuraButton(
            onPressed: _resendCode,
            child: const TextLocale(LocaleKeys.cloud_accounts_resend_code),
            variant: AuraButtonVariant.outlined,
            disabled:
                _isSubmitting ||
                ref.read(cloudEmailDeliveryProvider) == .unavailable,
          ),
          AuraButton(
            onPressed: () => setState(() {
              _passwordResetRequestId = null;
              _finishToken = null;
              _code.clear();
              _errorKey = null;
              _statusKey = null;
              widget.onCodeStepChanged?.call(false);
              _password.clear();
            }),
            child: const TextLocale(LocaleKeys.cloud_accounts_edit_email),
            variant: AuraButtonVariant.outlined,
            disabled:
                _isSubmitting ||
                ref.read(cloudEmailDeliveryProvider) == .unavailable,
          ),
        ],
      ],
      spacing: .sm,
      crossAxisAlignment: CrossAxisAlignment.stretch,
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final epoch = _epoch;
    final target = widget.target.withEmail(_email.text.trim());
    widget.onEmailChanged?.call(_email.text.trim());
    widget.onPendingChanged?.call(true);

    setState(() {
      _isSubmitting = true;
      _errorKey = null;
      _statusKey = null;
    });

    try {
      final useCases = ref.read(cloudAccountUseCasesProvider);
      final requestId = _passwordResetRequestId;
      if (requestId == null) {
        final nextRequestId = await useCases.startPasswordReset(
          email: _email.text.trim(),
          target: target,
        );
        if (!mounted || epoch != _epoch) return;
        setState(() => _passwordResetRequestId = nextRequestId);
        widget.onCodeStepChanged?.call(true);

        return;
      }

      final token =
          _finishToken ??
          await useCases.verifyPasswordResetCode(
            passwordResetRequestId: requestId,
            target: target,
            code: _code.text.trim(),
          );
      if (!mounted || epoch != _epoch) return;
      _finishToken = token;
      await useCases.finishPasswordReset(
        finishPasswordResetToken: token,
        target: target,
        newPassword: _password.text,
      );
      if (!mounted || epoch != _epoch) return;
      unawaited(AuraHaptics.success());
      widget.onFinished();
    } on Object catch (error) {
      if (!mounted || epoch != _epoch) return;
      unawaited(AuraHaptics.error());
      setState(() => _errorKey = _passwordResetErrorKey(error));
    } finally {
      if (mounted && epoch == _epoch) {
        setState(() => _isSubmitting = false);
        widget.onPendingChanged?.call(false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_isSubmitting) return;
    final epoch = _epoch;
    final target = widget.target.withEmail(_email.text.trim());
    widget.onEmailChanged?.call(_email.text.trim());
    widget.onPendingChanged?.call(true);

    setState(() {
      _isSubmitting = true;
      _errorKey = null;
      _statusKey = null;
    });

    try {
      final requestId = await ref
          .read(cloudAccountUseCasesProvider)
          .startPasswordReset(email: _email.text.trim(), target: target);
      if (!mounted || epoch != _epoch) return;
      setState(() {
        _passwordResetRequestId = requestId;
        _finishToken = null;
        _code.clear();
        _password.clear();
        _statusKey = LocaleKeys.cloud_accounts_code_resent;
      });
    } on Object catch (error) {
      if (!mounted || epoch != _epoch) return;
      setState(() => _errorKey = _passwordResetErrorKey(error));
    } finally {
      if (mounted && epoch == _epoch) {
        setState(() => _isSubmitting = false);
        widget.onPendingChanged?.call(false);
      }
    }
  }

  String _passwordResetErrorKey(Object error) => CloudAuthFailure.key(error);
}
