import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_mode.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_target.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_forgot_password_form.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_login_form.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_register_form.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/setup_page_frame.dart';
import 'package:auravibes_app/widgets/setup_page_transition.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

typedef _CloudAuthContentViewData = ({
  _CloudAuthPresentation presentation,
  _CloudAuthContentCallbacks callbacks,
  bool pending,
  String returnTaskLabel,
});

typedef _CloudAuthPresentation = ({
  CloudAuthMode mode,
  CloudAuthTarget target,
  String title,
  bool showPasswordChanged,
});

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
    this.pageBuilder,
    this.onPendingChanged,
    super.key,
  });
  final CloudAuthTarget target;
  final CloudAuthMode initialMode;
  final bool passwordChanged;
  final String returnTaskLabel;
  final ValueChanged<CloudAccountSession> onSignedIn;
  final VoidCallback onCancel;
  final ValueChanged<CloudAuthNavigation>? onModeChanged;
  final SetupPageBuilder? pageBuilder;
  final ValueChanged<bool>? onPendingChanged;
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
  var _reverse = false;
  SetupPageBuilder? get _pageBuilder {
    final builder = widget.pageBuilder;
    if (builder == null) return null;

    return (page) => SetupPageTransition(child: builder(page));
  }

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
    final builder = widget.pageBuilder;
    final layout = _CloudAccountAuthLayout(
      data: _cloudAuthContentViewData(this, widget),
      pageBuilder: _pageBuilder,
    );
    if (builder == null) return layout;

    return SetupPageTransition(
      child: KeyedSubtree(
        key: ValueKey(_mode ?? widget.initialMode),
        child: layout,
      ),
      reverse: _reverse,
    );
  }

  String _title(CloudAuthMode mode) => switch (mode) {
    .forgotPassword when _code =>
      LocaleKeys.cloud_accounts_finish_password_reset,
    _ when _code => LocaleKeys.cloud_accounts_verify_email,
    .login => LocaleKeys.workspace_management_cloud_login,
    .register => LocaleKeys.cloud_accounts_create_title,
    .forgotPassword => LocaleKeys.cloud_accounts_forgot_password,
  };

  void _change(CloudAuthMode mode, {bool passwordChanged = false}) {
    if (_pending && !passwordChanged) return;
    _applyCloudAuthModeChange(this, widget, (
      mode: mode,
      email: _effectiveEmail(_email, widget.target.email),
      passwordChanged: passwordChanged,
    ));
  }

  void _updateMode(CloudAuthMode mode, String email, bool passwordChanged) {
    setState(() => _setMode(mode, email, passwordChanged));
    if (passwordChanged) widget.onPendingChanged?.call(false);
  }

  void _setMode(CloudAuthMode mode, String email, bool passwordChanged) {
    _reverse = mode == .login;
    _mode = mode;
    _modeEmail = email.isEmpty ? null : email;
    _code = false;
    _passwordChanged = passwordChanged;
    if (passwordChanged) _pending = false;
  }

  void _pendingChanged(bool value) {
    if (!mounted) return;
    setState(() => _pending = value);
    widget.onPendingChanged?.call(value);
  }

  void _codeChanged(bool value) => setState(() => _code = value);
}

typedef _CloudAuthModeChange = ({
  CloudAuthMode mode,
  String email,
  bool passwordChanged,
});

_CloudAuthContentViewData _cloudAuthContentViewData(
  _CloudAccountAuthContentState state,
  CloudAccountAuthContent widget,
) {
  return (
    presentation: _cloudAuthPresentation(state, widget),
    callbacks: _cloudAuthContentCallbacks(state, widget),
    pending: state._pending,
    returnTaskLabel: widget.returnTaskLabel,
  );
}

_CloudAuthPresentation _cloudAuthPresentation(
  _CloudAccountAuthContentState state,
  CloudAccountAuthContent widget,
) {
  final mode = state._mode ?? widget.initialMode;

  return (
    mode: mode,
    target: _viewTarget(widget.target, state._mode, state._modeEmail),
    title: state._title(mode),
    showPasswordChanged:
        mode == .login && (state._passwordChanged || widget.passwordChanged),
  );
}

