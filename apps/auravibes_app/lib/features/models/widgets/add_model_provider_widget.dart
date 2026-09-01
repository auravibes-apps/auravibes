// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/widgets/enhanced_model_input.dart';
import 'package:auravibes_app/features/models/widgets/model_logo.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/codex_oauth_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_app/utils/open_system_browser.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
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
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final formKey = useMemoized(GlobalKey<FormState>.new, []);
    final codexDeviceCode = useState<CodexDeviceCode?>(null);
    final activeCodexOAuthMethod = useState<CodexOAuthMethod?>(null);
    final codexOAuthCancellation = useRef<_CodexOAuthCancellation?>(null);

    final selectedState = ref.watch(
      addModelProviderStateProvider(workspaceId).select(
        (value) => (
          hasModel: value.modelId != null,
          authMode: value.authMode,
          modelId: value.modelId,
        ),
      ),
    );
    final isOAuth = selectedState.authMode == ModelProviderAuthMode.oauth2;
    final isCodex = ModelProviderOAuthProfiles.isCodexProvider(
      selectedState.modelId,
    );
    final isSubmitting = ref.watch(
      addCredentialsModelMutationProvider.select((value) => value.isPending),
    );
    final session = ref.watch(workspaceSessionForRouteProvider(workspaceId));
    final isDesktop =
        !kIsWeb &&
        const {
          TargetPlatform.macOS,
          TargetPlatform.linux,
          TargetPlatform.windows,
        }.contains(defaultTargetPlatform);

    if (!selectedState.hasModel) {
      return _SelectModelProvider(workspaceId: workspaceId);
    }

    if (session case AsyncLoading() || AsyncError()) {
      return const Center(child: AuraSpinner());
    }
    final capabilities = session.requireValue.capabilities;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader)
          _ModalHeader(onClose: onCancel ?? () => Navigator.of(context).pop()),
        _SelectedModelHeader(workspaceId: workspaceId),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.auraTheme.fromSpacing(.lg)),
            controller: scrollController,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EnhancedModelInput(
                    workspaceId: workspaceId,
                    fieldType: ModelInputFieldType.name,
                    // OnSubmitted: keyFocusNode.requestFocus,.
                  ),
                  if (!isOAuth) ...[
                    EnhancedModelInput(
                      workspaceId: workspaceId,
                      fieldType: ModelInputFieldType.key,
                    ),
                    const AuraSizedBox(height: .xl),
                    _ApiConfigSection(
                      workspaceId: workspaceId,
                      onSubmit: () => unawaited(_submitForm(context, ref)),
                    ),
                  ],
                  const AuraSizedBox(height: .xl),
                  if (codexDeviceCode.value case final deviceCode?) ...[
                    _CodexDeviceCodePanel(
                      deviceCode: deviceCode,
                      isPending: isSubmitting,
                      onCancel: () => _cancelCodexOAuth(
                        ref,
                        codexDeviceCode,
                        activeCodexOAuthMethod,
                        codexOAuthCancellation,
                      ),
                    ),
                    const AuraSizedBox(height: .xl),
                  ],
                  if (!(isCodex &&
                      isSubmitting &&
                      codexDeviceCode.value != null))
                    _CreateButton(
                      workspaceId: workspaceId,
                      onSubmit: () => unawaited(_submitForm(context, ref)),
                      isCodex: isCodex,
                      isDesktop: isDesktop,
                      supportsBrowserOAuth: capabilities.modelBrowserOAuth,
                      supportsDeviceOAuth: capabilities.modelDeviceOAuth,
                      activeCodexOAuthMethod: activeCodexOAuthMethod.value,
                      onCodexBrowserSubmit: () => _submitCodexBrowser(
                        context,
                        ref,
                        codexDeviceCode,
                        activeCodexOAuthMethod,
                        codexOAuthCancellation,
                      ),
                      onCodexDeviceSubmit: () => _submitCodexDevice(
                        context,
                        ref,
                        codexDeviceCode,
                        activeCodexOAuthMethod,
                        codexOAuthCancellation,
                      ),
                    ),
                  if (isCodex &&
                      isSubmitting &&
                      codexDeviceCode.value == null) ...[
                    const AuraSizedBox(height: .md),
                    const _CodexOAuthPendingStatus(showSpinner: false),
                    const AuraSizedBox(height: .md),
                    AuraButton(
                      onPressed: () => _cancelCodexOAuth(
                        ref,
                        codexDeviceCode,
                        activeCodexOAuthMethod,
                        codexOAuthCancellation,
                      ),
                      child: const TextLocale(_cancelConnectionKey),
                      variant: AuraButtonVariant.outlined,
                      isFullWidth: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm(
    BuildContext context,
    WidgetRef ref, {
    CodexOAuthMethod? codexOAuthMethod,
    void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
    bool Function()? isCodexDeviceCodeCancelled,
  }) async {
    try {
      await addCredentialsModelMutationProvider.run(ref, (transaction) async {
        final notifier = transaction.get(
          addModelProviderStateProvider(workspaceId).notifier,
        );
        final created = await notifier.addModelProvider(
          codexOAuthMethod: codexOAuthMethod,
          onCodexDeviceCode: onCodexDeviceCode,
          isCodexDeviceCodeCancelled: isCodexDeviceCodeCancelled,
        );
        if (context.mounted && created != null) {
          final onCreated = this.onCreated;
          if (onCreated != null) {
            onCreated();
          } else {
            Navigator.of(context).pop(created);
          }
        }
      });
    } on Object {
      // Mutation state renders the mapped failure in _ErrorBanner.
    }
  }

  void _submitCodexBrowser(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<CodexDeviceCode?> deviceCode,
    ValueNotifier<CodexOAuthMethod?> activeOAuthMethod,
    ObjectRef<_CodexOAuthCancellation?> cancellationRef,
  ) {
    final cancellation = _CodexOAuthCancellation();
    cancellationRef.value = cancellation;
    activeOAuthMethod.value = CodexOAuthMethod.browser;
    deviceCode.value = null;
    unawaited(
      _submitForm(
        context,
        ref,
        codexOAuthMethod: CodexOAuthMethod.browser,
        isCodexDeviceCodeCancelled: () => cancellation.isCancelled,
      ),
    );
  }

  void _submitCodexDevice(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<CodexDeviceCode?> deviceCode,
    ValueNotifier<CodexOAuthMethod?> activeOAuthMethod,
    ObjectRef<_CodexOAuthCancellation?> cancellationRef,
  ) {
    final cancellation = _CodexOAuthCancellation();
    cancellationRef.value = cancellation;
    activeOAuthMethod.value = CodexOAuthMethod.deviceCode;
    deviceCode.value = null;
    unawaited(
      _submitForm(
        context,
        ref,
        codexOAuthMethod: CodexOAuthMethod.deviceCode,
        onCodexDeviceCode: (value) {
          if (!context.mounted ||
              cancellation.isCancelled ||
              !identical(cancellationRef.value, cancellation)) {
            return;
          }
          deviceCode.value = value;
        },
        isCodexDeviceCodeCancelled: () => cancellation.isCancelled,
      ),
    );
  }

  void _cancelCodexOAuth(
    WidgetRef ref,
    ValueNotifier<CodexDeviceCode?> deviceCode,
    ValueNotifier<CodexOAuthMethod?> activeOAuthMethod,
    ObjectRef<_CodexOAuthCancellation?> cancellationRef,
  ) {
    cancellationRef.value?.cancel();
    cancellationRef.value = null;
    deviceCode.value = null;
    activeOAuthMethod.value = null;
    addCredentialsModelMutationProvider.reset(ref);
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
      child: Row(
        children: [
          const Expanded(
            child: AuraText(
              child: TextLocale(LocaleKeys.models_screens_add_provider_title),
              style: AuraTextStyle.heading5,
            ),
          ),
          AuraIconButton(
            icon: Icons.close,
            onPressed: onClose,
            semanticLabel: LocaleKeys.common_close_dialog.tr(),
          ),
        ],
      ),
    );
  }
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
        fieldType: ModelInputFieldType.url,

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextLocale(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.auraColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            AuraIconButton(
              icon: visibilityState.value
                  ? Icons.expand_less
                  : Icons.expand_more,
              onPressed: () {
                visibilityState.value = !visibilityState.value;
              },
            ),
          ],
        ),
        const AuraSizedBox(height: .md),
        Visibility(child: child, visible: visibilityState.value),
      ],
    );
  }
}

