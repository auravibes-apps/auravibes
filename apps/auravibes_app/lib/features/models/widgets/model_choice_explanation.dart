import 'dart:async';

import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const ModelChoiceExplanation({
  required final String descriptionKey,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final helpLabel = 'models_screens.choice_help.label'.tr(context: context);

    return Row(
      crossAxisAlignment: .start,
      children: [
        Expanded(
          child: AuraText(child: TextLocale(descriptionKey), style: .bodySmall),
        ),
        const AuraSizedBox(width: .xs),
        _ModelChoiceHelpButton(label: helpLabel),
      ],
    );
  }

  static Future<void> _showModelChoiceHelp(BuildContext context) =>
      AuraDialogs.alert(
        context: context,
        title: const TextLocale('models_screens.choice_help.title'),
        message: const TextLocale('models_screens.choice_help.details'),
        dismissLabel: const TextLocale('common.close'),
      );
}

class const _ModelChoiceHelpButton({required final String label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.info_outline,
    onPressed: () =>
        unawaited(ModelChoiceExplanation._showModelChoiceHelp(context)),
    size: .small,
    semanticLabel: label,
    tooltip: label,
  );
}
