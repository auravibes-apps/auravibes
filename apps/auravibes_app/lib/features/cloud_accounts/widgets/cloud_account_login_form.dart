// ignore_for_file: type=lint

import 'dart:async' show unawaited;

import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_failure.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_target.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_management_mode.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const CloudAccountLoginForm({
  required final ValueChanged<CloudAccountSession> onSignedIn,
  final CloudAuthTarget target = const CloudAuthTarget(),
  final ValueChanged<bool>? onPendingChanged,
  final ValueChanged<String>? onEmailChanged,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<CloudAccountLoginForm> createState() =>
      _CloudAccountLoginFormState();
}

class _CloudAccountLoginFormState extends ConsumerState<CloudAccountLoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _isSubmitting = false;
  String? _errorKey;

  var _epoch = 0;
  String? _statusKey;

  @override
  void initState() {
    super.initState();
    _email.text = widget.target.email ?? '';
  }

  @override
  void didUpdateWidget(covariant CloudAccountLoginForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target.owner == widget.target.owner) return;
    _epoch++;
    _email.text = widget.target.email ?? '';
    _password.clear();

    _errorKey = null;
    _statusKey = null;
    _isSubmitting = false;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
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
          obscureText: true,
          textInputAction: .done,
          onSubmitted: (_) => _login(),
          enabled: !_isSubmitting,
        ),
        if (_statusKey case final statusKey?)
          Semantics(liveRegion: true, child: TextLocale(statusKey)),
        if (_errorKey case final errorKey?)
          AuraText(child: TextLocale(errorKey), style: AuraTextStyle.bodySmall),
        AuraButton(
          onPressed: _login,
          child: const TextLocale(LocaleKeys.workspace_management_cloud_login),
          isLoading: _isSubmitting,
          disabled: _isSubmitting,
        ),
      ],
      spacing: .sm,
      crossAxisAlignment: CrossAxisAlignment.stretch,
    );
  }

  Future<void> _login() async {
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
      await WorkspaceManagementMutations.cloudAccount.run(ref, (_) async {
        final account = await ref
            .read(cloudAccountUseCasesProvider)
            .login(
              email: _email.text.trim(),
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
      setState(() => _errorKey = cloudAccountErrorKey(error));
    } finally {
      if (mounted && epoch == _epoch) {
        setState(() => _isSubmitting = false);
        widget.onPendingChanged?.call(false);
      }
    }
  }
}

String cloudAccountErrorKey(Object error) => CloudAuthFailure.key(error);
