import 'package:auravibes_app/features/chats/agent_adapters/mcp_scoped_verification_runner.dart';
import 'package:auravibes_app/features/chats/providers/scoped_verification_provider.dart';
import 'package:auravibes_app/features/settings/services/scoped_verification_configuration.dart';
import 'package:auravibes_app/features/settings/usecases/save_scoped_verification_settings_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

final scopedVerificationConfigurationProvider =
    Provider<ScopedVerificationConfiguration>(
      (ref) => ScopedVerificationConfiguration(ref.watch(appDatabaseProvider)),
    );

// ignore: specify_nonobvious_property_types - Riverpod family type.
final scopedVerificationSettingsProvider = StreamProvider.autoDispose
    .family<ScopedVerificationSettings, String>((ref, workspaceId) async* {
      final session = await ref.watch(
        workspaceSessionForRouteProvider(workspaceId).future,
      );
      if (session.cloud != null) {
        yield ScopedVerificationSettings();

        return;
      }
      yield* ref
          .watch(workspaceVerificationRepositoryProvider)
          .watchSettings(workspaceId);
    });

// ignore: specify_nonobvious_property_types - Riverpod family type.
final scopedVerificationToolsProvider = StreamProvider.autoDispose
    .family<List<ScopedVerificationToolOption>, String>((
      ref,
      workspaceId,
    ) async* {
      final session = await ref.watch(
        workspaceSessionForRouteProvider(workspaceId).future,
      );
      if (session.cloud != null) {
        yield const [];

        return;
      }
      yield* ref
          .watch(scopedVerificationConfigurationProvider)
          .watchTools(workspaceId);
    });

// ignore: specify_nonobvious_property_types - Riverpod family type.
final saveScopedVerificationSettingsUsecaseProvider = Provider.autoDispose
    .family<SaveScopedVerificationSettingsUsecase, String>((ref, workspaceId) {
      final configuration = ref.watch(scopedVerificationConfigurationProvider);
      final repository = ref.watch(workspaceVerificationRepositoryProvider);
      final container = ref.container;

      return SaveScopedVerificationSettingsUsecase(
        repository: repository,
        validateBindings: (id, settings) async =>
            id == workspaceId && await configuration.validate(id, settings),
        probeCapabilities: (id, settings, deadline) async {
          final target = (await configuration.tools(id))
              .where(
                (tool) =>
                    tool.id == settings.runnerToolId &&
                    tool.serverId == settings.mcpServerId &&
                    tool.canRunUnattended,
              )
              .firstOrNull;
          if (target == null || id != workspaceId) {
            throw StateError('Verification binding unavailable.');
          }
          if (!deadline.isAfter(DateTime.now().toUtc())) {
            throw StateError('Verification probe expired.');
          }
          final cancellation = AgentCancellationScope();
          // A separate non-interactive connection belongs to each save.
          final session = await container
              .read(mcpConnectionProvider.notifier)
              .openVerificationSession(
                mcpServerId: settings.mcpServerId,
                toolIdentifier: target.toolIdentifier,
                deadline: deadline,
                cancellation: cancellation,
              );
          try {
            final remaining = deadline.difference(DateTime.now().toUtc());
            if (remaining <= .zero || cancellation.isCancellationRequested) {
              throw StateError('Verification probe expired.');
            }
            final runner = McpScopedVerificationRunner(
              mcpServerId: settings.mcpServerId,
              editMcpServerId: settings.mcpServerId,
              runnerToolIdentifier: target.toolIdentifier,
              caller: session.call,
              isAllowed: () async =>
                  deadline.isAfter(DateTime.now().toUtc()) &&
                  await configuration.validate(id, settings),
              onClose: session.close,
            );
            // This path never starts a request or configured command.

            return await runner.capabilities().timeout(remaining);
          } finally {
            cancellation.requestStop();
            session.close();
          }
        },
      );
    });
