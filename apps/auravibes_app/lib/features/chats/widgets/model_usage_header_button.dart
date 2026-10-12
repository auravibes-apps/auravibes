import 'package:auravibes_app/features/chats/widgets/model_usage_details_sheet.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const ModelUsageHeaderButton({
  required final String conversationId,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = LocaleKeys.chats_screens_chat_conversation_model_usage_open
        .tr();

    return AuraIconButton(
      icon: Icons.analytics_outlined,
      onPressed: () => _showDetails(context),
      key: key ?? const ValueKey<String>('model-usage-button'),
      semanticLabel: label,
      tooltip: label,
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => ModelUsageDetailsSheet(conversationId: conversationId),
      isScrollControlled: true,
      useSafeArea: true,
    );
  }
}
