// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/widgets/enhanced_model_input.dart';
import 'package:auravibes_app/features/models/widgets/model_logo.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/codex_oauth_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_app/utils/open_system_browser.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/experimental/mutation.dart';

const String _oauthWaitingKey =
    LocaleKeys.models_screens_add_provider_oauth_waiting;
const String _cancelConnectionKey =
    LocaleKeys.models_screens_add_provider_cancel_connection;

class const AddModelProviderWidget({
  required final String workspaceId,
  super.key,
  final VoidCallback? onCreated,
  final VoidCallback? onCancel,
  final bool showHeader = true,
}) extends HookConsumerWidget {
  // Extract long locale key to avoid line length issues.
  static const String noModelsFoundKey =
      LocaleKeys.models_screens_add_provider_search_no_models_found;

  @override
  Widget build(BuildContext context, WidgetRef _) => _AddModelProviderContent(
    workspaceId: workspaceId,
    showHeader: showHeader,
    onCreated: onCreated,
    onCancel: onCancel,
  );
}

class const _AddModelProviderContent({
  required final String workspaceId,
  required final bool showHeader,
  final VoidCallback? onCreated,
  final VoidCallback? onCancel,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = _useAddModelProviderRuntime(ref, workspaceId);
    final session = ref.watch(workspaceSessionForRouteProvider(workspaceId));

    return _AddModelProviderContentView(
      runtime: runtime,
      session: session,
      context: context,
      ref: ref,
      workspaceId: workspaceId,
      showHeader: showHeader,
      onCreated: onCreated,
      onCancel: onCancel,
    );
  }
}

class const _AddModelProviderContentView({
  required final _AddModelProviderRuntime runtime,
  required final AsyncValue<WorkspaceSession> session,
  required final BuildContext context,
  required final WidgetRef ref,
  required final String workspaceId,
  required final bool showHeader,
  final VoidCallback? onCreated,
  final VoidCallback? onCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => runtime.selection.hasModel
      ? _AddModelProviderSessionContent(
          session: session,
          context: context,
          ref: ref,
          runtime: runtime,
          workspaceId: workspaceId,
          showHeader: showHeader,
          onCreated: onCreated,
          onCancel: onCancel,
        )
      : _SelectModelProvider(workspaceId: workspaceId);
}

class const _AddModelProviderSessionContent({
  required final AsyncValue<WorkspaceSession> session,
  required final BuildContext context,
  required final WidgetRef ref,
  required final _AddModelProviderRuntime runtime,
  required final String workspaceId,
  required final bool showHeader,
  final VoidCallback? onCreated,
  final VoidCallback? onCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => switch (session) {
    AsyncLoading() || AsyncError() => const Center(child: AuraSpinner()),
    AsyncData(:final value) => _AddModelProviderForm(
      data: _addModelProviderFormData(_request(value)),
    ),
  };

  _AddModelProviderFormRequest _request(WorkspaceSession value) => (
    context: context,
    ref: ref,
    runtime: runtime,
    capabilities: value.capabilities,
    workspaceId: workspaceId,
    showHeader: showHeader,
    onCreated: onCreated,
    onCancel: onCancel,
  );
}

typedef _AddModelProviderFormRequest = ({
  BuildContext context,
  WidgetRef ref,
  _AddModelProviderRuntime runtime,
  WorkspaceCapabilities capabilities,
  String workspaceId,
  bool showHeader,
  VoidCallback? onCreated,
  VoidCallback? onCancel,
});

typedef _AddModelProviderSubmission = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  VoidCallback? onCreated,
  CodexOAuthMethod? codexOAuthMethod,
  void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
  bool Function()? isCodexOAuthCancelled,
});

typedef _ModelProviderMutationRequest = ({
  WidgetRef ref,
  String workspaceId,
  CodexOAuthMethod? codexOAuthMethod,
  void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
  bool Function()? isCodexOAuthCancelled,
});

typedef _CodexOAuthState = ({
  ValueNotifier<CodexDeviceCode?> deviceCode,
  ValueNotifier<CodexOAuthMethod?> activeOAuthMethod,
  ObjectRef<_CodexOAuthCancellation?> cancellationRef,
});

typedef _CodexOAuthSubmission = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  VoidCallback? onCreated,
  _CodexOAuthState state,
  CodexOAuthMethod method,
});

typedef _CodexDeviceCodeUpdate = ({
  BuildContext context,
  _CodexOAuthState state,
  _CodexOAuthCancellation cancellation,
  CodexDeviceCode value,
});

_AddModelProviderFormData _addModelProviderFormData(
  _AddModelProviderFormRequest request,
) {
  final runtime = request.runtime;
  final state = _codexOAuthState(runtime);

  return _AddModelProviderFormData(
    values: _addModelProviderFormValues(request, state),
    callbacks: _addModelProviderFormCallbacks(request, state),
  );
}

_AddModelProviderFormValues _addModelProviderFormValues(
  _AddModelProviderFormRequest request,
  _CodexOAuthState state,
) {
  return _AddModelProviderFormValues(request: request, state: state);
}

_AddModelProviderFormCallbacks _addModelProviderFormCallbacks(
  _AddModelProviderFormRequest request,
  _CodexOAuthState state,
) => _AddModelProviderFormCallbacks(
  onClose: request.onCancel ?? _closeModelProviderForm(request.context),
  onSubmit: _addModelProviderSubmitCallback(request),
  onCancelCodexOAuth: () => _cancelCodexOAuth(state),
  onCodexBrowserSubmit: _addModelProviderBrowserCallback(request, state),
  onCodexDeviceSubmit: _addModelProviderDeviceCallback(request, state),
);

VoidCallback _closeModelProviderForm(BuildContext context) =>
    () => Navigator.of(context).pop();

VoidCallback _addModelProviderSubmitCallback(
  _AddModelProviderFormRequest request,
) =>
    () => unawaited(
      _submitAddModelProviderForm(_modelProviderSubmission(request)),
    );

_AddModelProviderSubmission _modelProviderSubmission(
  _AddModelProviderFormRequest request,
) => (
  context: request.context,
  ref: request.ref,
  workspaceId: request.workspaceId,
  onCreated: request.onCreated,
  codexOAuthMethod: null,
  onCodexDeviceCode: null,
  isCodexOAuthCancelled: null,
);

VoidCallback _addModelProviderBrowserCallback(
  _AddModelProviderFormRequest request,
  _CodexOAuthState state,
) =>
    () => _submitCodexBrowser((
      context: request.context,
      ref: request.ref,
      workspaceId: request.workspaceId,
      onCreated: request.onCreated,
      state: state,
      method: .browser,
    ));