/// Error banner for displaying general errors.
class const _ErrorBanner() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addCredentialsModelMutation = ref.watch(
      addCredentialsModelMutationProvider,
    );

    final error = switch (addCredentialsModelMutation) {
      MutationError<void>(:final error) => _mapErrorMessage(error),
      _ => null,
    };

    if (error == null) {
      return const SizedBox.shrink();
    }
    final errorColor = context.auraColors.error;

    return Container(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        border: Border.all(color: errorColor),
        borderRadius: BorderRadius.all(
          Radius.circular(context.auraTheme.fromBorderRadius(.md)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: errorColor),
          const AuraSizedBox(width: .sm),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }

  String _mapErrorMessage(Object error) {
    if (error case ModelConnectionException(:final message)
        when message.trim().isNotEmpty) {
      return message;
    }

    return LocaleKeys.models_screens_add_provider_errors_unknown.tr();
  }
}

/// Create button with loading state.
class const _CreateButton({
  required final String workspaceId,
  required final VoidCallback onSubmit,
  required final bool isCodex,
  required final bool isDesktop,
  required final bool supportsBrowserOAuth,
  required final bool supportsDeviceOAuth,
  required final CodexOAuthMethod? activeCodexOAuthMethod,
  required final VoidCallback onCodexBrowserSubmit,
  required final VoidCallback onCodexDeviceSubmit,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      addCredentialsModelMutationProvider.select((value) => value.isPending),
    );

    final isValid = ref.watch(
      addModelProviderStateProvider(workspaceId)
          .select((value) => value.isValid()),
    );
    final disabled = isSubmitting || !isValid;

    return Column(
      children: [
        const _ErrorBanner(),
        if (isCodex && isDesktop && supportsBrowserOAuth) ...[
          AuraButton(
            onPressed: onCodexBrowserSubmit,
            child: const TextLocale(
              LocaleKeys.models_screens_add_provider_connect_browser,
            ),
            size: AuraButtonSize.large,
            isLoading:
                isSubmitting &&
                activeCodexOAuthMethod == CodexOAuthMethod.browser,
            isFullWidth: true,
            disabled: disabled,
          ),
          const AuraSizedBox(height: .md),
        ],
        if (!isCodex || supportsDeviceOAuth)
          AuraButton(
            onPressed: isCodex ? onCodexDeviceSubmit : onSubmit,
            child: TextLocale(
              isCodex
                  ? LocaleKeys.models_screens_add_provider_use_device_code
                  : LocaleKeys.models_screens_add_provider_create_button,
            ),
            size: AuraButtonSize.large,
            isLoading:
                !isCodex ||
                (isSubmitting &&
                    activeCodexOAuthMethod == CodexOAuthMethod.deviceCode),
            isFullWidth: true,
            disabled: disabled,
          ),
      ],
    );
  }
}

