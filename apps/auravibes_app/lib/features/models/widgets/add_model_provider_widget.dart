// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/widgets/enhanced_model_input.dart';
import 'package:auravibes_app/features/models/widgets/model_logo.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/codex_oauth_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/experimental/mutation.dart';

class AddModelProviderWidget extends HookConsumerWidget {
  const AddModelProviderWidget({
    required this.workspaceId,
    super.key,
    this.onCreated,
    this.onCancel,
    this.showHeader = true,
  });

  final String workspaceId;
  final VoidCallback? onCreated;
  final VoidCallback? onCancel;
  final bool showHeader;

  // Extract long locale key to avoid line length issues.
  static const String noModelsFoundKey =
      LocaleKeys.models_screens_add_provider_search_no_models_found;

  void _submitForm(
    BuildContext context,
    WidgetRef ref, {
    CodexOAuthMethod? codexOAuthMethod,
    void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
    bool Function()? isCodexDeviceCodeCancelled,
  }) {
    addCredentialsModelMutationProvider.run(ref, (transaction) async {
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final formKey = useMemoized(GlobalKey<FormState>.new, []);
    final codexDeviceCode = useState<CodexDeviceCode?>(null);
    final codexDeviceCodeCancelled = useRef(false);

    final hasModel = ref.watch(
      addModelProviderStateProvider(workspaceId).select(
        (value) => value.modelId != null,
      ),
    );
    final authMode = ref.watch(
      addModelProviderStateProvider(workspaceId).select(
        (value) => value.authMode,
      ),
    );
    final selectedModelId = ref.watch(
      addModelProviderStateProvider(workspaceId).select(
        (value) => value.modelId,
      ),
    );
    final isOAuth = authMode == ModelProviderAuthMode.oauth2;
    final isCodex = isOpenAICodexProvider(selectedModelId);
    final isDesktop =
        !kIsWeb &&
        const {
          TargetPlatform.macOS,
          TargetPlatform.linux,
          TargetPlatform.windows,
        }.contains(defaultTargetPlatform);

    if (!hasModel) {
      return _SelectModelProvider(workspaceId: workspaceId);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader)
          _ModalHeader(
            onClose: onCancel ?? () => Navigator.of(context).pop(),
          ),
        _SelectedModelHeader(workspaceId: workspaceId),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.auraTheme.spacing.lg),
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
                    SizedBox(height: context.auraTheme.spacing.xl),
                    _ApiConfigSection(
                      workspaceId: workspaceId,
                      onSubmit: () => _submitForm(context, ref),
                    ),
                  ],
                  SizedBox(height: context.auraTheme.spacing.xl),
                  if (codexDeviceCode.value case final deviceCode?) ...[
                    _CodexDeviceCodePanel(
                      deviceCode: deviceCode,
                      onCancel: () {
                        codexDeviceCodeCancelled.value = true;
                        codexDeviceCode.value = null;
                      },
                    ),
                    SizedBox(height: context.auraTheme.spacing.xl),
                  ],
                  _CreateButton(
                    workspaceId: workspaceId,
                    onSubmit: () => _submitForm(context, ref),
                    isCodex: isCodex,
                    isDesktop: isDesktop,
                    onCodexBrowserSubmit: () {
                      codexDeviceCodeCancelled.value = false;
                      codexDeviceCode.value = null;
                      _submitForm(
                        context,
                        ref,
                        codexOAuthMethod: CodexOAuthMethod.browser,
                      );
                    },
                    onCodexDeviceSubmit: () {
                      codexDeviceCodeCancelled.value = false;
                      codexDeviceCode.value = null;
                      _submitForm(
                        context,
                        ref,
                        codexOAuthMethod: CodexOAuthMethod.deviceCode,
                        onCodexDeviceCode: (deviceCode) {
                          if (context.mounted) {
                            codexDeviceCode.value = deviceCode;
                          }
                        },
                        isCodexDeviceCodeCancelled: () =>
                            codexDeviceCodeCancelled.value,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Modal header with title and close button.
class _ModalHeader extends StatelessWidget {
  const _ModalHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.auraTheme.spacing.lg),
      child: Row(
        children: [
          const Expanded(
            child: AuraText(
              child: TextLocale(
                LocaleKeys.models_screens_add_provider_title,
              ),
              style: AuraTextStyle.heading5,
            ),
          ),
          AuraIconButton(
            icon: Icons.close,
            onPressed: onClose,
            semanticLabel: 'Close dialog',
          ),
        ],
      ),
    );
  }
}

/// API configuration section with key and URL.
class _ApiConfigSection extends StatelessWidget {
  const _ApiConfigSection({
    required this.workspaceId,
    required this.onSubmit,
  });

  final String workspaceId;
  final VoidCallback onSubmit;

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
class _HiddenSection extends HookWidget {
  const _HiddenSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

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
        SizedBox(height: context.auraTheme.spacing.md),
        Visibility(
          child: child,
          visible: visibilityState.value,
        ),
      ],
    );
  }
}

