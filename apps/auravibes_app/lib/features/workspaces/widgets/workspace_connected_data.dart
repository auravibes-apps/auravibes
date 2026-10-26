import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
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
    if (state.isLoading) return _Waiting(stale: state.hasValue);

    return switch (state) {
      AsyncData(:final value) => _Fetched(workspaceId, data, value),
      AsyncError(:final error) => TextLocale(_errorKey(error)),
      AsyncLoading() => const _Waiting(stale: false),
    };
  }
}

class const _Waiting({required final bool stale}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: .min,
      children: [
        const CircularProgressIndicator(),
        TextLocale(
          stale
              ? LocaleKeys.workspace_relational_stale
              : LocaleKeys.workspace_relational_loading,
        ),
      ],
    ),
  );
}

class const _Fetched(
  final String workspaceId,
  final WorkspaceViewData? data,
  final WorkspaceConnectedResult result,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      const TextLocale(LocaleKeys.workspace_connected_title),
      const TextLocale(LocaleKeys.workspace_connected_disclosure),
      _Freshness(result.fetchedAt),
      _Projected(workspaceId, data, result.value),
    ],
  );
}

class const _Freshness(final DateTime time) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    LocaleKeys.workspace_connected_freshness.tr(
      namedArgs: {'time': time.toLocal().toString()},
    ),
  );
}

class const _Result(final Object? value) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SelectableText(const JsonEncoder.withIndent('  ').convert(value));
}

String _errorKey(Object error) => switch (error) {
  WorkspaceTableException(denied: true) =>
    LocaleKeys.workspace_connected_denied,
  WorkspaceTableException() => LocaleKeys.workspace_connected_repair,
  CloudWorkspaceException(code: .staleRevision) =>
    LocaleKeys.workspace_connected_changed,
  WorkspaceConnectedReadException(:final code) => _codeKey(code),
  CloudWorkspaceException(
    code: .permissionDenied || .membershipRequired || .authenticationRequired,
  ) =>
    LocaleKeys.workspace_connected_denied,
  AgentToolExecutionFailure() => _codeKey(_commandCode(error)),
  _ => LocaleKeys.workspace_connected_failed,
};
String _codeKey(String? code) => switch (code) {
  'denied' || 'tool_access_denied' => LocaleKeys.workspace_connected_denied,
  'repair' ||
  'stale_contract' ||
  'invalid_tool_arguments' => LocaleKeys.workspace_connected_repair,
  'disconnected' => LocaleKeys.workspace_connected_disconnected,
  final String value when value.startsWith('connection_') =>
    LocaleKeys.workspace_connected_disconnected,
  _ => LocaleKeys.workspace_connected_failed,
};
String? _commandCode(AgentToolExecutionFailure error) {
  try {
    return switch (jsonDecode(error.responseRaw)) {
      {'error': {'code': final String code}} => code,
      _ => null,
    };
  } on FormatException {
    return null;
  }
}

class const _Projected(
  final String workspaceId,
  final WorkspaceViewData? data,
  final Object? value,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (_empty(value) && data?.view.action == null) {
      return const TextLocale(LocaleKeys.workspace_connected_empty);
    }
    final source = data;
    if (source == null || !source.view.isConnectedOnly) return _Result(value);

    return _ConnectedView(
      workspaceId: workspaceId,
      source: source,
      value: value,
    );
  }
}

class const _ConnectedView({
  required final String workspaceId,
  required final WorkspaceViewData source,
  required final Object? value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    try {
      return WorkspaceViewSurface(
        data: source,
        connectedModel: _empty(value)
            ? const <String, Object?>{}
            : ProjectConnectedWorkspaceViewUsecase.call(
                value,
                source.view.bindings,
              ),
        workspaceId: workspaceId,
      );
    } on Object {
      return const TextLocale(LocaleKeys.workspace_connected_repair);
    }
  }
}

bool _empty(Object? value) => switch (value) {
  null || '' => true,
  final List<Object?> values => values.isEmpty,
  final Map<Object?, Object?> values => values.isEmpty,
  final String text => const {'[]', '{}', 'null'}.contains(text.trim()),
  _ => false,
};
