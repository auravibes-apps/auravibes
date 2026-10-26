import 'dart:convert';

import 'package:auravibes_app/data/repositories/cloud_workspace_view_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/service_connections/usecases/connector_command_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_batch_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/submit_workspace_view_action_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/misc.dart' show FutureProviderFamily;
import 'package:riverpod/riverpod.dart';

final FutureProviderFamily<SubmitWorkspaceViewActionUsecase, String>
workspaceViewActionUsecaseProvider =
    FutureProvider.family<SubmitWorkspaceViewActionUsecase, String>((
      ref,
      workspaceId,
    ) async {
      final session = await ref.watch(
        workspaceSessionForRouteProvider(workspaceId).future,
      );
      if (!ref.mounted) throw const WorkspaceTableException(denied: true);
      final tables = await ref.watch(
        workspaceTableUsecaseProvider(workspaceId).future,
      );
      final editRecords = await ref.watch(
        workspaceRecordBatchUsecaseProvider(workspaceId).future,
      );
      final repository = session.cloud == null
          ? LocalWorkspaceViewRepository(
              ref.watch(appDatabaseProvider),
              workspaceId,
            )
          : await _cloudViews(ref, session);

      return SubmitWorkspaceViewActionUsecase(
        views: repository,
        tables: tables,
        editRecords: editRecords,
        executeConnector: session.cloud == null
            ? _localConnector(ref, repository)
            : _cloudConnector(ref, session),
      );
    });

Future<WorkspaceViewRepository> _cloudViews(
  Ref ref,
  WorkspaceSession session,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  final cloud = session.cloud;
  if (!ref.mounted || gateway == null || cloud == null) {
    throw const WorkspaceTableException(denied: true);
  }

  return CloudWorkspaceViewRepository(gateway.client, cloud.cloudWorkspaceId);
}

WorkspaceConnectorActionExecutor _localConnector(
  Ref ref,
  WorkspaceViewRepository views,
) {
  final commands = ref.watch(connectorCommandUsecaseProvider);

  return ({
    required workspaceId,
    required viewId,
    required expectedRevision,
    required action,
    required formValues,
    required arguments,
    required operationId,
  }) async {
    final current = await views.read(viewId);
    if (current.revision != expectedRevision) {
      throw const WorkspaceTableException(conflict: true);
    }
    if (utf8.encode(jsonEncode(formValues)).length > 131072) {
      throw const WorkspaceViewFormValidationException({'/': 'tooLarge'});
    }
    final toolId = action.toolId;
    final revision = action.revision;
    if (toolId == null || revision == null) {
      throw const WorkspaceTableException();
    }

    return await commands.call(
      workspaceId: workspaceId,
      commandName: executeConnectorToolName,
      arguments: {
        'toolId': toolId,
        'revision': revision,
        'args': arguments,
        'connectionId': ?action.connectionId,
      },
      operationId: operationId,
    );
  };
}

WorkspaceConnectorActionExecutor _cloudConnector(
  Ref ref,
  WorkspaceSession session,
) =>
    ({
      required workspaceId,
      required viewId,
      required expectedRevision,
      required action,
      required formValues,
      required arguments,
      required operationId,
    }) async {
      final gateway = await ref.watch(
        cloudWorkspaceStateGatewayProvider(session).future,
      );
      final cloud = session.cloud;
      if (!ref.mounted || gateway == null || cloud == null) {
        throw const WorkspaceTableException(denied: true);
      }
      final result = await gateway.client.workspaceView.submitAction(
        cloud.cloudWorkspaceId,
        viewId,
        expectedRevision,
        jsonEncode(formValues),
        operationId,
      );

      return jsonDecode(result);
    };
