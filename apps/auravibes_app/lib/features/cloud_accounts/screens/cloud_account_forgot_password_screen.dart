// ignore_for_file: type=lint

import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_forgot_password_form.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class const CloudAccountForgotPasswordScreen({
  required final String workspaceId,
  required final String? returnPath,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CloudAccountForgotPasswordForm(
            onFinished: () => context.go(
              CloudAccountLoginRoute(
                workspaceId: workspaceId,
                returnPath: returnPath,
              ).location,
            ),
          ),
        ],
      ),
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.cloud_accounts_forgot_password),
      ),
    );
  }
}
