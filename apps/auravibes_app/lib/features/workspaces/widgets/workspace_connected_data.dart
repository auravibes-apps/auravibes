import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_connected_view_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/project_connected_workspace_view_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_surface.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart'
    show CloudWorkspaceException, WorkspaceConnectedReadException;
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceConnectedData({
  required final String workspaceId,
  required final String viewId,
  final WorkspaceViewData? data,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      workspaceConnectedViewProvider(workspaceId, viewId),
    );
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            const CircularProgressIndicator(),
            TextLocale(
              state.hasValue
                  ? LocaleKeys.workspace_relational_stale
                  : LocaleKeys.workspace_relational_loading,
            ),
          ],
        ),
      );
    }

    return switch (state) {
      AsyncData(:final value) => Column(
        crossAxisAlignment: .start,
        children: [
          const TextLocale(LocaleKeys.workspace_connected_title),
          const TextLocale(LocaleKeys.workspace_connected_disclosure),
          Text(
            LocaleKeys.workspace_connected_freshness.tr(
              namedArgs: {'time': value.fetchedAt.toLocal().toString()},
            ),
          ),
          _Projected(data, value.value),
        ],
      ),
      AsyncError(:final error) => TextLocale(_errorKey(error)),
      AsyncLoading() => const CircularProgressIndicator(),
    };
  }
}

class const _Result(final Object? value) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      value == null || value == '' || (value is List && (value as List).isEmpty)
      ? const TextLocale(LocaleKeys.workspace_connected_empty)
      : SelectableText(const JsonEncoder.withIndent('  ').convert(value));
}

String _errorKey(Object error) {
  if (error is WorkspaceConnectedReadException) {
    return switch (error.code) {
      'denied' => LocaleKeys.workspace_connected_denied,
      'disconnected' => LocaleKeys.workspace_connected_disconnected,
      'repair' => LocaleKeys.workspace_connected_repair,
      _ => LocaleKeys.workspace_connected_failed,
    };
  }
  if (error is CloudWorkspaceException &&
      {
        'permissionDenied',
        'membershipRequired',
        'authenticationRequired',
      }.contains(error.code.name)) {
    return LocaleKeys.workspace_connected_denied;
  }
  if (error is AgentToolExecutionFailure) {
    try {
      final data = jsonDecode(error.responseRaw) as Map<String, dynamic>;
      final code = (data['error'] as Map?)?['code'];
      if (code == 'tool_access_denied') {
        return LocaleKeys.workspace_connected_denied;
      }
      if (code is String && code.startsWith('connection_')) {
        return LocaleKeys.workspace_connected_disconnected;
      }
      if (code == 'stale_contract' || code == 'invalid_tool_arguments') {
        return LocaleKeys.workspace_connected_repair;
      }
    } on FormatException {
      return LocaleKeys.workspace_connected_failed;
    }
  }

  return LocaleKeys.workspace_connected_failed;
}

class const _Projected(final WorkspaceViewData? data, final Object? value)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final source = data;
    if (source == null || !source.view.isConnectedOnly) return _Result(value);
    try {
      return WorkspaceViewSurface(
        data: source,
        connectedModel: ProjectConnectedWorkspaceViewUsecase.call(
          value,
          source.view.bindings,
        ),
      );
    } on Object {
      return const TextLocale(LocaleKeys.workspace_connected_repair);
    }
  }
}