class const _CodexOAuthPendingStatus({final bool showSpinner = true})
    extends StatelessWidget {

  @override
  Widget build(BuildContext _) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showSpinner) const AuraSpinner(size: AuraSpinnerSize.small),
        if (showSpinner) const AuraSizedBox(width: .sm),
        const Flexible(
          child: AuraText(
            child: TextLocale(_oauthWaitingKey),
            style: AuraTextStyle.bodySmall,
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
    final linkStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: context.auraColors.primary,
      decoration: TextDecoration.underline,
      decorationColor: context.auraColors.primary,
    );

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuraText(
            child: TextLocale(
              LocaleKeys.models_screens_add_provider_device_code_instruction,
            ),
            style: AuraTextStyle.bodyLarge,
          ),
          const AuraSizedBox(height: .sm),
          const AuraText(
            child: TextLocale(
              LocaleKeys.models_screens_add_provider_device_code_step_code,
            ),
          ),
          const AuraSizedBox(height: .sm),
          Row(
            children: [
              Expanded(
                child: AuraSelectableText(
                  deviceCode.userCode,
                  style: AuraTextStyle.heading5,
                  tint: AuraTint.primary,
                ),
              ),
              AuraIconButton(
                icon: Icons.copy_outlined,
                onPressed: () => _copyCode(context),
                tooltip: LocaleKeys
                    .models_screens_add_provider_device_code_copy_tooltip
                    .tr(context: context),
              ),
            ],
          ),
          const AuraSizedBox(height: .md),
          const AuraText(
            child: TextLocale(
              LocaleKeys.models_screens_add_provider_device_code_step_link,
            ),
          ),
          const AuraSizedBox(height: .sm),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  deviceCode.verificationUrl,
                  style: linkStyle,
                  onTap: () => _showVerificationUrlActions(context),
                ),
              ),
              AuraIconButton(
                icon: Icons.open_in_new,
                onPressed: () => _showVerificationUrlActions(context),
                tint: AuraTint.primary,
                tooltip: LocaleKeys
                    .models_screens_add_provider_device_code_open_link_tooltip
                    .tr(context: context),
              ),
            ],
          ),
          if (isPending) ...[
            const AuraSizedBox(height: .lg),
            const _CodexOAuthPendingStatus(),
            const AuraSizedBox(height: .md),
          ],
          AuraButton(
            onPressed: onCancel,
            child: const TextLocale(_cancelConnectionKey),
            variant: AuraButtonVariant.outlined,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: deviceCode.userCode));
    if (!context.mounted) return;

    final _ = AuraSnackBars.show(
      context: context,
      content: Text(
        LocaleKeys.models_screens_add_provider_device_code_copied.tr(),
      ),
      variant: AuraSnackBarVariant.success,
    );
  }

  Future<void> _copyVerificationUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: deviceCode.verificationUrl));
    if (!context.mounted) return;

    final _ = AuraSnackBars.show(
      context: context,
      content: Text(
        LocaleKeys.models_screens_add_provider_device_code_link_copied.tr(),
      ),
      variant: AuraSnackBarVariant.success,
    );
  }

  void _showVerificationUrlActions(BuildContext context) {
    AuraDialogs.alert(
      context: context,
      title: const TextLocale(
        LocaleKeys.models_screens_add_provider_device_code_link_actions_title,
      ),
      message: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              unawaited(_launchVerificationUrl(context));
            },
            child: const TextLocale(
              LocaleKeys.models_screens_add_provider_device_code_open_browser,
            ),
            isFullWidth: true,
          ),
          const AuraSizedBox(height: .sm),
          AuraButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              unawaited(_copyVerificationUrl(context));
            },
            child: const TextLocale(
              LocaleKeys.models_screens_add_provider_device_code_copy_link,
            ),
            variant: AuraButtonVariant.outlined,
            isFullWidth: true,
          ),
        ],
      ),
      dismissLabel: const TextLocale(LocaleKeys.common_cancel),
    );
  }

  Future<void> _launchVerificationUrl(BuildContext context) async {
    final uri = Uri.parse(deviceCode.verificationUrl);
    try {
      await OpenSystemBrowser.call(uri);
    } on Exception {
      if (!context.mounted) return;

      final _ = AuraSnackBars.show(
        context: context,
        content: Text(
          LocaleKeys.models_screens_add_provider_device_code_open_link_failed
              .tr(),
        ),
        variant: AuraSnackBarVariant.error,
      );
    }
  }
}

