import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_mode.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_target.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_forgot_password_form.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_login_form.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_register_form.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// Callback-owned content usable before a workspace exists. Owns secrets only.
class CloudAccountAuthContent extends StatefulWidget {
  const new({
    required this.onSignedIn,
    required this.onCancel,
    this.target = const CloudAuthTarget(),
    this.initialMode = .login,
    this.onModeChanged,
    this.passwordChanged = false,
    this.returnTaskLabel = '',
    super.key,
  });
  final CloudAuthTarget target;
  final CloudAuthMode initialMode;
  final bool passwordChanged;
  final String returnTaskLabel;
  final ValueChanged<CloudAccountSession> onSignedIn;
  final VoidCallback onCancel;
  final ValueChanged<CloudAuthNavigation>? onModeChanged;
  @override
  State<CloudAccountAuthContent> createState() =>
      _CloudAccountAuthContentState();
}

class _CloudAccountAuthContentState extends State<CloudAccountAuthContent> {
  CloudAuthMode? _mode;
  String? _email;
  String? _modeEmail;
  var _pending = false;
  var _code = false;
  var _passwordChanged = false;
  @override
  void didUpdateWidget(covariant CloudAccountAuthContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target.owner == widget.target.owner &&
        oldWidget.initialMode == widget.initialMode) {
      return;
    }
    _mode = null;
    _email = null;
    _modeEmail = null;
    _pending = false;
    _code = false;
    _passwordChanged = false;
  }

  @override
  Widget build(BuildContext context) {
    final mode = _mode ?? widget.initialMode;
    final target = CloudAuthTarget(
      serverUrl: widget.target.serverUrl,
      accountId: widget.target.accountId,
      email: _mode == null ? widget.target.email : _modeEmail,
      isValid: widget.target.isValid,
    );
    final title = _code
        ? LocaleKeys.cloud_accounts_verify_email
        : switch (mode) {
            .login => LocaleKeys.workspace_management_cloud_login,
            .register => LocaleKeys.cloud_accounts_create_title,
            .forgotPassword => LocaleKeys.cloud_accounts_forgot_password,
          };
    if (!target.isValid) {
      return AuraColumn(
        children: [
          const TextLocale(LocaleKeys.cloud_accounts_invalid_target),
          AuraButton(
            onPressed: widget.onCancel,
            child: const TextLocale(LocaleKeys.cloud_accounts_cancel_auth),
          ),
        ],
      );
    }

    return AuraColumn(
      children: [
        AuraText(child: TextLocale(title), style: .heading3),
        if (target.configuredOrigin case final origin?)
          Text(origin)
        else
          const TextLocale(LocaleKeys.cloud_accounts_not_configured),
        if (mode == .login && (_passwordChanged || widget.passwordChanged))
          const TextLocale(LocaleKeys.cloud_accounts_password_changed),
        switch (mode) {
          .login => CloudAccountLoginForm(
            onSignedIn: widget.onSignedIn,
            target: target,
            onPendingChanged: _pendingChanged,
            onEmailChanged: (value) => _email = value,
            key: ValueKey((owner: target.owner, mode: mode)),
          ),
          .register => CloudAccountRegisterForm(
            onSignedIn: widget.onSignedIn,
            target: target,
            onPendingChanged: _pendingChanged,
            onEmailChanged: (value) => _email = value,
            onCodeStepChanged: _codeChanged,
            key: ValueKey((owner: target.owner, mode: mode)),
          ),
          .forgotPassword => CloudAccountForgotPasswordForm(
            onFinished: () => _change(.login, passwordChanged: true),
            target: target,
            onPendingChanged: _pendingChanged,
            onEmailChanged: (value) => _email = value,
            onCodeStepChanged: _codeChanged,
            key: ValueKey((owner: target.owner, mode: mode)),
          ),
        },
        if (mode != .login)
          AuraButton(
            onPressed: () => _change(.login),
            child: const TextLocale(LocaleKeys.cloud_accounts_login_existing),
            variant: .outlined,
            disabled: _pending,
          ),
        if (mode == .login) ...[
          const TextLocale(LocaleKeys.cloud_accounts_add_body),
          if (widget.returnTaskLabel.isNotEmpty)
            TextLocale(
              LocaleKeys.cloud_accounts_return_to_task,
              args: [widget.returnTaskLabel],
            )
          else
            const TextLocale(LocaleKeys.cloud_accounts_return_hint),
          AuraButton(
            onPressed: () => _change(.register),
            child: const TextLocale(LocaleKeys.cloud_accounts_create_new),
            variant: .outlined,
            disabled: _pending,
          ),
          AuraButton(
            onPressed: () => _change(.forgotPassword),
            child: const TextLocale(LocaleKeys.cloud_accounts_forgot_password),
            variant: .outlined,
            disabled: _pending,
          ),
        ],
        AuraButton(
          onPressed: widget.onCancel,
          child: const TextLocale(LocaleKeys.cloud_accounts_cancel_auth),
          variant: .outlined,
          disabled: _pending,
        ),
      ],
      spacing: .sm,
      crossAxisAlignment: .stretch,
    );
  }

  void _change(CloudAuthMode mode, {bool passwordChanged = false}) {
    final email = _email ?? widget.target.email ?? '';
    setState(() {
      _mode = mode;
      _modeEmail = email.isEmpty ? null : email;
      _code = false;
      _passwordChanged = passwordChanged;
    });
    widget.onModeChanged?.call((
      mode: mode,
      email: email,
      passwordChanged: passwordChanged,
    ));
  }

  void _pendingChanged(bool value) => setState(() => _pending = value);
  void _codeChanged(bool value) => setState(() => _code = value);
}
