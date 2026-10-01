import 'package:auravibes_app/domain/entities/agent_visibility.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

class const AgentAvailabilitySummary({
  required final bool isEnabled,
  required final AgentVisibility visibility,
  final bool isSaved = true,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      TextLocale(
        isSaved ? LocaleKeys.authoring_saved : LocaleKeys.authoring_draft,
      ),
      TextLocale(
        isEnabled
            ? LocaleKeys.authoring_enabled
            : LocaleKeys.authoring_disabled,
      ),
      if (isEnabled && visibility.appearsInChatSelector)
        const TextLocale(LocaleKeys.agents_available_chat),
      if (isEnabled && visibility.appearsInSubAgentList)
        const TextLocale(LocaleKeys.agents_available_delegation),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}