class const _SelectModelProvider({required final String workspaceId})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref
        .watch(apiModelProvidersProvider(workspaceId: workspaceId))
        .value;
    final searchQuery = useState('');
    final addModelProvider = ref.watch(
      addModelProviderStateProvider(workspaceId).notifier,
    );

    // Filter models based on search query using useMemoized.
    List<ApiModelProviderEntity> filterModels() {
      if (models == null) return <ApiModelProviderEntity>[];

      if (searchQuery.value.isEmpty) {
        return models;
      }

      final query = searchQuery.value.toLowerCase();

      return models.where((model) {
        return model.name.toLowerCase().contains(query);
      }).toList();
    }

    final filteredModels = useMemoized(filterModels, [
      models,
      searchQuery.value,
    ]);

    if (models == null) {
      return AuraButton(
        onPressed: () =>
            ref.invalidate(apiModelProvidersProvider(workspaceId: workspaceId)),
        child: const TextLocale(LocaleKeys.common_reload),
      );
    }

    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(
            LocaleKeys.chats_screens_chat_conversation_select_model_selctor,
          ),
        ),
        const AuraSizedBox(height: .md),
        // Search input field.
        AuraInput(
          initialValue: searchQuery.value,
          placeholder: const AuraText(
            child: TextLocale(
              LocaleKeys.models_screens_add_provider_search_placeholder,
            ),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: context.auraColors.onSurfaceVariant,
          ),
          onChanged: (value) {
            searchQuery.value = value;
          },
        ),
        const AuraSizedBox(height: .md),
        Expanded(
          child: filteredModels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: context.auraColors.onSurfaceVariant,
                      ),
                      const AuraSizedBox(height: .sm),
                      const AuraText(
                        child: TextLocale(
                          AddModelProviderWidget.noModelsFoundKey,
                        ),
                        style: AuraTextStyle.bodyLarge,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemBuilder: (context, index) {
                    final model = filteredModels[index];
                    final isOAuthProvider =
                        ModelProviderOAuthProfiles.isCodexProvider(model.id);

                    return AuraCard(
                      child: Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          ModelLogo(modelId: model.id),
                          AuraText(child: Text(model.name)),
                          if (isOAuthProvider)
                            const AuraText(
                              child: TextLocale(
                                LocaleKeys.mcp_modal_auth_oauth,
                              ),
                              style: AuraTextStyle.bodySmall,
                              tint: AuraTint.primary,
                            ),
                        ],
                      ),
                      onTap: () {
                        addModelProvider.setModel(model.id);
                      },
                    );
                  },
                  itemCount: filteredModels.length,
                ),
        ),
      ],
    );
  }
}