VoidCallback _addModelProviderDeviceCallback(
  _AddModelProviderFormRequest request,
  _CodexOAuthState state,
) =>
    () => _submitCodexDevice((
      context: request.context,
      ref: request.ref,
      workspaceId: request.workspaceId,
      onCreated: request.onCreated,
      state: state,
      method: .deviceCode,
    ));

_CodexOAuthState _codexOAuthState(_AddModelProviderRuntime runtime) {
  final controls = runtime.controls;

  return (
    deviceCode: controls.codexDeviceCode,
    activeOAuthMethod: controls.activeCodexOAuthMethod,
    cancellationRef: controls.codexOAuthCancellation,
  );
}

Future<void> _submitAddModelProviderForm(
  _AddModelProviderSubmission request,
) async {
  try {
    await _submitAddModelProviderFormRequest(request);
  } on Object {
    // Mutation state renders the mapped failure in _ErrorBanner.
  }
}

Future<void> _submitAddModelProviderFormRequest(
  _AddModelProviderSubmission request,
) async {
  final created = await _runModelProviderMutation(
    _modelProviderMutationRequest(request),
  );
  if (!request.context.mounted || created == null) return;

  _completeAddModelProviderSubmission(
    request.context,
    request.onCreated,
    created,
  );
}

_ModelProviderMutationRequest _modelProviderMutationRequest(
  _AddModelProviderSubmission request,
) => (
  ref: request.ref,
  workspaceId: request.workspaceId,
  codexOAuthMethod: request.codexOAuthMethod,
  onCodexDeviceCode: request.onCodexDeviceCode,
  isCodexOAuthCancelled: request.isCodexOAuthCancelled,
);

void _completeAddModelProviderSubmission(
  BuildContext context,
  VoidCallback? onCreated,
  ModelConnectionEntity created,
) {
  if (onCreated case final callback?) {
    callback();

    return;
  }

  Navigator.of(context).pop(created);
}

void _submitCodexBrowser(_CodexOAuthSubmission request) {
  final cancellation = _beginCodexOAuth(request.state, request.method);
  unawaited(
    _submitAddModelProviderForm(_codexBrowserSubmission(request, cancellation)),
  );
}

_AddModelProviderSubmission _codexBrowserSubmission(
  _CodexOAuthSubmission request,
  _CodexOAuthCancellation cancellation,
) => (
  context: request.context,
  ref: request.ref,
  workspaceId: request.workspaceId,
  onCreated: request.onCreated,
  codexOAuthMethod: request.method,
  onCodexDeviceCode: null,
  isCodexOAuthCancelled: () => cancellation.isCancelled,
);

void _submitCodexDevice(_CodexOAuthSubmission request) {
  final cancellation = _beginCodexOAuth(request.state, request.method);
  unawaited(
    _submitAddModelProviderForm(_codexDeviceSubmission(request, cancellation)),
  );
}

_AddModelProviderSubmission _codexDeviceSubmission(
  _CodexOAuthSubmission request,
  _CodexOAuthCancellation cancellation,
) => (
  context: request.context,
  ref: request.ref,
  workspaceId: request.workspaceId,
  onCreated: request.onCreated,
  codexOAuthMethod: request.method,
  onCodexDeviceCode: _codexDeviceCodeCallback(request, cancellation),
  isCodexOAuthCancelled: () => cancellation.isCancelled,
);

void Function(CodexDeviceCode) _codexDeviceCodeCallback(
  _CodexOAuthSubmission request,
  _CodexOAuthCancellation cancellation,
) =>
    (value) => _updateCodexDeviceCode((
      context: request.context,
      state: request.state,
      cancellation: cancellation,
      value: value,
    ));

_CodexOAuthCancellation _beginCodexOAuth(
  _CodexOAuthState state,
  CodexOAuthMethod method,
) {
  final cancellation = _CodexOAuthCancellation();
  state.cancellationRef.value = cancellation;
  state.activeOAuthMethod.value = method;
  state.deviceCode.value = null;

  return cancellation;
}

void _updateCodexDeviceCode(_CodexDeviceCodeUpdate update) {
  if (!update.context.mounted ||
      update.cancellation.isCancelled ||
      !identical(update.state.cancellationRef.value, update.cancellation)) {
    return;
  }

  update.state.deviceCode.value = update.value;
}

void _cancelCodexOAuth(_CodexOAuthState state) {
  state.cancellationRef.value?.cancel();
  state.cancellationRef.value = null;
  state.deviceCode.value = null;
  state.activeOAuthMethod.value = null;
}

class const _AddModelProviderSelection({
  required final bool hasModel,
  required final ModelProviderAuthMode authMode,
  required final String? modelId,
  required final bool isCodex,
  required final bool isOAuth,
});

typedef _SelectedModelProviderState = ({
  bool hasModel,
  ModelProviderAuthMode authMode,
  String? modelId,
});

typedef _AddModelProviderControls = ({
  ScrollController scrollController,
  GlobalKey<FormState> formKey,
  ValueNotifier<CodexDeviceCode?> codexDeviceCode,
  ValueNotifier<CodexOAuthMethod?> activeCodexOAuthMethod,
  ObjectRef<_CodexOAuthCancellation?> codexOAuthCancellation,
  bool isSubmitting,
  bool isDesktop,
});

typedef _AddModelProviderRuntime = ({
  _AddModelProviderControls controls,
  _AddModelProviderSelection selection,
});

_AddModelProviderRuntime _useAddModelProviderRuntime(
  WidgetRef ref,
  String workspaceId,
) {
  final selected = _watchSelectedModelProvider(ref, workspaceId);
  final controls = _useAddModelProviderControls(ref);

  return (controls: controls, selection: _addModelProviderSelection(selected));
}

_AddModelProviderSelection _addModelProviderSelection(
  _SelectedModelProviderState selected,
) => _AddModelProviderSelection(
  hasModel: selected.hasModel,
  authMode: selected.authMode,
  modelId: selected.modelId,
  isCodex: ModelProviderOAuthProfiles.isCodexProvider(selected.modelId),
  isOAuth: selected.authMode == ModelProviderAuthMode.oauth2,
);

_SelectedModelProviderState _watchSelectedModelProvider(
  WidgetRef ref,
  String workspaceId,
) => ref.watch(
  addModelProviderStateProvider(workspaceId).select(
    (value) => (
      hasModel: value.modelId != null,
      authMode: value.authMode,
      modelId: value.modelId,
    ),
  ),
);

