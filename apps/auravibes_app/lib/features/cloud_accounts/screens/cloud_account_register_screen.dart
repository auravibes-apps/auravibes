// ignore_for_file: type=lint

import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_register_form.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CloudAccountRegisterScreen extends StatelessWidget {
  const CloudAccountRegisterScreen({
    required this.workspaceId,
    required this.returnPath,
    super.key,
  });

  final String workspaceId;
  final String? returnPath;

  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.workspace_management_cloud_register),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CloudAccountRegisterForm(
            onSignedIn: (account) => _complete(context, account),
          ),
          const SizedBox(height: 12),
          AuraButton(
            onPressed: () => context.go(
              CloudAccountLoginRoute(
                workspaceId: workspaceId,
                returnPath: returnPath,
              ).location,
            ),
            child: const TextLocale(LocaleKeys.cloud_accounts_login_existing),
            variant: AuraButtonVariant.outlined,
          ),
        ],
      ),
    );
  }

  void _complete(BuildContext context, CloudAccountSession _) {
    final path = returnPath;
    if (path == null || path.isEmpty) {
      context.go(CloudAccountsRoute(workspaceId: workspaceId).location);

      return;
    }

    context.go(path);
  }
}