/// Header showing the selected model with a back button.
class const _SelectedModelHeader({required final String workspaceId})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModelId = ref.watch(
      addModelProviderStateProvider(workspaceId)
          .select((value) => value.modelId),
    );

    final addModelProvider = ref.watch(
      addModelProviderStateProvider(workspaceId).notifier,
    );

    final models = ref
        .watch(apiModelProvidersProvider(workspaceId: workspaceId))
        .value;

    if (selectedModelId == null || models == null) {
      return const SizedBox.shrink();
    }

    final selectedModel = models.firstWhereOrNull(
      (model) => model.id == selectedModelId,
    );
    final selectedModelName =
        selectedModel?.name ??
        (ModelProviderOAuthProfiles.isCodexProvider(selectedModelId)
            ? ModelProviderOAuthProfiles.displayName
            : null);
    if (selectedModelName == null) return const SizedBox.shrink();

    return Row(
      children: [
        AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () {
            addModelProvider.setModel(null);
          },
          semanticLabel: LocaleKeys
              .models_screens_add_provider_back_to_selection
              .tr(),
        ),
        const AuraSizedBox(width: .md),
        ModelLogo(
          modelId: selectedModel?.id ?? ModelProviderOAuthProfiles.providerId,
          height: 24,
        ),
        const AuraSizedBox(width: .md),
        Expanded(
          child: AuraText(
            child: Text(selectedModelName),
            style: AuraTextStyle.bodyLarge,
          ),
        ),
      ],
    );
  }
}
