import 'package:auravibes_app/data/repositories/workspace_verification_repository.dart';
import 'package:auravibes_app/features/chats/agent_adapters/create_mcp_scoped_verification_runner.dart';
import 'package:auravibes_app/features/chats/agent_adapters/scoped_verification_cancellation.dart';
import 'package:auravibes_app/features/chats/agent_adapters/scoped_verification_identity.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/verify_reported_edits_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/resolve_tool_approval_decision_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:riverpod/riverpod.dart';

final workspaceVerificationRepositoryProvider =
    Provider<WorkspaceVerificationRepository>(
      (ref) => WorkspaceVerificationRepository(ref.watch(appDatabaseProvider)),
    );
final scopedVerificationCancellationProvider =
    Provider<ScopedVerificationCancellation>(
      (ref) => ScopedVerificationCancellation(
        ref.watch(agentCancellationRuntimeProvider),
      ),
    );

final scopedVerificationProvider = Provider<VerifyReportedEditsUsecase>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final repository = ref.watch(workspaceVerificationRepositoryProvider);
  final container = ref.container;
  final factory = CreateMcpScopedVerificationRunner(
    database: database,
    repository: repository,
    openSession: (input, target) async {
      final session = await container
          .read(mcpConnectionProvider.notifier)
          .openVerificationSession(
            mcpServerId: input.settings.mcpServerId,
            toolIdentifier: target.toolIdentifier,
            deadline: input.request.deadline,
            cancellation: input.cancellation,
          );

      return (call: session.call, close: session.close);
    },
    permission: (request) => container
        .read(resolveToolApprovalDecisionUsecaseProvider(request.workspaceId))
        .callForRequest(request),
  );

  return VerifyReportedEditsUsecase(
    repository: repository,
    resolveIdentity: ScopedVerificationIdentityResolver(database).call,
    createRunner: factory.call,
    cancellation: ref.watch(scopedVerificationCancellationProvider),
  );
});
