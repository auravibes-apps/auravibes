import 'package:auravibes_app/domain/entities/credentials_entities.dart';
import 'package:auravibes_app/features/models/providers/list_models_providers.dart';
import 'package:auravibes_app/features/models/providers/model_providers_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ListModelCredentialsWidget extends ConsumerWidget {
  const ListModelCredentialsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentialsModelsAsync = ref.watch(listCredentialsProvider);

    return switch (credentialsModelsAsync) {
      AsyncData(value: final credentialsModels) => () {
        if (credentialsModels.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: credentialsModels.length,
          shrinkWrap: true,
          // separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final credentialsModel = credentialsModels[index];
            //return Text(credentialsModel.name);
            return _CredentialsModelCard(credentialsModel: credentialsModel);
          },
          separatorBuilder: (BuildContext context, int index) {
            return SizedBox(height: context.auraTheme.spacing.md);
          },
        );
      }(),
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError(error: final error, stackTrace: _) => AuraText(
        child: Text(
          LocaleKeys.models_screens_list_error.tr(
            args: ['$error'],
            context: context,
          ),
        ),
      ),
    };
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: AuraColumn(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AuraIcon(
              Icons.model_training_outlined,
              size: AuraIconSize.extraLarge,
              color: Colors.grey,
            ),
            AuraText(
              style: AuraTextStyle.heading3,
              child: TextLocale(
                LocaleKeys.models_screens_list_empty_title,
              ),
            ),
            AuraText(
              // TODO: color: Colors.grey,
              textAlign: TextAlign.center,
              child: TextLocale(
                LocaleKeys.models_screens_list_empty_subtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialsModelCard extends ConsumerWidget {
  const _CredentialsModelCard({required this.credentialsModel});

  final CredentialsEntity credentialsModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuController = AuraPopupMenuController();

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildModelTypeIcon(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuraText(
                      style: AuraTextStyle.heading6,
                      child: Text(credentialsModel.name),
                    ),
                    const SizedBox(height: 4),
                    AuraText(
                      style: AuraTextStyle.bodySmall,

                      child: Text(_getModelTypeDisplay()),
                    ),
                  ],
                ),
              ),
              AuraPopupMenu(
                controller: menuController,
                items: [
                  AuraPopupMenuItem(
                    title: const TextLocale(LocaleKeys.common_delete),
                    leading: const AuraIcon(Icons.delete),
                    onTap: () => _confirmDelete(context, ref, credentialsModel),
                    variant: .error,
                  ),
                ],
                child: AuraIconButton(
                  icon: Icons.more_vert,
                  onPressed: menuController.toggle,
                ),
              ),
            ],
          ),
          if (credentialsModel.url != null) ...[
            const SizedBox(height: 12),
            AuraText(
              style: AuraTextStyle.bodySmall,

              child: Text(
                LocaleKeys.models_screens_list_url_label.tr(
                  args: [credentialsModel.url!],
                  context: context,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AuraText(
            style: AuraTextStyle.bodySmall,
            child: Text(
              LocaleKeys.models_screens_list_api_key_label.tr(
                args: [_obscureApiKey(credentialsModel.keySuffix)],
                context: context,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelTypeIcon(BuildContext context) {
    return SvgPicture.network(
      'https://models.dev/logos/${credentialsModel.modelId}.svg',
      placeholderBuilder: (BuildContext context) =>
          const CircularProgressIndicator(), // Optional: show a loading
      // indicator
      colorFilter: ColorFilter.mode(
        context.auraColors.onBackground,
        BlendMode.srcIn,
      ),
      height: 30, // Optional: specify height
      width: 30, // Optional: specify width
    );
  }

  String _getModelTypeDisplay() {
    return credentialsModel.modelId;
  }

  String _obscureApiKey(String? keySuffix) {
    if (keySuffix == null || keySuffix.isEmpty) {
      return '*' * 20;
    }
    return '********************$keySuffix';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CredentialsEntity credentials,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TextLocale(LocaleKeys.models_screens_list_delete_title),
        content: Text(
          LocaleKeys.models_screens_list_delete_confirm.tr(
            namedArgs: {'name': credentials.name},
            context: context,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const TextLocale(LocaleKeys.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const TextLocale(LocaleKeys.common_delete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref
          .read(modelProvidersRepositoryProvider)
          .deleteCredential(credentials.id);
      ref.invalidate(listCredentialsProvider);
    }
  }
}