_AddModelProviderControls _useAddModelProviderControls(WidgetRef ref) {
  final codex = _useCodexOAuthControls();

  return (
    scrollController: useScrollController(),
    formKey: useMemoized(GlobalKey<FormState>.new, []),
    codexDeviceCode: codex.deviceCode,
    activeCodexOAuthMethod: codex.activeOAuthMethod,
    codexOAuthCancellation: codex.cancellationRef,
    isSubmitting: _watchModelProviderSubmission(ref),
    isDesktop: _isDesktopPlatform(),
  );
}

typedef _CodexOAuthControls = ({
  ValueNotifier<CodexDeviceCode?> deviceCode,
  ValueNotifier<CodexOAuthMethod?> activeOAuthMethod,
  ObjectRef<_CodexOAuthCancellation?> cancellationRef,
});

_CodexOAuthControls _useCodexOAuthControls() => (
  deviceCode: useState<CodexDeviceCode?>(null),
  activeOAuthMethod: useState<CodexOAuthMethod?>(null),
  cancellationRef: useRef<_CodexOAuthCancellation?>(null),
);

bool _watchModelProviderSubmission(WidgetRef ref) => ref.watch(
  addCredentialsModelMutationProvider.select((value) => value.isPending),
);

bool _isDesktopPlatform() =>
    !kIsWeb &&
    const {
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.windows,
    }.contains(defaultTargetPlatform);

class const _AddModelProviderFormData({
  required final _AddModelProviderFormValues values,
  required final _AddModelProviderFormCallbacks callbacks,
});

class const _AddModelProviderFormValues({
  required final _AddModelProviderFormRequest request,
  required final _CodexOAuthState state,
});

class const _AddModelProviderFormCallbacks({
  required final VoidCallback onClose,
  required final VoidCallback onSubmit,
  required final VoidCallback onCancelCodexOAuth,
  required final VoidCallback onCodexBrowserSubmit,
  required final VoidCallback onCodexDeviceSubmit,
});

Future<ModelConnectionEntity?> _runModelProviderMutation(
  _ModelProviderMutationRequest request,
) async {
  ModelConnectionEntity? created;
  await addCredentialsModelMutationProvider.run(request.ref, (
    transaction,
  ) async {
    created = await _addModelProviderFromTransaction(
      transaction,
      request: request,
    );
  });

  return created;
}

Future<ModelConnectionEntity?> _addModelProviderFromTransaction(
  MutationTransaction transaction, {
  required _ModelProviderMutationRequest request,
}) {
  final notifier = transaction.get(
    addModelProviderStateProvider(request.workspaceId).notifier,
  );

  return notifier.addModelProvider(
    codexOAuthMethod: request.codexOAuthMethod,
    onCodexDeviceCode: request.onCodexDeviceCode,
    isCodexOAuthCancelled: request.isCodexOAuthCancelled,
  );
}

class const _AddModelProviderForm({
  required final _AddModelProviderFormData data,
}) extends StatelessWidget {
  _AddModelProviderFormValues get _values => data.values;
  _AddModelProviderFormRequest get _request => _values.request;
  _AddModelProviderFormCallbacks get _callbacks => data.callbacks;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      if (_request.showHeader) _ModalHeader(onClose: _callbacks.onClose),
      _SelectedModelHeader(workspaceId: _request.workspaceId),
      Flexible(child: _AddModelProviderFormScroll(data: data)),
    ],
  );
}

class const _AddModelProviderFormScroll({
  required final _AddModelProviderFormData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final values = data.values;
    final controls = values.request.runtime.controls;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.lg)),
      controller: controls.scrollController,
      child: _AddModelProviderFormBody(data: data),
    );
  }
}

class const _AddModelProviderFormBody({
  required final _AddModelProviderFormData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final values = data.values;
    final formKey = values.request.runtime.controls.formKey;

    return Form(
      key: formKey,
      child: _AddModelProviderFields(values: values, callbacks: data.callbacks),
    );
  }
}

class const _AddModelProviderFields({
  required final _AddModelProviderFormValues values,
  required final _AddModelProviderFormCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        _ModelProviderCredentialFields(
          values: values,
          onSubmit: callbacks.onSubmit,
        ),
        const AuraSizedBox(height: .xl),
        _ModelProviderOAuthFields(values: values, callbacks: callbacks),
      ],
    );
  }
}

class const _ModelProviderCredentialFields({
  required final _AddModelProviderFormValues values,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) =>
      _ModelProviderCredentialFieldsView(values: values, onSubmit: onSubmit);
}

class const _ModelProviderCredentialFieldsView({
  required final _AddModelProviderFormValues values,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Column(
    crossAxisAlignment: .start,
    children: [
      _ModelProviderNameField(workspaceId: values.request.workspaceId),
      _ModelProviderSecretFieldsVisibility(values: values, onSubmit: onSubmit),
    ],
  );
}

class const _ModelProviderSecretFieldsVisibility({
  required final _AddModelProviderFormValues values,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => values.request.runtime.selection.isOAuth
      ? const SizedBox.shrink()
      : _ModelProviderSecretFields(
          workspaceId: values.request.workspaceId,
          onSubmit: onSubmit,
        );
}

class const _ModelProviderNameField({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) =>
      EnhancedModelInput(workspaceId: workspaceId, fieldType: .name);
}

class const _ModelProviderSecretFields({
  required final String workspaceId,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        EnhancedModelInput(workspaceId: workspaceId, fieldType: .key),
        const AuraSizedBox(height: .xl),
        _ApiConfigSection(workspaceId: workspaceId, onSubmit: onSubmit),
      ],
    );
  }
}

class const _ModelProviderOAuthFields({
  required final _AddModelProviderFormValues values,
  required final _AddModelProviderFormCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) =>
      _ModelProviderOAuthFieldsView(values: values, callbacks: callbacks);
}

class const _ModelProviderOAuthFieldsView({
  required final _AddModelProviderFormValues values,
  required final _AddModelProviderFormCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        _CodexDeviceCodeSection(values: values, callbacks: callbacks),
        _CodexOAuthActions(values: values, callbacks: callbacks),
      ],
    );
  }
}

class const _CodexDeviceCodeSection({
  required final _AddModelProviderFormValues values,
  required final _AddModelProviderFormCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final deviceCode = values.state.deviceCode.value;
    if (deviceCode == null) return const SizedBox.shrink();

    return _CodexDeviceCodeContent(
      deviceCode: deviceCode,
      isPending: values.request.runtime.controls.isSubmitting,
      onCancel: callbacks.onCancelCodexOAuth,
    );
  }
}

