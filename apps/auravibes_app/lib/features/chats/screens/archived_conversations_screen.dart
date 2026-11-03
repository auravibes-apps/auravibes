import 'package:auravibes_app/features/chats/widgets/chat_list_widget.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ArchivedConversationsScreen({
  required final String workspaceId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScreen(
    child: _ArchivedConversationsBody(workspaceId: workspaceId),
    appBar: const AuraAppBarWithDrawer(
      title: TextLocale(LocaleKeys.chats_screens_archived_conversations_title),
    ),
  );
}

class const _ArchivedConversationsBody({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (_isCloudWorkspace(ref)) _cloudArchiveNotice(context),
        Expanded(
          child: ChatListWidget(workspaceId: workspaceId, scope: .archived),
        ),
      ],
    );
  }

  bool _isCloudWorkspace(WidgetRef ref) =>
      ref
          .watch(workspaceSessionForRouteProvider(workspaceId))
          .asData
          ?.value
          .cloud !=
      null;

  Widget _cloudArchiveNotice(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 16, top: 16, end: 16),
    child: AuraCallout(
      title: LocaleKeys.chats_screens_archived_conversations_cloud_notice_title
          .tr(context: context),
      description: LocaleKeys.chats_screens_archived_conversations_cloud_notice
          .tr(context: context),
      icon: Icons.info_outline,
    ),
  );
}
