import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CloudAccountAddScreen extends StatelessWidget {
  const CloudAccountAddScreen({
    required this.workspaceId,
    required this.returnPath,
    super.key,
  });

  final String workspaceId;
  final String? returnPath;

  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_add_body),
          ),
          const AuraText(
            child: TextLocale(LocaleKeys.cloud_accounts_return_hint),
            style: AuraTextStyle.bodySmall,
          ),
          const SizedBox(height: 16),
          AuraButton(
            onPressed: () => context.go(
              CloudAccountLoginRoute(
                workspaceId: workspaceId,
                returnPath: _returnPath,
              ).location,
            ),
            child: const TextLocale(LocaleKeys.cloud_accounts_login_existing),
          ),
          const SizedBox(height: 8),
          AuraButton(
            onPressed: () => context.go(
              CloudAccountRegisterRoute(
                workspaceId: workspaceId,
                returnPath: _returnPath,
              ).location,
            ),
            child: const TextLocale(LocaleKeys.cloud_accounts_create_new),
            variant: AuraButtonVariant.outlined,
          ),
        ],
      ),
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.cloud_accounts_add_title),
      ),
    );
  }

  String get _returnPath {
    final path = returnPath;
    if (path != null && path.isNotEmpty) return path;

    return CloudAccountsRoute(workspaceId: workspaceId).location;
  }
}