class const _CodexDeviceCodeContent({
  required final CodexDeviceCode deviceCode,
  required final bool isPending,
  required final VoidCallback onCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Column(
    children: [
      _CodexDeviceCodePanel(
        deviceCode: deviceCode,
        isPending: isPending,
        onCancel: onCancel,
      ),
      const AuraSizedBox(height: .xl),
    ],
  );
}

class const _CodexOAuthActions({
  required final _AddModelProviderFormValues values,
  required final _AddModelProviderFormCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Column(
      children: [
        _CodexCreateAction(values: values, callbacks: callbacks),
        _CodexPendingAction(values: values, callbacks: callbacks),
      ],
    );
  }
}

class const _CodexCreateAction({
  required final _AddModelProviderFormValues values,
  required final _AddModelProviderFormCallbacks callbacks,
}) extends StatelessWidget {
  bool get _hidden {
    final request = values.request;
    return request.runtime.selection.isCodex &&
        request.runtime.controls.isSubmitting &&
        values.state.deviceCode.value != null;
  }

  @override
  Widget build(BuildContext _) => _hidden
      ? const SizedBox.shrink()
      : _CreateButton(values: values, callbacks: callbacks);
}

class const _CodexPendingAction({
  required final _AddModelProviderFormValues values,
  required final _AddModelProviderFormCallbacks callbacks,
}) extends StatelessWidget {
  bool get _visible {
    final request = values.request;
    return request.runtime.selection.isCodex &&
        request.runtime.controls.isSubmitting &&
        values.state.deviceCode.value == null;
  }

  @override
  Widget build(BuildContext _) => _visible
      ? _CodexOAuthPendingActions(onCancel: callbacks.onCancelCodexOAuth)
      : const SizedBox.shrink();
}

class const _CodexOAuthPendingActions({required final VoidCallback onCancel})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Column(
      children: [
        const AuraSizedBox(height: .md),
        const _CodexOAuthPendingStatus(showSpinner: false),
        const AuraSizedBox(height: .md),
        AuraButton(
          onPressed: onCancel,
          child: const TextLocale(_cancelConnectionKey),
          variant: .outlined,
          isFullWidth: true,
        ),
      ],
    );
  }
}

class _CodexOAuthCancellation {
  bool isCancelled = false;

  void cancel() => isCancelled = true;
}

/// Modal header with title and close button.
class const _ModalHeader({required final VoidCallback onClose})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.lg)),
      child: _ModalHeaderContent(onClose: onClose),
    );
  }
}

class const _ModalHeaderContent({required final VoidCallback onClose})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _ModalHeaderTitle(),
        _ModalHeaderCloseButton(onPressed: onClose),
      ],
    );
  }
}

class const _ModalHeaderTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext _) => const Expanded(
    child: AuraText(
      child: TextLocale(LocaleKeys.models_screens_add_provider_title),
      style: .heading5,
    ),
  );
}

class const _ModalHeaderCloseButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.close,
    onPressed: onPressed,
    semanticLabel: LocaleKeys.common_close_dialog.tr(),
  );
}

/// API configuration section with key and URL.
class const _ApiConfigSection({
  required final String workspaceId,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _HiddenSection(
      title: LocaleKeys.models_screens_add_provider_sections_advanced,
      child: EnhancedModelInput(
        workspaceId: workspaceId,
        fieldType: .url,

        onSubmitted: onSubmit,
      ),
    );
  }
}

/// Reusable form section with title and content.
class const _HiddenSection({
  required final String title,
  required final Widget child,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final visibilityState = useState(false);

    return _HiddenSectionContent(
      title: title,
      child: child,
      isVisible: visibilityState.value,
      onToggle: () => visibilityState.value = !visibilityState.value,
    );
  }
}

class const _HiddenSectionContent({
  required final String title,
  required final Widget child,
  required final bool isVisible,
  required final VoidCallback onToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        _HiddenSectionHeader(
          title: title,
          isVisible: isVisible,
          onToggle: onToggle,
        ),
        const AuraSizedBox(height: .md),
        Visibility(child: child, visible: isVisible),
      ],
    );
  }
}

class const _HiddenSectionHeader({
  required final String title,
  required final bool isVisible,
  required final VoidCallback onToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HiddenSectionTitle(title: title),
        _HiddenSectionToggle(isVisible: isVisible, onPressed: onToggle),
      ],
    );
  }
}

class const _HiddenSectionTitle({required final String title})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(
    title,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(color: context.auraColors.primary, fontWeight: .w600),
  );
}

class const _HiddenSectionToggle({
  required final bool isVisible,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraIconButton(
    icon: isVisible ? Icons.expand_less : Icons.expand_more,
    onPressed: onPressed,
  );
}

/// Error banner for displaying general errors.
class const _ErrorBanner() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = _errorBannerMessage(ref);

    if (error == null) {
      return const SizedBox.shrink();
    }

    return _ErrorBannerContent(
      error: error,
      errorColor: context.auraColors.error,
    );
  }

  String? _errorBannerMessage(WidgetRef ref) {
    final mutation = ref.watch(addCredentialsModelMutationProvider);

    return switch (mutation) {
      MutationError<void>(:final error) => _mapErrorMessage(error),
      MutationIdle() || MutationPending() || MutationSuccess() => null,
    };
  }

  String _mapErrorMessage(Object error) {
    if (error case ModelConnectionException(:final message)
        when message.trim().isNotEmpty) {
      return message;
    }

    return LocaleKeys.models_screens_add_provider_errors_unknown.tr();
  }
}

class const _ErrorBannerContent({
  required final String error,
  required final Color errorColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
      decoration: _errorBannerDecoration(context, errorColor),
      child: _ErrorBannerRow(error: error, errorColor: errorColor),
    );
  }
}

BoxDecoration _errorBannerDecoration(BuildContext context, Color errorColor) =>
    BoxDecoration(
      color: errorColor.withValues(alpha: 0.1),
      border: Border.all(color: errorColor),
      borderRadius: BorderRadius.all(
        .circular(context.auraTheme.fromBorderRadius(.md)),
      ),
    );

class const _ErrorBannerRow({
  required final String error,
  required final Color errorColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 20, color: errorColor),
        const AuraSizedBox(width: .sm),
        Expanded(
          child: _ErrorBannerText(error: error, color: errorColor),
        ),
      ],
    );
  }
}

class const _ErrorBannerText({
  required final String error,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    error,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
  );
}

/// Create button with loading state.
class const _CreateButton({
  required final _AddModelProviderFormValues values,
  required final _AddModelProviderFormCallbacks callbacks,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _watchCreateButtonState(ref, values.request.workspaceId);

    return _CreateButtonView(
      values: values,
      callbacks: callbacks,
      isSubmitting: state.isSubmitting,
      disabled: state.isSubmitting || !state.isValid,
    );
  }
}