typedef _CloudAuthContentCallbacks = ({
  ValueChanged<CloudAccountSession> onSignedIn,
  VoidCallback onCancel,
  ValueChanged<bool> onPendingChanged,
  ValueChanged<String> onEmailChanged,
  ValueChanged<bool> onCodeChanged,
  void Function(CloudAuthMode, {bool passwordChanged}) onChange,
});

_CloudAuthContentCallbacks _cloudAuthContentCallbacks(
  _CloudAccountAuthContentState state,
  CloudAccountAuthContent widget,
) => (
  onSignedIn: widget.onSignedIn,
  onCancel: widget.onCancel,
  onPendingChanged: state._pendingChanged,
  onEmailChanged: (String value) => state._email = value,
  onCodeChanged: state._codeChanged,
  onChange: state._change,
);

void _applyCloudAuthModeChange(
  _CloudAccountAuthContentState state,
  CloudAccountAuthContent widget,
  _CloudAuthModeChange change,
) {
  state._updateMode(change.mode, change.email, change.passwordChanged);
  widget.onModeChanged?.call(change);
}

CloudAuthTarget _viewTarget(
  CloudAuthTarget target,
  CloudAuthMode? mode,
  String? modeEmail,
) => CloudAuthTarget(
  serverUrl: target.serverUrl,
  accountId: target.accountId,
  email: mode == null ? target.email : modeEmail,
  isValid: target.isValid,
);

String _effectiveEmail(String? currentEmail, String? targetEmail) =>
    currentEmail ?? targetEmail ?? '';

class _CloudAccountAuthLayout extends StatelessWidget {
  new({required _CloudAuthContentViewData data, SetupPageBuilder? pageBuilder})
    : _child = !data.presentation.target.isValid
          ? _CloudAuthUnavailable(data: data, pageBuilder: pageBuilder)
          : switch (pageBuilder) {
              final builder? => _CloudAuthEmbeddedForm(
                data: data,
                pageBuilder: builder,
              ),
              null => AuraColumn(
                children: [
                  _CloudAccountAuthHeader(data: data),
                  _CloudAccountAuthForm(data: data),
                  _CloudAccountAuthModeActions(data: data),
                  _CloudAuthCancelButton(data: data),
                ],
                spacing: .sm,
                crossAxisAlignment: .stretch,
              ),
            };
  final Widget _child;
  @override
  Widget build(BuildContext context) => _child;
}

class const _CloudAuthUnavailable({
  required final _CloudAuthContentViewData data,
  final SetupPageBuilder? pageBuilder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final builder = pageBuilder;
    if (builder == null) {
      return _InvalidCloudAccountAuthTarget(onCancel: data.callbacks.onCancel);
    }

    return builder(
      .new(
        key: const Key('intro_cloud_auth_unavailable'),
        heading: const AuraText(
          child: TextLocale('workspace_management.cloud_login'),
          style: .heading4,
        ),
        body: const TextLocale('cloud_accounts.not_configured'),
        actions: _CloudAuthCancelButton(data: data),
        pending: data.pending,
      ),
    );
  }
}

class const _CloudAuthEmbeddedForm({
  required final _CloudAuthContentViewData data,
  required final SetupPageBuilder pageBuilder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _CloudAccountAuthForm(data: data, contentBuilder: _content);

  Widget _content(Widget fields, Widget action) => pageBuilder(
    .new(
      key: ValueKey(data.presentation.title),
      heading: _CloudAuthTaskHeading(title: data.presentation.title),
      description: _CloudAuthLoginIntro(returnTaskLabel: data.returnTaskLabel),
      body: _CloudAuthEmbeddedBody(data: data, fields: fields),
      actions: _CloudAuthEmbeddedActions(data: data, action: action),
      pending: data.pending,
    ),
  );
}

class const _CloudAuthEmbeddedBody({
  required final _CloudAuthContentViewData data,
  required final Widget fields,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _CloudAuthHeaderDetails(presentation: data.presentation),
      fields,
      _CloudAccountAuthModeActions(data: data),
    ],
    spacing: .md,
    crossAxisAlignment: .stretch,
  );
}

