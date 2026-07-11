// ignore_for_file: type=lint

import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_management_mode.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CloudAccountLoginForm extends ConsumerStatefulWidget {
  const CloudAccountLoginForm({required this.onSignedIn, super.key});

  final ValueChanged<CloudAccountSession> onSignedIn;

  @override
  ConsumerState<CloudAccountLoginForm> createState() =>
      _CloudAccountLoginFormState();
}

class _CloudAccountLoginFormState extends ConsumerState<CloudAccountLoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _isSubmitting = false;
  String? _errorKey;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: .sm,
      children: [
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
          obscureText: true,
          enabled: !_isSubmitting,
        ),
        if (_errorKey case final errorKey?)
          AuraText(
            style: AuraTextStyle.bodySmall,
            child: TextLocale(errorKey),
          ),
        AuraButton(
          onPressed: _login,
          child: const TextLocale(LocaleKeys.workspace_management_cloud_login),
          isLoading: _isSubmitting,
          disabled: _isSubmitting,
        ),
      ],
    );
  }

  Future<void> _login() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorKey = null;
    });

    try {
      await cloudAccountMutation.run(ref, (_) async {
        final account = await ref
            .read(cloudAccountUseCasesProvider)
            .login(
              email: _email.text.trim(),
              password: _password.text,
            );
        ref.invalidate(cloudAccountsProvider);
        widget.onSignedIn(account);
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorKey = cloudAccountErrorKey(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

String cloudAccountErrorKey(Object error) {
  final message = error.toString();
  if (message.contains('SocketException') ||
      message.contains('Connection refused') ||
      message.contains('Failed host lookup') ||
      message.contains('server is not configured')) {
    return LocaleKeys.cloud_accounts_server_unreachable_error;
  }
  if (message.contains('Unauthorized') ||
      message.contains('unauthorized') ||
      message.contains('invalid') ||
      message.contains('authentication')) {
    return LocaleKeys.cloud_accounts_login_failed_error;
  }

  return LocaleKeys.cloud_accounts_request_failed;
}