typedef _CreateButtonState = ({bool isSubmitting, bool isValid});

_CreateButtonState _watchCreateButtonState(WidgetRef ref, String workspaceId) =>
    (
      isSubmitting: _watchCreateButtonSubmitting(ref),
      isValid: _watchCreateButtonValidity(ref, workspaceId),
    );

bool _watchCreateButtonSubmitting(WidgetRef ref) => ref.watch(
  addCredentialsModelMutationProvider.select((value) => value.isPending),
);

bool _watchCreateButtonValidity(WidgetRef ref, String workspaceId) => ref.watch(
  addModelProviderStateProvider(workspaceId).select((value) => value.isValid()),
);

class const _CreateButtonView({
  required final _AddModelProviderFormValues values,
  required final _AddModelProviderFormCallbacks callbacks,
  required final bool isSubmitting,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Column(
      children: [
        const _ErrorBanner(),
        _CreateButtonActions(
          values: values,
          callbacks: callbacks,
          isSubmitting: isSubmitting,
          disabled: disabled,
        ),
      ],
    );
  }
}

class const _CreateButtonActions({
  required final _AddModelProviderFormValues values,
  required final _AddModelProviderFormCallbacks callbacks,
  required final bool isSubmitting,
  required final bool disabled,
}) extends StatelessWidget {
  ({bool isSubmitting, bool disabled}) get _state =>
      (isSubmitting: isSubmitting, disabled: disabled);

  @override
  Widget build(BuildContext _) => Column(
    children: [
      _CodexBrowserAction(values: values, state: _state, callbacks: callbacks),
      _CodexDeviceAction(values: values, state: _state, callbacks: callbacks),
    ],
  );
}

class const _CodexBrowserAction({
  required final _AddModelProviderFormValues values,
  required final ({bool isSubmitting, bool disabled}) state,
  required final _AddModelProviderFormCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    if (!_supportsCodexBrowser(values)) {
      return const SizedBox.shrink();
    }

    return _CodexBrowserCreateButton(
      isSubmitting: state.isSubmitting,
      disabled: state.disabled,
      activeOAuthMethod: values.state.activeOAuthMethod.value,
      onPressed: callbacks.onCodexBrowserSubmit,
    );
  }
}

bool _supportsCodexBrowser(_AddModelProviderFormValues values) {
  final request = values.request;
  final selection = request.runtime.selection;
  final controls = request.runtime.controls;

  return selection.isCodex &&
      controls.isDesktop &&
      request.capabilities.modelBrowserOAuth;
}

class const _CodexDeviceAction({
  required final _AddModelProviderFormValues values,
  required final ({bool isSubmitting, bool disabled}) state,
  required final _AddModelProviderFormCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => _supportsCodexDevice(values)
      ? _CodexDeviceCreateButton.from(
          values: values,
          state: state,
          callbacks: callbacks,
        )
      : const SizedBox.shrink();
}

bool _supportsCodexDevice(_AddModelProviderFormValues values) {
  final request = values.request;
  return !request.runtime.selection.isCodex ||
      request.capabilities.modelDeviceOAuth;
}

class const _CodexBrowserCreateButton({
  required final bool isSubmitting,
  required final bool disabled,
  required final CodexOAuthMethod? activeOAuthMethod,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Column(
      children: [
        _CodexBrowserButton(
          isSubmitting: isSubmitting,
          disabled: disabled,
          activeOAuthMethod: activeOAuthMethod,
          onPressed: onPressed,
        ),
        const AuraSizedBox(height: .md),
      ],
    );
  }
}

class const _CodexBrowserButton({
  required final bool isSubmitting,
  required final bool disabled,
  required final CodexOAuthMethod? activeOAuthMethod,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(
      LocaleKeys.models_screens_add_provider_connect_browser,
    ),
    size: .large,
    isLoading: isSubmitting && activeOAuthMethod == CodexOAuthMethod.browser,
    isFullWidth: true,
    disabled: disabled,
  );
}

class const _CodexDeviceCreateButton({
  required final bool isSubmitting,
  required final bool disabled,
  required final bool isCodex,
  required final CodexOAuthMethod? activeOAuthMethod,
  required final VoidCallback onSubmit,
  required final VoidCallback onCodexDeviceSubmit,
}) extends StatelessWidget {
  _CodexDeviceCreateButton.from({
    required _AddModelProviderFormValues values,
    required ({bool isSubmitting, bool disabled}) state,
    required _AddModelProviderFormCallbacks callbacks,
  }) : this(
         isSubmitting: state.isSubmitting,
         disabled: state.disabled,
         isCodex: values.request.runtime.selection.isCodex,
         activeOAuthMethod: values.state.activeOAuthMethod.value,
         onSubmit: callbacks.onSubmit,
         onCodexDeviceSubmit: callbacks.onCodexDeviceSubmit,
       );

  VoidCallback get _onPressed => isCodex ? onCodexDeviceSubmit : onSubmit;
  String get _label => isCodex
      ? LocaleKeys.models_screens_add_provider_use_device_code
      : LocaleKeys.models_screens_add_provider_create_button;
  bool get _isLoading =>
      isSubmitting &&
      (!isCodex || activeOAuthMethod == CodexOAuthMethod.deviceCode);

  @override
  Widget build(BuildContext _) => _CodexDeviceButton(
    onPressed: _onPressed,
    disabled: disabled,
    label: _label,
    isLoading: _isLoading,
  );
}

class const _CodexDeviceButton({
  required final VoidCallback onPressed,
  required final bool disabled,
  required final String label,
  required final bool isLoading,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: onPressed,
    child: TextLocale(label),
    size: .large,
    isLoading: isLoading,
    isFullWidth: true,
    disabled: disabled,
  );
}

class const _CodexOAuthPendingStatus({final bool showSpinner = true})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Row(
      mainAxisAlignment: .center,
      children: [
        if (showSpinner) const AuraSpinner(size: .small),
        if (showSpinner) const AuraSizedBox(width: .sm),
        const Flexible(
          child: AuraText(
            child: TextLocale(_oauthWaitingKey),
            style: .bodySmall,
          ),
        ),
      ],
    );
  }
}

class const _CodexDeviceCodePanel({
  required final CodexDeviceCode deviceCode,
  required final bool isPending,
  required final VoidCallback onCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CodexDeviceCodePanelContent(
      deviceCode: deviceCode,
      isPending: isPending,
      linkStyle: _codexDeviceLinkStyle(context),
      onCopyCode: () => _copyCode(context),
      onOpenVerificationUrl: () => _showVerificationUrlActions(context),
      onCancel: onCancel,
    );
  }
}