class const _CloudAuthEmbeddedActions({
  required final _CloudAuthContentViewData data,
  required final Widget action,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      action,
      _CloudAuthCancelButton(data: data),
    ],
    spacing: .sm,
    crossAxisAlignment: .stretch,
  );
}

class const _CloudAccountAuthHeader({
  required final _CloudAuthContentViewData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraText(child: TextLocale(data.presentation.title), style: .heading3),
      _CloudAuthHeaderDetails(presentation: data.presentation),
      _CloudAuthLoginIntro(returnTaskLabel: data.returnTaskLabel),
    ],
    spacing: .sm,
    crossAxisAlignment: .stretch,
  );
}

class const _CloudAuthHeaderDetails({
  required final _CloudAuthPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final configuredOrigin = presentation.target.configuredOrigin;

    return AuraColumn(
      children: [
        if (configuredOrigin case final origin?)
          AuraText(child: Text(origin), style: .caption)
        else
          const TextLocale(LocaleKeys.cloud_accounts_not_configured),
        if (presentation.showPasswordChanged)
          const TextLocale(LocaleKeys.cloud_accounts_password_changed),
      ],
      spacing: .sm,
      crossAxisAlignment: .stretch,
    );
  }
}

class const _CloudAccountAuthForm({
  required final _CloudAuthContentViewData data,
  final SetupFormBuilder? contentBuilder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _CloudAuthModeForm(request: _cloudAuthFormRequest(data, contentBuilder));
}

typedef _CloudAuthFormRequest = ({
  CloudAuthMode mode,
  CloudAuthTarget target,
  _CloudAuthFormCallbacks callbacks,
  Key key,
  SetupFormBuilder? contentBuilder,
});

_CloudAuthFormRequest _cloudAuthFormRequest(
  _CloudAuthContentViewData data,
  SetupFormBuilder? contentBuilder,
) {
  final target = data.presentation.target;
  final mode = data.presentation.mode;

  return (
    mode: mode,
    target: target,
    callbacks: _CloudAuthFormCallbacks(data.callbacks),
    key: ValueKey((owner: target.owner, mode: mode)),
    contentBuilder: contentBuilder,
  );
}

class const _CloudAuthModeForm({required final _CloudAuthFormRequest request})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (request.mode) {
    .login => _CloudAccountLoginFormView(request: request),
    .register => _CloudAccountRegisterFormView(request: request),
    .forgotPassword => _CloudAccountForgotPasswordFormView(request: request),
  };
}

class const _CloudAccountLoginFormView({
  required final _CloudAuthFormRequest request,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final callbacks = request.callbacks;

    return CloudAccountLoginForm(
      onSignedIn: callbacks.onSignedIn,
      target: request.target,
      onPendingChanged: callbacks.onPendingChanged,
      onEmailChanged: callbacks.onEmailChanged,
      contentBuilder: request.contentBuilder,
      key: request.key,
    );
  }
}

class const _CloudAccountRegisterFormView({
  required final _CloudAuthFormRequest request,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final callbacks = request.callbacks;

    return CloudAccountRegisterForm(
      onSignedIn: callbacks.onSignedIn,
      target: request.target,
      onPendingChanged: callbacks.onPendingChanged,
      onEmailChanged: callbacks.onEmailChanged,
      contentBuilder: request.contentBuilder,
      onCodeStepChanged: callbacks.onCodeChanged,
      key: request.key,
    );
  }
}

class const _CloudAccountForgotPasswordFormView({
  required final _CloudAuthFormRequest request,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final callbacks = request.callbacks;

    return CloudAccountForgotPasswordForm(
      onFinished: callbacks.onForgotPasswordFinished,
      target: request.target,
      onPendingChanged: callbacks.onPendingChanged,
      onEmailChanged: callbacks.onEmailChanged,
      contentBuilder: request.contentBuilder,
      onCodeStepChanged: callbacks.onCodeChanged,
      key: request.key,
    );
  }
}

