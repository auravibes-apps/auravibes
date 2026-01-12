import 'package:auravibes_app/domain/entities/credentials_models_entities.dart';
import 'package:auravibes_app/features/models/providers/list_chat_models_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SelectCredentialsModelWidget extends HookConsumerWidget
    implements PreferredSizeWidget {
  const SelectCredentialsModelWidget({
    required this.selectCredentialsModelId,
    super.key,
    this.credentialsModelId,
  });

  final String? credentialsModelId;
  final void Function(String?) selectCredentialsModelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentialsModelsAsync = ref.watch(
      listCredentialsCredentialsProvider,
    );

    final searchValue = useState<String>('');
    final controller = useTextEditingController();

    final options = useMemoized(() {
      final credentialsModels = credentialsModelsAsync.value ?? [];
      if (searchValue.value.isEmpty) return credentialsModels;
      return credentialsModels.where((model) {
        final searchTerm =
            '${model.credentials.name} - ${model.credentialsModel.modelId}'
                .toLowerCase();
        return searchTerm.contains(searchValue.value.toLowerCase());
      }).toList();
    }, [searchValue.value, credentialsModelsAsync.value]);

    return AuraPadding(
      padding: const .only(bottom: .sm, left: .md, right: .md),
      child: AuraDropdownSelector<String>(
        value: credentialsModelId,
        onChanged: selectCredentialsModelId,
        placeholder: const TextLocale(
          LocaleKeys.chats_screens_chat_conversation_select_model_selctor,
        ),
        options: options.map(
          (model) {
            final name = model.credentials.name;
            final modelId = model.credentialsModel.modelId;
            return AuraDropdownOption(
              value: model.credentialsModel.id,
              child: Text(
                '$name - $modelId',
              ),
            );
          },
        ).toList(),

        header: switch (credentialsModelsAsync) {
          AsyncLoading<List<CredentialsModelWithProviderEntity>>() =>
            const AuraSpinner(),
          AsyncData<List<CredentialsModelWithProviderEntity>>() => Padding(
            padding: EdgeInsetsGeometry.all(context.auraTheme.spacing.md),
            child: AuraInput(
              controller: controller,
              onChanged: (value) {
                searchValue.value = value;
              },
            ),
          ),
          AsyncError<List<CredentialsModelWithProviderEntity>>(
            :final error,
            :final stackTrace,
          ) =>
            AppErrorWidget(error: error, stackTrace: stackTrace),
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