extension on _CodexDeviceCodePanel {
  TextStyle? _codexDeviceLinkStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: context.auraColors.primary,
        decoration: .underline,
        decorationColor: context.auraColors.primary,
      );

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(.new(text: deviceCode.userCode));
    if (!context.mounted) return;

    final _ = AuraSnackBars.show(
      context: context,
      content: Text(
        LocaleKeys.models_screens_add_provider_device_code_copied.tr(),
      ),
      variant: .success,
    );
  }

  Future<void> _copyVerificationUrl(BuildContext context) async {
    await Clipboard.setData(.new(text: deviceCode.verificationUrl));
    if (!context.mounted) return;

    final _ = AuraSnackBars.show(
      context: context,
      content: Text(
        LocaleKeys.models_screens_add_provider_device_code_link_copied.tr(),
      ),
      variant: .success,
    );
  }

  void _showVerificationUrlActions(BuildContext context) {
    AuraDialogs.alert(
      context: context,
      title: const TextLocale(
        LocaleKeys.models_screens_add_provider_device_code_link_actions_title,
      ),
      message: _VerificationUrlActions(
        onOpen: _verificationUrlOpenAction(context),
        onCopy: _verificationUrlCopyAction(context),
      ),
      dismissLabel: const TextLocale(LocaleKeys.common_cancel),
    );
  }

  VoidCallback _verificationUrlOpenAction(BuildContext context) => () {
    Navigator.of(context, rootNavigator: true).pop();
    unawaited(_launchVerificationUrl(context));
  };

  VoidCallback _verificationUrlCopyAction(BuildContext context) => () {
    Navigator.of(context, rootNavigator: true).pop();
    unawaited(_copyVerificationUrl(context));
  };

  Future<void> _launchVerificationUrl(BuildContext context) async {
    final uri = Uri.parse(deviceCode.verificationUrl);
    try {
      await OpenSystemBrowser.call(uri);
    } on Exception {
      if (!context.mounted) return;

      _showVerificationUrlError(context);
    }
  }

  void _showVerificationUrlError(BuildContext context) {
    if (!context.mounted) return;

    final _ = AuraSnackBars.show(
      context: context,
      content: Text(
        LocaleKeys.models_screens_add_provider_device_code_open_link_failed
            .tr(),
      ),
      variant: .error,
    );
  }
}

class const _CodexDeviceCodePanelContent({
  required final CodexDeviceCode deviceCode,
  required final bool isPending,
  required final TextStyle? linkStyle,
  required final VoidCallback onCopyCode,
  required final VoidCallback onOpenVerificationUrl,
  required final VoidCallback onCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraCard(
    child: _CodexDeviceCodePanelBody(
      deviceCode: deviceCode,
      isPending: isPending,
      linkStyle: linkStyle,
      onCopyCode: onCopyCode,
      onOpenVerificationUrl: onOpenVerificationUrl,
      onCancel: onCancel,
    ),
  );
}

class const _CodexDeviceCodePanelBody({
  required final CodexDeviceCode deviceCode,
  required final bool isPending,
  required final TextStyle? linkStyle,
  required final VoidCallback onCopyCode,
  required final VoidCallback onOpenVerificationUrl,
  required final VoidCallback onCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        _CodexDeviceCodePanelDetails(
          userCode: deviceCode.userCode,
          verificationUrl: deviceCode.verificationUrl,
          linkStyle: linkStyle,
          onCopyCode: onCopyCode,
          onOpen: onOpenVerificationUrl,
        ),
        _CodexDeviceCodePanelActions(isPending: isPending, onCancel: onCancel),
      ],
    );
  }
}

class const _CodexDeviceCodePanelDetails({
  required final String userCode,
  required final String verificationUrl,
  required final TextStyle? linkStyle,
  required final VoidCallback onCopyCode,
  required final VoidCallback onOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Column(
    crossAxisAlignment: .start,
    children: [
      const _CodexDeviceCodeInstructionSection(),
      _CodexDeviceCodeRows(
        userCode: userCode,
        verificationUrl: verificationUrl,
        linkStyle: linkStyle,
        onCopyCode: onCopyCode,
        onOpen: onOpen,
      ),
    ],
  );
}

class const _CodexDeviceCodeInstructionSection() extends StatelessWidget {
  @override
  Widget build(BuildContext _) => const Column(
    children: [
      AuraText(
        child: TextLocale(
          LocaleKeys.models_screens_add_provider_device_code_instruction,
        ),
        style: .bodyLarge,
      ),
      AuraSizedBox(height: .sm),
    ],
  );
}

class const _CodexDeviceCodeRows({
  required final String userCode,
  required final String verificationUrl,
  required final TextStyle? linkStyle,
  required final VoidCallback onCopyCode,
  required final VoidCallback onOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Column(
    children: [
      _CodexDeviceCodeRow(userCode: userCode, onCopy: onCopyCode),
      const AuraSizedBox(height: .md),
      _CodexDeviceLinkRow(
        verificationUrl: verificationUrl,
        linkStyle: linkStyle,
        onOpen: onOpen,
      ),
    ],
  );
}

class const _CodexDeviceCodePanelActions({
  required final bool isPending,
  required final VoidCallback onCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Column(
      children: [
        if (isPending) const _CodexDevicePendingSection(),
        _CodexDeviceCancelButton(onCancel: onCancel),
      ],
    );
  }
}

class const _CodexDeviceCancelButton({required final VoidCallback onCancel})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: onCancel,
    child: const TextLocale(_cancelConnectionKey),
    variant: .outlined,
    isFullWidth: true,
  );
}