class _CloudAuthFormCallbacks {
  new(_CloudAuthContentCallbacks callbacks)
    : onSignedIn = callbacks.onSignedIn,
      onPendingChanged = callbacks.onPendingChanged,
      onEmailChanged = callbacks.onEmailChanged,
      onCodeChanged = callbacks.onCodeChanged,
      onForgotPasswordFinished = _cloudAuthForgotPasswordFinished(
        callbacks.onChange,
      );

  final ValueChanged<CloudAccountSession> onSignedIn;
  final ValueChanged<bool> onPendingChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<bool> onCodeChanged;
  final VoidCallback onForgotPasswordFinished;
}

VoidCallback _cloudAuthForgotPasswordFinished(
  void Function(CloudAuthMode, {bool passwordChanged}) onChange,
) =>
    () => onChange(.login, passwordChanged: true);

class const _CloudAccountAuthModeActions({
  required final _CloudAuthContentViewData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _ExistingCloudAccountLogin(
        visible: data.presentation.mode != .login,
        pending: data.pending,
        onChange: data.callbacks.onChange,
      ),
      _CloudAuthLoginActionGroup(
        visible: data.presentation.mode == .login,
        data: data,
      ),
    ],
    spacing: .sm,
    crossAxisAlignment: .stretch,
  );
}

class const _ExistingCloudAccountLogin({
  required final bool visible,
  required final bool pending,
  required final void Function(CloudAuthMode, {bool passwordChanged}) onChange,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => visible
      ? AuraButton(
          onPressed: _cloudAuthLoginAction(onChange),
          child: const TextLocale(LocaleKeys.cloud_accounts_login_existing),
          variant: .outlined,
          disabled: pending,
        )
      : const SizedBox.shrink();
}

class const _CloudAuthLoginActionGroup({
  required final bool visible,
  required final _CloudAuthContentViewData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      visible ? _CloudAuthLoginButtons(data: data) : const SizedBox.shrink();
}

class const _CloudAuthLoginIntro({required final String returnTaskLabel})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const TextLocale(LocaleKeys.cloud_accounts_add_body),
      if (returnTaskLabel.isNotEmpty)
        TextLocale(
          LocaleKeys.cloud_accounts_return_to_task,
          args: [returnTaskLabel],
        )
      else
        const TextLocale(LocaleKeys.cloud_accounts_return_hint),
    ],
    spacing: .sm,
    crossAxisAlignment: .stretch,
  );
}

class const _CloudAuthLoginButtons({
  required final _CloudAuthContentViewData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onChange = data.callbacks.onChange;
    final pending = data.pending;

    return AuraColumn(
      children: [
        _CloudAuthModeButton(
          onChange: onChange,
          mode: .register,
          label: LocaleKeys.cloud_accounts_create_new,
          pending: pending,
        ),
        _CloudAuthModeButton(
          onChange: onChange,
          mode: .forgotPassword,
          label: LocaleKeys.cloud_accounts_forgot_password,
          pending: pending,
        ),
      ],
      spacing: .sm,
      crossAxisAlignment: .stretch,
    );
  }
}

class const _CloudAuthModeButton({
  required final void Function(CloudAuthMode, {bool passwordChanged}) onChange,
  required final CloudAuthMode mode,
  required final String label,
  required final bool pending,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: _cloudAuthLoginAction(onChange, mode),
    child: TextLocale(label),
    variant: .ghost,
    disabled: pending,
  );
}

VoidCallback _cloudAuthLoginAction(
  void Function(CloudAuthMode, {bool passwordChanged}) onChange, [
  CloudAuthMode mode = .login,
]) =>
    () => onChange(mode);

class const _CloudAuthCancelButton({
  required final _CloudAuthContentViewData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: data.callbacks.onCancel,
    child: const TextLocale(LocaleKeys.cloud_accounts_cancel_auth),
    variant: .ghost,
    disabled: data.pending,
  );
}

class const _InvalidCloudAccountAuthTarget({
  required final VoidCallback onCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const TextLocale(LocaleKeys.cloud_accounts_invalid_target),
      AuraButton(
        onPressed: onCancel,
        child: const TextLocale(LocaleKeys.cloud_accounts_cancel_auth),
      ),
    ],
  );
}

class const _CloudAuthTaskHeading({required final String title})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraText(child: TextLocale(title), style: .heading4);
}
