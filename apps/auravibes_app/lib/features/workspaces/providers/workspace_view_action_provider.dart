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
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/features/workspaces/usecases/edit_workspace_records_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/submit_workspace_view_action_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/misc.dart' show FutureProviderFamily;
import 'package:riverpod/riverpod.dart';

const _maximumFormBytes = 131072;

abstract final class WorkspaceViewActionProvider {
  static Future<SubmitWorkspaceViewActionUsecase> build(
    Ref ref,
    String workspaceId,
  ) => _WorkspaceViewActionSetup(ref, workspaceId).build();

  static Future<WorkspaceViewRepository> _cloudViews(
    Ref ref,
    WorkspaceSession session,
  ) async {
    final cloud = await _cloudWorkspace(ref, session);

    return CloudWorkspaceViewRepository(
      cloud.gateway.client,
      cloud.workspace.cloudWorkspaceId,
    );
  }

  static WorkspaceConnectorActionExecutor _localConnector(
    Ref ref,
    WorkspaceViewRepository views,
  ) => _LocalWorkspaceViewConnector(
    views: views,
    commands: ref.watch(connectorCommandUsecaseProvider),
  ).call;

  static WorkspaceConnectorActionExecutor _cloudConnector(
    Ref ref,
    WorkspaceSession session,
  ) => _CloudWorkspaceViewConnector(ref: ref, session: session).call;

  static Future<
    ({CloudWorkspaceStateGateway gateway, CloudWorkspaceRef workspace})
  >
  _cloudWorkspace(Ref ref, WorkspaceSession session) async {
    final gateway = await ref.watch(
      cloudWorkspaceStateGatewayProvider(session).future,
    );
    final workspace = session.cloud;
    if (!ref.mounted || gateway == null || workspace == null) {
      throw const WorkspaceTableException(denied: true);
    }

    return (gateway: gateway, workspace: workspace);
  }

  static Future<void> _requireViewRevision(
    WorkspaceViewRepository views,
    String viewId,
    int expectedRevision,
  ) async {
    final view = await views.read(viewId);
    if (view.revision != expectedRevision) {
      throw const WorkspaceTableException(conflict: true);
    }
  }

  static Map<String, Object?> _arguments(
    WorkspaceConnectorActionRequest request,
  ) {
    if (utf8.encode(jsonEncode(request.formValues)).length >
        _maximumFormBytes) {
      throw const WorkspaceViewFormValidationException({'/': 'tooLarge'});
    }
    final action = request.action;
    final toolId = action.toolId;
    final revision = action.revision;
    if (toolId == null || revision == null) {
      throw const WorkspaceTableException();
    }

    return {
      'toolId': toolId,
      'revision': revision,
      'args': request.arguments,
      'connectionId': ?action.connectionId,
    };
  }
}

final FutureProviderFamily<SubmitWorkspaceViewActionUsecase, String>
workspaceViewActionUsecaseProvider =
    FutureProvider.family<SubmitWorkspaceViewActionUsecase, String>(
      WorkspaceViewActionProvider.build,
    );

class const _WorkspaceViewActionSetup(final Ref ref, final String workspaceId) {
  Future<SubmitWorkspaceViewActionUsecase> build() async {
    final session = await _session();
    final usecases = await _tableUsecases();
    final views = await _views(session);

    return _assemble(session, usecases, views);
  }

  Future<WorkspaceSession> _session() async {
    final session = await ref.watch(
      workspaceSessionForRouteProvider(workspaceId).future,
    );
    if (!ref.mounted) throw const WorkspaceTableException(denied: true);

    return session;
  }

  Future<
    ({
      OrganizeWorkspaceTablesUsecase tables,
      EditWorkspaceRecordsUsecase editRecords,
    })
  >
  _tableUsecases() async => (
    tables: await ref.watch(workspaceTableUsecaseProvider(workspaceId).future),
    editRecords: await ref.watch(
      workspaceRecordBatchUsecaseProvider(workspaceId).future,
    ),
  );

  Future<WorkspaceViewRepository> _views(WorkspaceSession session) {
    if (session.cloud != null) {
      return WorkspaceViewActionProvider._cloudViews(ref, session);
    }

    return Future.value(
      LocalWorkspaceViewRepository(ref.watch(appDatabaseProvider), workspaceId),
    );
  }

  SubmitWorkspaceViewActionUsecase _assemble(
    WorkspaceSession session,
    ({
      OrganizeWorkspaceTablesUsecase tables,
      EditWorkspaceRecordsUsecase editRecords,
    })
    usecases,
    WorkspaceViewRepository views,
  ) => SubmitWorkspaceViewActionUsecase(
    views: views,
    tables: usecases.tables,
    editRecords: usecases.editRecords,
    executeConnector: session.cloud == null
        ? WorkspaceViewActionProvider._localConnector(ref, views)
        : WorkspaceViewActionProvider._cloudConnector(ref, session),
  );
}

class const _LocalWorkspaceViewConnector({
  required final WorkspaceViewRepository views,
  required final ConnectorCommandUsecase commands,
}) {
  Future<Object?> call(WorkspaceConnectorActionRequest request) async {
    await WorkspaceViewActionProvider._requireViewRevision(
      views,
      request.viewId,
      request.expectedRevision,
    );
    final connectorArguments = WorkspaceViewActionProvider._arguments(request);

    return await commands.call(
      workspaceId: request.workspaceId,
      commandName: executeConnectorToolName,
      arguments: connectorArguments,
      operationId: request.operationId,
    );
  }
}

class const _CloudWorkspaceViewConnector({
  required final Ref ref,
  required final WorkspaceSession session,
}) {
  Future<Object?> call(WorkspaceConnectorActionRequest request) async {
    final cloud = await WorkspaceViewActionProvider._cloudWorkspace(
      ref,
      session,
    );
    final result = await cloud.gateway.client.workspaceView.submitAction(
      cloud.workspace.cloudWorkspaceId,
      request.viewId,
      request.expectedRevision,
      jsonEncode(request.formValues),
      request.operationId,
    );

    return jsonDecode(result);
  }
}
