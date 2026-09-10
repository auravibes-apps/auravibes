import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class const CloudAccountAddScreen({
  required final String workspaceId,
  required final String? returnPath,
  super.key,
}) extends StatelessWidget {
  String get _returnPath {
    final path = returnPath;
    if (path != null && path.isNotEmpty) return path;

    return CloudAccountsRoute(workspaceId: workspaceId).location;
  }

  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _CloudAccountAddContent(
        workspaceId: workspaceId,
        returnPath: _returnPath,
      ),
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.cloud_accounts_add_title),
      ),
    );
  }
}

class const _CloudAccountAddContent({
  required final String workspaceId,
  required final String returnPath,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _CloudAccountAddDescription(),
        const SizedBox(height: 16),
        _CloudAccountRouteButton(
          label: LocaleKeys.cloud_accounts_login_existing,
          workspaceId: workspaceId,
          returnPath: returnPath,
        ),
        const SizedBox(height: 8),
        _CloudAccountRouteButton(
          label: LocaleKeys.cloud_accounts_create_new,
          workspaceId: workspaceId,
          returnPath: returnPath,
          outlined: true,
        ),
      ],
    );
  }
}

class _CloudAccountAddDescription extends StatelessWidget {
  const _CloudAccountAddDescription();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: .start,
    children: [
      AuraText(child: TextLocale(LocaleKeys.cloud_accounts_add_body)),
      AuraText(
        child: TextLocale(LocaleKeys.cloud_accounts_return_hint),
        style: .bodySmall,
      ),
    ],
  );
}

class const _CloudAccountRouteButton({
  required final String label,
  required final String workspaceId,
  required final String returnPath,
  final bool outlined = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _CloudAccountAddButton(
    label: label,
    onPressed: () => context.go(
      (outlined
              ? CloudAccountRegisterRoute(
                  workspaceId: workspaceId,
                  returnPath: returnPath,
                )
              : CloudAccountLoginRoute(
                  workspaceId: workspaceId,
                  returnPath: returnPath,
                ))
          .location,
    ),
    outlined: outlined,
  );
}

class const _CloudAccountAddButton({
  required final String label,
  required final VoidCallback onPressed,
  final bool outlined = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: TextLocale(label),
    variant: outlined ? .outlined : .primary,
  );
}