/// Error banner for displaying general errors.
class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner();

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

    return Container(
      padding: EdgeInsets.all(context.auraTheme.spacing.md),
      decoration: BoxDecoration(
        color: context.auraColors.error.withValues(alpha: 0.1),
        border: Border.all(
          color: context.auraColors.error,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(DesignBorderRadius.md),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 20,
            color: context.auraColors.error,
          ),
          SizedBox(width: context.auraTheme.spacing.sm),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.auraColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mapErrorMessage(Object error) {
    if (error case ModelConnectionException(
      :final message,
    ) when message.trim().isNotEmpty) {
      return message;
    }

    return LocaleKeys.models_screens_add_provider_errors_unknown.tr();
  }
}

/// Create button with loading state.
class _CreateButton extends HookConsumerWidget {
  const _CreateButton({
    required this.workspaceId,
    required this.onSubmit,
    required this.isCodex,
    required this.isDesktop,
    required this.onCodexBrowserSubmit,
    required this.onCodexDeviceSubmit,
  });

  final String workspaceId;
  final VoidCallback onSubmit;
  final bool isCodex;
  final bool isDesktop;
  final VoidCallback onCodexBrowserSubmit;
  final VoidCallback onCodexDeviceSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      addCredentialsModelMutationProvider.select(
        (value) => value.isPending,
      ),
    );

    final isValid = ref.watch(
      addModelProviderStateProvider(workspaceId).select(
        (value) => value.isValid(),
      ),
    );
    final disabled = isSubmitting || !isValid;
    return Column(
      children: [
        const _ErrorBanner(),
        if (isCodex && isDesktop) ...[
          AuraButton(
            onPressed: onCodexBrowserSubmit,
            child: const TextLocale(
              LocaleKeys.models_screens_add_provider_connect_browser,
            ),
            size: AuraButtonSize.large,
            isLoading: isSubmitting,
            isFullWidth: true,
            disabled: disabled,
          ),
          SizedBox(height: context.auraTheme.spacing.md),
        ],
        AuraButton(
          onPressed: isCodex ? onCodexDeviceSubmit : onSubmit,
          child: TextLocale(
            isCodex
                ? LocaleKeys.models_screens_add_provider_use_device_code
                : LocaleKeys.models_screens_add_provider_create_button,
          ),
          size: AuraButtonSize.large,
          isLoading: isSubmitting,
          isFullWidth: true,
          disabled: disabled,
        ),
      ],
    );
  }
}

class _CodexDeviceCodePanel extends StatelessWidget {
  const _CodexDeviceCodePanel({
    required this.deviceCode,
    required this.onCancel,
  });

  final CodexDeviceCode deviceCode;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
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
          SizedBox(height: context.auraTheme.spacing.sm),
          SelectableText(deviceCode.verificationUrl),
          SizedBox(height: context.auraTheme.spacing.sm),
          AuraText(
            child: Text(deviceCode.userCode),
            style: AuraTextStyle.heading5,
            color: AuraColorVariant.primary,
          ),
          SizedBox(height: context.auraTheme.spacing.md),
          AuraButton(
            onPressed: onCancel,
            child: const TextLocale(LocaleKeys.common_cancel),
            size: AuraButtonSize.small,
          ),
        ],
      ),
    );
  }
}

class _SelectModelProvider extends HookConsumerWidget {
  const _SelectModelProvider({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(apiModelProvidersProvider).value;
    final searchQuery = useState('');
    final addModelProvider = ref.watch(
      addModelProviderStateProvider(workspaceId).notifier,
    );

    // Filter models based on search query using useMemoized.
    final filteredModels = useMemoized(
      () {
        if (models == null) return <ApiModelProviderEntity>[];

        if (searchQuery.value.isEmpty) {
          return models;
        }

        final query = searchQuery.value.toLowerCase();

        return models.where((model) {
          return model.name.toLowerCase().contains(query);
        }).toList();
      },
      [models, searchQuery.value],
    );

    if (models == null) {
      return AuraButton(
        onPressed: () => ref.invalidate(apiModelProvidersProvider),
        child: const AuraText(child: Text('reload')),
      );
    }

    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(
            LocaleKeys.chats_screens_chat_conversation_select_model_selctor,
          ),
        ),
        SizedBox(height: context.auraTheme.spacing.md),
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
        SizedBox(height: context.auraTheme.spacing.md),
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
                      SizedBox(height: context.auraTheme.spacing.sm),
                      const AuraText(
                        child: TextLocale(
                          AddModelProviderWidget.noModelsFoundKey,
                        ),
                        style: AuraTextStyle.bodyLarge,
                        color: AuraColorVariant.onSurfaceVariant,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemBuilder: (context, index) {
                    final model = filteredModels[index];
                    final isOAuthProvider = isOpenAICodexProvider(model.id);

                    return AuraCard(
                      child: Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          ModelLogo(
                            modelId: model.id,
                          ),
                          AuraText(
                            child: Text(model.name),
                          ),
                          if (isOAuthProvider)
                            const AuraText(
                              child: TextLocale(
                                LocaleKeys.mcp_modal_auth_oauth,
                              ),
                              style: AuraTextStyle.bodySmall,
                              color: AuraColorVariant.primary,
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
class _SelectedModelHeader extends HookConsumerWidget {
  const _SelectedModelHeader({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModelId = ref.watch(
      addModelProviderStateProvider(workspaceId).select(
        (value) => value.modelId,
      ),
    );

    final addModelProvider = ref.watch(
      addModelProviderStateProvider(workspaceId).notifier,
    );

    final models = ref.watch(apiModelProvidersProvider).value;

    if (selectedModelId == null || models == null) {
      return const SizedBox.shrink();
    }

    final selectedModel = models.firstWhereOrNull(
      (model) => model.id == selectedModelId,
    );
    final selectedModelName =
        selectedModel?.name ??
        (isOpenAICodexProvider(selectedModelId)
            ? openAICodexDisplayName
            : null);
    if (selectedModelName == null) return const SizedBox.shrink();

    return Row(
      children: [
        AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () {
            addModelProvider.setModel(null);
          },
          semanticLabel: 'Back to model selection',
        ),
        SizedBox(width: context.auraTheme.spacing.md),
        ModelLogo(
          modelId: selectedModel?.id ?? openAICodexProviderId,
          height: 24,
        ),
        SizedBox(width: context.auraTheme.spacing.md),
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
