import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/widgets/chat_readiness_summary.dart';
import 'package:auravibes_app/features/intro/notifiers/intro_session_notifier.dart';
import 'package:auravibes_app/features/intro/widgets/intro_welcome_pager.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/models/widgets/compact_workspace_model_selector.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_edit_screen.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_setup_result.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_creation_draft_notifier.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_setup_content.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/setup_page_frame.dart';
import 'package:auravibes_app/widgets/setup_page_transition.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _IntroSavedStage { readiness, provider, connections, edit }

class const IntroScreen({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  static const _lastWelcomePage = 2;
  final _pages = PageController();
  final _providerExitGuard = DraftExitGuard();
  WorkspaceSetupResult? _result;
  WorkspaceSetupStage _setupStage = .chooser;
  _IntroSavedStage _savedStage = .readiness;
  bool _pending = false;
  bool _reverse = false;
  String _editingConnection = '';

  @override
  void dispose() {
    _pages.dispose();
    _providerExitGuard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _watchIntroState(ref, _result);

    return _IntroJourneyFrame(
      child: _IntroJourneyContent(
        state: this,
        onPendingChanged: (pending) => setState(() => _pending = pending),
      ),
    );
  }

  Widget _frame(SetupPagePresentation page) =>
      SetupPageFrame(page: page, key: page.key);

  void _changeSetupStage(WorkspaceSetupStage stage) {
    ref.read(introSessionProvider.notifier).begin();
    setState(() => _setupStage = stage);
  }

  void _returnToWelcome() {
    if (_pending || !_pages.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      _pages.jumpToPage(_lastWelcomePage);
    } else {
      final _ = _pages.animateToPage(
        _lastWelcomePage,
        duration: context.auraTheme.animation.slow,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _completeWorkspace(WorkspaceSetupResult result) => setState(() {
    _result = result;
    _pending = false;
    _savedStage = .readiness;
    _reverse = false;
  });

  void _changeSavedStage(_IntroSavedStage stage, {bool reverse = false}) =>
      setState(() {
        _savedStage = stage;
        _reverse = reverse;
      });

  void _leaveProvider(String workspaceId) {
    ref.read(addModelProviderStateProvider(workspaceId).notifier).reset();
    _providerExitGuard.releaseApproval(restoreFocus: false);
    _changeSavedStage(.readiness, reverse: true);
  }

  void _openChat(String workspaceId, String? selection) {
    if (selection == null) {
      ref.read(newChatProvider(workspaceId).notifier).setModelId(null);
    }
    NewChatRoute(
      workspaceId: workspaceId,
      modelSelectionId: selection,
    ).go(context);
    ref.read(introSessionProvider.notifier).finish();
  }
}

void _watchIntroState(WidgetRef ref, WorkspaceSetupResult? result) {
  ref
    ..watch(workspaceCreationDraftProvider('intro'))
    ..watch(introSessionProvider);
  if (result != null) {
    final _ = ref.watch(newChatProvider(result.workspace.id));
  }
}

class const _IntroJourneyFrame({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppScreen(
    child: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
          child: child,
        ),
      ),
    ),
    variant: .aurora,
  );
}

class _IntroJourneyContent extends StatelessWidget {
  new({
    required _IntroScreenState state,
    required ValueChanged<bool> onPendingChanged,
  }) : _child = SetupPageTransition(
         child: KeyedSubtree(
           key: ValueKey(state._result?.workspace.id),
           child: switch (state._result) {
             null => _IntroSetup(
               state: state,
               onPendingChanged: onPendingChanged,
             ),
             final result => _IntroSavedWorkspace(state: state, result: result),
           },
         ),
       );
  final Widget _child;
  @override
  Widget build(BuildContext context) => _child;
}

class _IntroSetup extends StatelessWidget {
  new({
    required _IntroScreenState state,
    required ValueChanged<bool> onPendingChanged,
  }) : _child = IntroWelcomePager(
         setup: WorkspaceSetupContent(
           taskId: 'intro',
           onCompleted: state._completeWorkspace,
           onReturn: state._returnToWelcome,
           showIntroRouteChooser: true,
           pageBuilder: state._frame,
           onStageChanged: state._changeSetupStage,
           onPendingChanged: onPendingChanged,
           key: const Key('intro_workspace_setup'),
         ),
         canNavigate: state._setupStage == .chooser && !state._pending,
         controller: state._pages,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _IntroSavedWorkspace({
  required final _IntroScreenState state,
  required final WorkspaceSetupResult result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SetupPageTransition(
      child: KeyedSubtree(
        key: ValueKey(state._savedStage),
        child: _IntroSavedStageContent(state: state, result: result),
      ),
      reverse: state._reverse,
    );
  }
}

class const _IntroSavedStageContent({
  required final _IntroScreenState state,
  required final WorkspaceSetupResult result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workspaceId = result.workspace.id;

    return switch (state._savedStage) {
      .readiness => _IntroReadyStage(state: state, result: result),
      .provider => _IntroProviderSetup(state: state, workspaceId: workspaceId),
      .connections => _IntroConnectionsStage(
        state: state,
        workspaceId: workspaceId,
      ),
      .edit => _IntroEditStage(state: state, workspaceId: workspaceId),
    };
  }
}

class const _IntroReadyStage({
  required final _IntroScreenState state,
  required final WorkspaceSetupResult result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _IntroReadiness(
    result: result,
    onAddProvider: () => state._changeSavedStage(.provider),
    onReviewConnections: () => state._changeSavedStage(.connections),
    onContinue: (selection) => state._openChat(result.workspace.id, selection),
  );
}

class const _IntroConnectionsStage({
  required final _IntroScreenState state,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _IntroConnections(
    workspaceId: workspaceId,
    onBack: () => state._changeSavedStage(.readiness, reverse: true),
    onAdd: () => state._changeSavedStage(.provider),
    onEdit: (connection) {
      state._editingConnection = connection;
      state._changeSavedStage(.edit);
    },
  );
}

class const _IntroEditStage({
  required final _IntroScreenState state,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ServiceConnectionEditScreen(
    workspaceId: workspaceId,
    connectionId: state._editingConnection,
    pageBuilder: state._frame,
    onReturn: () => state._changeSavedStage(.connections, reverse: true),
  );
}

class const _IntroProviderSetup({
  required final _IntroScreenState state,
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = _watchIntroProviderSaving(ref, workspaceId);
    _bindIntroProviderGuard(state, ref, workspaceId);

    return _IntroProviderForm(
      state: state,
      workspaceId: workspaceId,
      saving: saving,
    );
  }
}

bool _watchIntroProviderSaving(WidgetRef ref, String workspaceId) {
  final saving = ref.watch(addCredentialsModelMutationProvider).isPending;
  final verifying = ref.watch(verifyModelProviderMutationProvider).isPending;
  final testing = ref
      .watch(addModelProviderStateProvider(workspaceId))
      .isTestingConnection;

  return saving || verifying || testing;
}

bool _readIntroProviderSaving(WidgetRef ref, String workspaceId) =>
    ref.read(addCredentialsModelMutationProvider).isPending ||
    ref.read(verifyModelProviderMutationProvider).isPending ||
    ref.read(addModelProviderStateProvider(workspaceId)).isTestingConnection;

void _bindIntroProviderGuard(
  _IntroScreenState state,
  WidgetRef ref,
  String workspaceId,
) {
  state._providerExitGuard.bind(
    readers: (
      isDirty: () => ref
          .read(addModelProviderStateProvider(workspaceId))
          .hasUnsavedChanges,
      isSaving: () => _readIntroProviderSaving(ref, workspaceId),
    ),
    callbacks: .new(onReturn: (_) => state._leaveProvider(workspaceId)),
    preferReturn: true,
  );
}

class const _IntroProviderForm({
  required final _IntroScreenState state,
  required final String workspaceId,
  required final bool saving,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DraftExitScope(
    guard: state._providerExitGuard,
    child: AddModelProviderWidget(
      workspaceId: workspaceId,
      routeExitGuard: state._providerExitGuard,
      onCreated: () => state._leaveProvider(workspaceId),
      onCancel: saving ? null : () => state._leaveProvider(workspaceId),
      pageBuilder: state._frame,
      showHeader: false,
    ),
  );
}

class const _IntroReadiness({
  required final WorkspaceSetupResult result,
  required final VoidCallback onAddProvider,
  required final VoidCallback onReviewConnections,
  required final ValueChanged<String?> onContinue,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _IntroReadinessPage(
      readiness: this,
      data: _watchIntroReadiness(ref, result.workspace.id),
    );
  }
}

typedef _IntroReadinessData = ({
  AsyncValue<Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>>
  models,
  AsyncValue<List<ModelConnectionEntity>> connections,
  String? selected,
  String workspaceId,
});

_IntroReadinessData _watchIntroReadiness(WidgetRef ref, String workspaceId) => (
  workspaceId: workspaceId,
  selected: ref.watch(newChatProvider(workspaceId)).modelId,
  models: ref.watch(
    listModelsGroupedByProviderProvider(workspaceId: workspaceId),
  ),
  connections: ref.watch(chatModelConnectionsProvider(workspaceId)),
);

bool _introStreamsReady(_IntroReadinessData data) =>
    !data.models.isLoading &&
    !data.connections.isLoading &&
    !data.models.hasError &&
    !data.connections.hasError;

bool _introCanChat(_IntroReadinessData data) {
  if (!_introStreamsReady(data)) return false;

  return data.models.value?.values
          .expand((group) => group)
          .any((model) => _introModelAuthorized(model, data)) ??
      false;
}

bool _introModelAuthorized(
  WorkspaceModelSelectionWithConnectionEntity model,
  _IntroReadinessData data,
) =>
    model.workspaceModelSelection.id == data.selected &&
    model.modelConnection.workspaceId == data.workspaceId &&
    _introConnectionHasKey(model.modelConnection.id, data.connections.value);

bool _introConnectionHasKey(
  String id,
  List<ModelConnectionEntity>? connections,
) =>
    connections?.any(
      (connection) => connection.id == id && connection.hasKey,
    ) ??
    false;

class _IntroReadinessPage extends StatelessWidget {
  new({required _IntroReadiness readiness, required _IntroReadinessData data})
    : _child = SetupPageFrame(
        page: .new(
          key: const Key('intro_readiness'),
          heading: AuraText(
            child: TextLocale(switch (readiness.result.outcome) {
              .created => 'intro_flow.ready.title',
              .connected => 'intro_flow.ready.connected_title',
              .joined => 'intro_flow.ready.joined_title',
            }),
            style: .heading4,
          ),
          description: AuraText(
            child: Text(readiness.result.workspace.name),
            style: .bodyLarge,
          ),
          body: _IntroReadinessBody(
            workspaceId: data.workspaceId,
            selected: data.selected,
            showModels: data.models.value?.isNotEmpty ?? false,
            onAddProvider: readiness.onAddProvider,
            onReviewConnections: readiness.onReviewConnections,
          ),
          actions: _IntroReadinessActions(
            canChat: _introCanChat(data),
            selected: data.selected,
            onContinue: readiness.onContinue,
          ),
        ),
      );
  final Widget _child;
  @override
  Widget build(BuildContext context) => _child;
}

class const _IntroReadinessBody({
  required final String workspaceId,
  required final String? selected,
  required final bool showModels,
  required final VoidCallback onAddProvider,
  required final VoidCallback onReviewConnections,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: .stretch,
    children: [
      ChatReadinessSummary(
        workspaceId: workspaceId,
        onAddProvider: onAddProvider,
        onReviewConnections: onReviewConnections,
      ),
      if (showModels) ...[
        const SizedBox(height: 24),
        CompactWorkspaceModelSelector(
          workspaceId: workspaceId,
          workspaceModelSelectionId: selected,
          onChanged: ref.read(newChatProvider(workspaceId).notifier).setModelId,
        ),
      ],
      const SizedBox(height: 24),
      const TextLocale('intro_flow.ai.explore_hint'),
    ],
  );
}

class const _IntroReadinessActions({
  required final bool canChat,
  required final String? selected,
  required final ValueChanged<String?> onContinue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      AuraButton(
        onPressed: () {
          if (canChat) onContinue(selected);
        },
        child: const TextLocale('intro_flow.ai.start_chat'),
        key: const Key('intro_start_chat_button'),
        disabled: !canChat,
      ),
      const SizedBox(height: 8),
      AuraButton(
        onPressed: () => onContinue(null),
        child: const TextLocale('intro_flow.ai.explore'),
        key: const Key('intro_skip_ai_button'),
        variant: .ghost,
      ),
    ],
  );
}

class const _IntroConnections({
  required final String workspaceId,
  required final VoidCallback onBack,
  required final VoidCallback onAdd,
  required final ValueChanged<String> onEdit,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SetupPageFrame(
      page: .new(
        key: const Key('intro_connections'),
        heading: const AuraText(
          child: TextLocale('chat_readiness.review_connections'),
          style: .heading4,
        ),
        description: const TextLocale('intro_flow.ai.review_hint'),
        body: _IntroConnectionList(workspaceId: workspaceId, onEdit: onEdit),
        onBack: onBack,
        actions: AuraButton(
          onPressed: onAdd,
          child: const TextLocale('models_screens.add_provider.open_button'),
        ),
      ),
    );
  }
}

class const _IntroConnectionList({
  required final String workspaceId,
  required final ValueChanged<String> onEdit,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(chatModelConnectionsProvider(workspaceId));

    return switch (connections) {
      AsyncData(:final value) => Column(
        crossAxisAlignment: .stretch,
        children: [
          for (final connection in value) ...[
            _IntroConnectionCard(connection: connection, onEdit: onEdit),
            const SizedBox(height: 12),
          ],
        ],
      ),
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError() => _IntroConnectionError(workspaceId: workspaceId),
    };
  }
}

class const _IntroConnectionCard({
  required final ModelConnectionEntity connection,
  required final ValueChanged<String> onEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        AuraText(child: Text(connection.name), style: .bodyLarge),
        AuraButton(
          onPressed: () => onEdit(connection.id),
          child: const TextLocale('common.edit'),
          variant: .outlined,
        ),
      ],
    ),
  );
}

class const _IntroConnectionError({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      const TextLocale('chat_readiness.attention'),
      AuraButton(
        onPressed: () =>
            ref.invalidate(chatModelConnectionsProvider(workspaceId)),
        child: const TextLocale('route_state.retry'),
      ),
    ],
  );
}