class const _CodexDeviceCodeRow({
  required final String userCode,
  required final VoidCallback onCopy,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _CodexDeviceCodeRowContent(
    userCode: userCode,
    onCopy: onCopy,
    tooltip: _tooltip(context),
  );

  String _tooltip(BuildContext context) => LocaleKeys
      .models_screens_add_provider_device_code_copy_tooltip
      .tr(context: context);
}

class _CodexDeviceCodeRowContent extends Column {
  _CodexDeviceCodeRowContent({
    required String userCode,
    required VoidCallback onCopy,
    required String tooltip,
  }) : super(
         crossAxisAlignment: .stretch,
         children: [
           const _CodexDeviceStepLabel(
             LocaleKeys.models_screens_add_provider_device_code_step_code,
           ),
           const AuraSizedBox(height: .sm),
           _CodexDeviceCodeValue(
             userCode: userCode,
             onCopy: onCopy,
             tooltip: tooltip,
           ),
         ],
       );
}

class const _CodexDeviceCodeValue({
  required final String userCode,
  required final VoidCallback onCopy,
  required final String tooltip,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Row(
      children: [
        Expanded(
          child: AuraSelectableText(userCode, style: .heading5, tint: .primary),
        ),
        AuraIconButton(
          icon: Icons.copy_outlined,
          onPressed: onCopy,
          tooltip: tooltip,
        ),
      ],
    );
  }
}

class const _CodexDeviceLinkRow({
  required final String verificationUrl,
  required final TextStyle? linkStyle,
  required final VoidCallback onOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _CodexDeviceLinkRowContent(
    verificationUrl: verificationUrl,
    linkStyle: linkStyle,
    onOpen: onOpen,
    tooltip: _tooltip(context),
  );

  String _tooltip(BuildContext context) => LocaleKeys
      .models_screens_add_provider_device_code_open_link_tooltip
      .tr(context: context);
}

class _CodexDeviceLinkRowContent extends Column {
  _CodexDeviceLinkRowContent({
    required String verificationUrl,
    required TextStyle? linkStyle,
    required VoidCallback onOpen,
    required String tooltip,
  }) : super(
         crossAxisAlignment: .stretch,
         children: [
           const _CodexDeviceStepLabel(
             LocaleKeys.models_screens_add_provider_device_code_step_link,
           ),
           const AuraSizedBox(height: .sm),
           _CodexDeviceLinkValue(
             verificationUrl: verificationUrl,
             linkStyle: linkStyle,
             onOpen: onOpen,
             tooltip: tooltip,
           ),
         ],
       );
}

class const _CodexDeviceStepLabel(this.localeKey) extends StatelessWidget {
  final String localeKey;

  @override
  Widget build(BuildContext _) => AuraText(child: TextLocale(localeKey));
}

class const _CodexDeviceLinkValue({
  required final String verificationUrl,
  required final TextStyle? linkStyle,
  required final VoidCallback onOpen,
  required final String tooltip,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Row(
    children: [
      Expanded(
        child: SelectableText(verificationUrl, style: linkStyle, onTap: onOpen),
      ),
      AuraIconButton(
        icon: Icons.open_in_new,
        onPressed: onOpen,
        tint: .primary,
        tooltip: tooltip,
      ),
    ],
  );
}

class const _CodexDevicePendingSection() extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return const Column(
      children: [
        AuraSizedBox(height: .lg),
        _CodexOAuthPendingStatus(),
        AuraSizedBox(height: .md),
      ],
    );
  }
}

class const _VerificationUrlActions({
  required final VoidCallback onOpen,
  required final VoidCallback onCopy,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        _OpenVerificationUrlButton(onPressed: onOpen),
        const AuraSizedBox(height: .sm),
        _CopyVerificationUrlButton(onPressed: onCopy),
      ],
    );
  }
}

class const _OpenVerificationUrlButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(
      LocaleKeys.models_screens_add_provider_device_code_open_browser,
    ),
    isFullWidth: true,
  );
}

class const _CopyVerificationUrlButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(
      LocaleKeys.models_screens_add_provider_device_code_copy_link,
    ),
    variant: .outlined,
    isFullWidth: true,
  );
}

class const _SelectModelProvider({required final String workspaceId})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _useModelProviderSelection(ref, workspaceId);
    return _ModelProviderSelectionContent(
      workspaceId: workspaceId,
      ref: ref,
      state: state,
    );
  }
}

class const _ModelProviderSelectionContent({
  required final String workspaceId,
  required final WidgetRef ref,
  required final _ModelProviderSelectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => state.models == null
      ? _ReloadModelProvidersButton(
          onPressed: () => _reloadModelProviders(ref, workspaceId),
        )
      : _SelectModelProviderView(
          searchQuery: state.searchQuery,
          filteredModels: state.filteredModels,
          onSearchChanged: state.onSearchChanged,
          onModelSelected: state.onModelSelected,
        );
}

class const _ModelProviderSelectionState({
  required final List<ApiModelProviderEntity>? models,
  required final String searchQuery,
  required final List<ApiModelProviderEntity> filteredModels,
  required final ValueChanged<String> onSearchChanged,
  required final ValueChanged<String> onModelSelected,
});

_ModelProviderSelectionState _useModelProviderSelection(
  WidgetRef ref,
  String workspaceId,
) {
  final models = _watchModelProviders(ref, workspaceId);
  final searchQuery = useState('');
  final addModelProvider = _watchAddModelProviderNotifier(ref, workspaceId);

  return _buildModelProviderSelectionState(
    models,
    searchQuery,
    addModelProvider,
  );
}

_ModelProviderSelectionState _buildModelProviderSelectionState(
  List<ApiModelProviderEntity>? models,
  ValueNotifier<String> searchQuery,
  AddModelProviderState addModelProvider,
) {
  final filteredModels = _useFilteredModelProviders(models, searchQuery);

  return _ModelProviderSelectionState(
    models: models,
    searchQuery: searchQuery.value,
    filteredModels: filteredModels,
    onSearchChanged: (value) => searchQuery.value = value,
    onModelSelected: addModelProvider.setModel,
  );
}

List<ApiModelProviderEntity> _useFilteredModelProviders(
  List<ApiModelProviderEntity>? models,
  ValueNotifier<String> searchQuery,
) => useMemoized(() => _filterModelProviders(models, searchQuery.value), [
  models,
  searchQuery.value,
]);

List<ApiModelProviderEntity>? _watchModelProviders(
  WidgetRef ref,
  String workspaceId,
) => ref.watch(apiModelProvidersProvider(workspaceId: workspaceId)).value;

AddModelProviderState _watchAddModelProviderNotifier(
  WidgetRef ref,
  String workspaceId,
) => ref.watch(addModelProviderStateProvider(workspaceId).notifier);

void _reloadModelProviders(WidgetRef ref, String workspaceId) =>
    ref.invalidate(apiModelProvidersProvider(workspaceId: workspaceId));

class const _ReloadModelProvidersButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.common_reload),
  );
}

List<ApiModelProviderEntity> _filterModelProviders(
  List<ApiModelProviderEntity>? models,
  String searchQuery,
) {
  if (models == null || searchQuery.isEmpty) {
    return models ?? <ApiModelProviderEntity>[];
  }

  final query = searchQuery.toLowerCase();

  return models
      .where((model) => model.name.toLowerCase().contains(query))
      .toList();
}

