import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_providers.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/widgets/enhanced_model_input.dart';
import 'package:auravibes_app/features/models/widgets/model_logo.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// ignore: implementation_imports
import 'package:riverpod/src/framework.dart';

class AddModelProviderWidget extends HookConsumerWidget {
  const AddModelProviderWidget({super.key});

  // Extract long locale key to avoid line length issues
  static const String _noModelsFoundKey =
      LocaleKeys.models_screens_add_provider_search_no_models_found;

  void _submitForm(BuildContext context, WidgetRef ref) {
    addCredentialsModelMutationProvider.run(ref, (transaction) async {
      final notifier = transaction.get(addModelProviderStateProvider.notifier);
      final created = await notifier.addModelProvider();
      if (context.mounted && created != null) {
        Navigator.of(context).pop(created);
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final formKey = useMemoized(GlobalKey<FormState>.new, []);

    final hasModel = ref.watch(
      addModelProviderStateProvider.select(
        (value) => value.modelId != null,
      ),
    );

    if (!hasModel) {
      return _SelectModelProvider();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModalHeader(
          onClose: () => Navigator.of(context).pop(),
        ),
        _SelectedModelHeader(),
        Flexible(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(context.auraTheme.spacing.lg),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EnhancedModelInput(
                    fieldType: ModelInputFieldType.name,
                    // onSubmitted: keyFocusNode.requestFocus,
                  ),
                  const EnhancedModelInput(
                    fieldType: ModelInputFieldType.key,
                  ),
                  SizedBox(height: context.auraTheme.spacing.xl),
                  _ApiConfigSection(
                    onSubmit: () => _submitForm(context, ref),
                  ),
                  SizedBox(height: context.auraTheme.spacing.xl),
                  _CreateButton(onSubmit: () => _submitForm(context, ref)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Modal header with title and close button
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
              style: AuraTextStyle.heading5,
              child: TextLocale(
                LocaleKeys.models_screens_add_provider_title,
              ),
            ),
          ),
          AuraIconButton(
            onPressed: onClose,
            icon: Icons.close,
            semanticLabel: 'Close dialog',
          ),
        ],
      ),
    );
  }
}

/// API configuration section with key and URL
class _ApiConfigSection extends StatelessWidget {
  const _ApiConfigSection({
    required this.onSubmit,
  });

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _HiddenSection(
      title: LocaleKeys.models_screens_add_provider_sections_advanced,
      child: EnhancedModelInput(
        fieldType: ModelInputFieldType.url,

        onSubmitted: onSubmit,
      ),
    );
  }
}

/// Reusable form section with title and content
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
                fontWeight: FontWeight.w600,
                color: context.auraColors.primary,
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
          visible: visibilityState.value,
          child: child,
        ),
      ],
    );
  }
}

/// Error banner for displaying general errors
class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addCredentialsModelMutation = ref.watch(
      addCredentialsModelMutationProvider,
    );

    final error = switch (addCredentialsModelMutation) {
      MutationError<void>(:final error) => switch (error) {
        AddModelException() => switch (error) {
          AddModelExceptionNoWorkspace() => 'no workspace found',
          AddModelExceptionNoUnkown() => 'unkown error',
        },
        _ => error.toString(),
      },
      _ => null,
    };

    if (error == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.all(context.auraTheme.spacing.md),
      decoration: BoxDecoration(
        color: context.auraColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignBorderRadius.md),
        border: Border.all(
          color: context.auraColors.error,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: context.auraColors.error,
            size: 20,
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
}

/// Create button with loading state
class _CreateButton extends HookConsumerWidget {
  const _CreateButton({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      addCredentialsModelMutationProvider.select(
        (value) => value.isPending,
      ),
    );

    final isValid = ref.watch(
      addModelProviderStateProvider.select(
        (value) => value.isValid(),
      ),
    );

    return Column(
      children: [
        const _ErrorBanner(),
        AuraButton(
          disabled: isSubmitting || !isValid,
          onPressed: onSubmit,
          isLoading: isSubmitting,
          isFullWidth: true,
          size: AuraButtonSize.large,
          child: const TextLocale(
            LocaleKeys.models_screens_add_provider_create_button,
          ),
        ),
      ],
    );
  }
}

class _SelectModelProvider extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(modelProvidersProvider).value;
    final searchQuery = useState('');
    final addModelProvider = ref.watch(
      addModelProviderStateProvider.notifier,
    );

    // Filter models based on search query using useMemoized
    final filteredModels = useMemoized(() {
      if (models == null) return <ApiModelProviderEntity>[];

      if (searchQuery.value.isEmpty) {
        return models;
      }

      final query = searchQuery.value.toLowerCase();
      return models.where((model) {
        return model.name.toLowerCase().contains(query);
      }).toList();
    }, [models, searchQuery.value]);

    if (models == null) {
      return AuraButton(
        onPressed: () {},
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
        // Search input field
        AuraInput(
          placeholder: const AuraText(
            child: TextLocale(
              LocaleKeys.models_screens_add_provider_search_placeholder,
            ),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: context.auraColors.onSurfaceVariant,
          ),
          initialValue: searchQuery.value,
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
                        style: AuraTextStyle.bodyLarge,
                        color: AuraColorVariant.onSurfaceVariant,
                        child: TextLocale(
                          AddModelProviderWidget._noModelsFoundKey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredModels.length,
                  itemBuilder: (context, index) {
                    final model = filteredModels[index];
                    return AuraCard(
                      onTap: () {
                        addModelProvider.setModel(model.id);
                      },
                      child: Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          ModelLogo(
                            modelId: model.id,
                          ),
                          AuraText(
                            child: Text(model.name),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Header showing the selected model with a back button
class _SelectedModelHeader extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModelId = ref.watch(
      addModelProviderStateProvider.select(
        (value) => value.modelId,
      ),
    );

    final addModelProvider = ref.watch(
      addModelProviderStateProvider.notifier,
    );

    final models = ref.watch(modelProvidersProvider).value;

    if (selectedModelId == null || models == null) {
      return const SizedBox.shrink();
    }

    final selectedModel = models.firstWhere(
      (model) => model.id == selectedModelId,
    );

    return Row(
      children: [
        AuraIconButton(
          onPressed: () {
            addModelProvider.setModel(null);
          },
          icon: Icons.arrow_back,
          semanticLabel: 'Back to model selection',
        ),
        SizedBox(width: context.auraTheme.spacing.md),
        ModelLogo(
          modelId: selectedModel.id,
          height: 24,
        ),
        SizedBox(width: context.auraTheme.spacing.md),
        Expanded(
          child: AuraText(
            style: AuraTextStyle.bodyLarge,
            child: Text(selectedModel.name),
          ),
        ),
      ],
    );
  }
}
