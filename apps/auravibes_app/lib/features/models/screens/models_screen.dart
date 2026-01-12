import 'package:auravibes_app/features/models/providers/list_models_providers.dart';
import 'package:auravibes_app/features/models/widgets/add_chat_model.dart';
import 'package:auravibes_app/features/models/widgets/list_model_credentials.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_content.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ModelsScreen extends StatelessWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      appBar: const AuraAppBar(
        title: TextLocale(LocaleKeys.models_screens_title),
      ),
      child: AuraColumn(
        children: [
          _AddModelModalButton(),
          const Expanded(child: ListModelCredentialsWidget()),
        ],
      ),
    );
  }
}

class _AddModelModalButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraPadding(
      padding: const .horizontal(.md),
      child: AppContent(
        child: Row(
          children: [
            Expanded(
              child: AuraButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignBorderRadius.xl,
                        ),
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: ctx.auraTheme.spacing.xl3 * 6,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(ctx.auraTheme.spacing.lg),
                          child: const AddModelProviderWidget(),
                        ),
                      ),
                    ),
                  ).then((onValue) {
                    ref.invalidate(listCredentialsProvider);
                  });
                  // context.go(location)
                },
                child: const TextLocale(
                  LocaleKeys.models_screens_add_provider_open_button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