class const _SelectModelProviderView({
  required final String searchQuery,
  required final List<ApiModelProviderEntity> filteredModels,
  required final ValueChanged<String> onSearchChanged,
  required final ValueChanged<String> onModelSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraColumn(
    children: [
      _ModelProviderSearchControls(
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
      ),
      Expanded(
        child: _ModelProviderResults(
          models: filteredModels,
          onModelSelected: onModelSelected,
        ),
      ),
    ],
  );
}

class const _ModelProviderSearchControls({
  required final String searchQuery,
  required final ValueChanged<String> onSearchChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _ModelProviderSearchLabel(),
      const AuraSizedBox(height: .md),
      _ModelProviderSearchInput(
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
      ),
      const AuraSizedBox(height: .md),
    ],
  );
}

class const _ModelProviderSearchLabel() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(
      LocaleKeys.chats_screens_chat_conversation_select_model_selctor,
    ),
  );
}

class const _ModelProviderSearchInput({
  required final String searchQuery,
  required final ValueChanged<String> onSearchChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    initialValue: searchQuery,
    placeholder: const AuraText(
      child: TextLocale(
        LocaleKeys.models_screens_add_provider_search_placeholder,
      ),
    ),
    prefixIcon: Icon(Icons.search, color: context.auraColors.onSurfaceVariant),
    onChanged: onSearchChanged,
  );
}

class const _ModelProviderResults({
  required final List<ApiModelProviderEntity> models,
  required final ValueChanged<String> onModelSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) return const _NoModelProvidersFound();

    return ListView.builder(
      itemBuilder: (context, index) => _ModelProviderListItem(
        model: models[index],
        onSelected: onModelSelected,
      ),
      itemCount: models.length,
    );
  }
}

class const _NoModelProvidersFound() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: .center,
        children: [
          _NoModelProvidersIcon(color: context.auraColors.onSurfaceVariant),
          const AuraSizedBox(height: .sm),
          const _NoModelProvidersLabel(),
        ],
      ),
    );
  }
}

class const _NoModelProvidersIcon({required final Color color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) =>
      Icon(Icons.search_off, size: 48, color: color);
}

class const _NoModelProvidersLabel() extends StatelessWidget {
  @override
  Widget build(BuildContext _) => const AuraText(
    child: TextLocale(AddModelProviderWidget.noModelsFoundKey),
    style: .bodyLarge,
  );
}

class const _ModelProviderListItem({
  required final ApiModelProviderEntity model,
  required final ValueChanged<String> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final isOAuthProvider = ModelProviderOAuthProfiles.isCodexProvider(
      model.id,
    );

    return AuraCard(
      child: _ModelProviderListItemContent(
        model: model,
        isOAuthProvider: isOAuthProvider,
      ),
      onTap: () => onSelected(model.id),
    );
  }
}

class const _ModelProviderListItemContent({
  required final ApiModelProviderEntity model,
  required final bool isOAuthProvider,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Row(
    mainAxisAlignment: .spaceBetween,
    children: [
      ModelLogo(modelId: model.id),
      AuraText(child: Text(model.name)),
      _ModelProviderOAuthBadge(visible: isOAuthProvider),
    ],
  );
}

class const _ModelProviderOAuthBadge({required final bool visible})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => visible
      ? const AuraText(
          child: TextLocale(LocaleKeys.mcp_modal_auth_oauth),
          style: .bodySmall,
          tint: .primary,
        )
      : const SizedBox.shrink();
}

/// Header showing the selected model with a back button.
class const _SelectedModelHeader({required final String workspaceId})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext _, WidgetRef ref) {
    return _SelectedModelHeaderContent(
      details: _selectedModelHeaderDetails(
        _watchSelectedModelHeader(ref, workspaceId),
      ),
      notifier: ref.watch(addModelProviderStateProvider(workspaceId).notifier),
    );
  }
}

class const _SelectedModelHeaderContent({
  required final _SelectedModelHeaderDetails? details,
  required final AddModelProviderState notifier,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => details == null
      ? const SizedBox.shrink()
      : _SelectedModelHeaderView(
          modelId: details!.modelId,
          modelName: details!.modelName,
          onBack: () => notifier.setModel(null),
        );
}

typedef _SelectedModelHeaderState = ({
  String? selectedModelId,
  List<ApiModelProviderEntity>? models,
});

_SelectedModelHeaderState _watchSelectedModelHeader(
  WidgetRef ref,
  String workspaceId,
) => (
  selectedModelId: ref.watch(
    addModelProviderStateProvider(workspaceId).select((value) => value.modelId),
  ),
  models: ref.watch(apiModelProvidersProvider(workspaceId: workspaceId)).value,
);

typedef _SelectedModelHeaderDetails = ({String modelId, String modelName});

_SelectedModelHeaderDetails? _selectedModelHeaderDetails(
  _SelectedModelHeaderState state,
) {
  final input = _selectedModelHeaderInput(state);
  if (input == null) return null;
  final selectedModel = _findModelProvider(input.models, input.modelId);
  final modelName = _selectedModelName(selectedModel, input.modelId);
  if (modelName == null) return null;

  return (
    modelId: selectedModel?.id ?? ModelProviderOAuthProfiles.providerId,
    modelName: modelName,
  );
}

({String modelId, List<ApiModelProviderEntity> models})?
_selectedModelHeaderInput(_SelectedModelHeaderState state) {
  final modelId = state.selectedModelId;
  final models = state.models;
  return modelId == null || models == null
      ? null
      : (modelId: modelId, models: models);
}

ApiModelProviderEntity? _findModelProvider(
  List<ApiModelProviderEntity> models,
  String modelId,
) => models.firstWhereOrNull((model) => model.id == modelId);

String? _selectedModelName(
  ApiModelProviderEntity? selectedModel,
  String selectedModelId,
) =>
    selectedModel?.name ??
    (ModelProviderOAuthProfiles.isCodexProvider(selectedModelId)
        ? ModelProviderOAuthProfiles.displayName
        : null);

class const _SelectedModelHeaderView({
  required final String modelId,
  required final String modelName,
  required final VoidCallback onBack,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Row(
    children: [
      _SelectedModelBackButton(onPressed: onBack),
      const AuraSizedBox(width: .md),
      ModelLogo(modelId: modelId, height: 24),
      const AuraSizedBox(width: .md),
      Expanded(
        child: AuraText(child: Text(modelName), style: .bodyLarge),
      ),
    ],
  );
}

class const _SelectedModelBackButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.arrow_back,
    onPressed: onPressed,
    semanticLabel: LocaleKeys.models_screens_add_provider_back_to_selection
        .tr(),
  );
}
