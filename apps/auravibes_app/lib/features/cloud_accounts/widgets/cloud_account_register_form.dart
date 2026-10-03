import 'dart:async' show unawaited;

import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_failure.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_target.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_email_delivery_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_management_mode.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// ignore_for_file: type=lint

class const CloudAccountRegisterForm({
  required final ValueChanged<CloudAccountSession> onSignedIn,
  final CloudAuthTarget target = const CloudAuthTarget(),
  final ValueChanged<bool>? onPendingChanged,
  final ValueChanged<String>? onEmailChanged,
  final ValueChanged<bool>? onCodeStepChanged,
  super.key,
}) extends ConsumerStatefulWidget {
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

  var _epoch = 0;
  String? _statusKey;

  @override
  void initState() {
    super.initState();
    _email.text = widget.target.email ?? '';
  }

  @override
  void didUpdateWidget(covariant CloudAccountRegisterForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target.owner == widget.target.owner) return;
    _epoch++;
    _email.text = widget.target.email ?? '';
    _password.clear();
    _code.clear();
    _registrationRequestId = null;
    _registrationToken = null;
    _errorKey = null;
    _statusKey = null;
    _isSubmitting = false;
  }

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
      children: [
        if (ref.watch(cloudEmailDeliveryProvider) == .unavailable)
          const TextLocale(LocaleKeys.cloud_accounts_delivery_unavailable),
        if (isCodeStep) ...[
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_check_email_title),
            style: AuraTextStyle.heading4,
          ),
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_check_email_body),
          ),
          Text(_email.text),
          if (ref.read(cloudEmailDeliveryProvider) == .developmentLog)
            const TextLocale(LocaleKeys.cloud_accounts_dev_code_hint),
          AuraInput(
            controller: _code,
            label: Text(LocaleKeys.workspace_management_cloud_code.tr()),
            placeholder: Text(LocaleKeys.workspace_management_cloud_code.tr()),
            textInputAction: .done,
            onSubmitted: (_) => _registerStep(),
            autofocus: true,
            enabled: !_isSubmitting,
          ),
        ] else ...[
          AuraInput(
            controller: _email,
            onChanged: widget.onEmailChanged,
            label: Text(LocaleKeys.workspace_management_cloud_email.tr()),
            placeholder: Text(LocaleKeys.workspace_management_cloud_email.tr()),
            textInputAction: .next,
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
            textInputAction: .done,
            onSubmitted: (_) => _registerStep(),
            enabled: !_isSubmitting,
          ),
        ],
        if (_statusKey case final statusKey?)
          Semantics(liveRegion: true, child: TextLocale(statusKey)),
        if (_errorKey case final errorKey?)
          AuraText(child: TextLocale(errorKey), style: AuraTextStyle.bodySmall),
        AuraButton(
          onPressed: _registerStep,
          child: TextLocale(
            isCodeStep
                ? LocaleKeys.workspace_management_cloud_finish_register
                : LocaleKeys.workspace_management_cloud_register,
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
              _registrationRequestId = null;
              _registrationToken = null;
              _code.clear();
              _errorKey = null;
              _statusKey = null;
              widget.onCodeStepChanged?.call(false);
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

  Future<void> _registerStep() async {
    if (_isSubmitting) return;
    final epoch = _epoch;
    final target = widget.target.withEmail(_email.text.trim());
    widget.onEmailChanged?.call(_email.text.trim());
    widget.onPendingChanged?.call(true);

    setState(() {
      _errorKey = null;
      _statusKey = null;
      _isSubmitting = true;
    });
    try {
      await WorkspaceManagementMutations.cloudAccount.run(ref, (_) async {
        final useCases = ref.read(cloudAccountUseCasesProvider);
        final requestId = _registrationRequestId;
        if (requestId == null) {
          final nextRequestId = await useCases.startRegistration(
            email: _email.text.trim(),
            target: target,
          );
          if (!mounted || epoch != _epoch) return;
          setState(() => _registrationRequestId = nextRequestId);
          widget.onCodeStepChanged?.call(true);

          return;
        }

        final token =
            _registrationToken ??
            await useCases.verifyRegistrationCode(
              accountRequestId: requestId,
              target: target,
              code: _code.text.trim(),
            );
        if (!mounted || epoch != _epoch) return;
        _registrationToken = token;
        final account = await useCases.finishRegistration(
          registrationToken: token,
          target: target,
          password: _password.text,
        );
        if (!mounted || epoch != _epoch) return;
        ref.invalidate(cloudAccountsProvider);
        unawaited(AuraHaptics.success());
        widget.onSignedIn(account);
      });
    } on Object catch (error) {
      if (!mounted || epoch != _epoch) return;
      unawaited(AuraHaptics.error());
      setState(() => _errorKey = _registrationErrorKey(error));
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
      _errorKey = null;
      _statusKey = null;
      _isSubmitting = true;
    });

    try {
      final requestId = await ref
          .read(cloudAccountUseCasesProvider)
          .startRegistration(email: _email.text.trim(), target: target);
      if (!mounted || epoch != _epoch) return;
      setState(() {
        _registrationRequestId = requestId;
        _registrationToken = null;
        _code.clear();
        _statusKey = LocaleKeys.cloud_accounts_code_resent;
      });
    } on Object catch (error) {
      if (!mounted || epoch != _epoch) return;
      setState(() => _errorKey = _registrationErrorKey(error));
    } finally {
      if (mounted && epoch == _epoch) {
        setState(() => _isSubmitting = false);
        widget.onPendingChanged?.call(false);
      }
    }
  }

  String _registrationErrorKey(Object error) => CloudAuthFailure.key(error);
}
