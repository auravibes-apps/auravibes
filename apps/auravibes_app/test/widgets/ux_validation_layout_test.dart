import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/agents/screens/agent_detail_screen.dart';
import 'package:auravibes_app/features/agents/screens/agents_screen.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/screens/archived_conversations_screen.dart';
import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/screens/chats_list_screen.dart';
import 'package:auravibes_app/features/chats/screens/message_bookmarks_screen.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_readiness_summary.dart';
import 'package:auravibes_app/features/chats/widgets/model_usage_details_sheet.dart';
import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_health.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_failure.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_email_delivery_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_add_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_forgot_password_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_login_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_register_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_accounts_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/intro/screens/intro_screen.dart';
import 'package:auravibes_app/features/markdown/screens/markdown_editor_screen.dart';
import 'package:auravibes_app/features/models/models/model_connection_store.dart';
import 'package:auravibes_app/features/models/models/model_provider_verification.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_connection_test_status.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_edit_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connections_screen.dart';
import 'package:auravibes_app/features/service_connections/usecases/test_mcp_connection_usecase.dart';
import 'package:auravibes_app/features/settings/screens/settings_screen.dart';
import 'package:auravibes_app/features/settings/screens/workspace_settings_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_resource_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skills_screen.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/screens/tools_screen.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_route_failure.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/create_workspace_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_management_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_setup_preflight_screen.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/services/cloud_auth_protocol.dart';
import 'package:auravibes_app/services/codex_oauth_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/app_with_responsive_drawer.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_app/widgets/route_recovery_view.dart';
import 'package:auravibes_app/widgets/setup_page_frame.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_file_drop/flutter_file_drop.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/ux_capture.dart';
import '../helpers/ux_validation_fixture.dart';

part '../helpers/intro_journey_capture.dart';

void main() {
  _registerIntroJourneyCaptures();
  tearDownAll(UxValidationFixture.closeDatabase);
  setUpAll(loadUxCaptureFonts);
  testWidgets('captures chat composer desktop file drop states', (
    tester,
  ) async {
    final previousDebugPrint = debugPrint;
    final previousDebugDefaultTargetPlatformOverride =
        debugDefaultTargetPlatformOverride;
    final previousDebugDoublePrecision = debugDoublePrecision;
    final previousDebugBrightnessOverride = debugBrightnessOverride;
    debugDefaultTargetPlatformOverride = .macOS;

    const size = Size(1280, 800);
    UxValidationFixture? fixture;
    try {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            const .new('flutter_file_drop/events'),
            .inline(
              onListen: (_, _) => Future<void>.value(),
              onCancel: (_) => Future<void>.value(),
            ),
          );
      final currentFixture = await UxValidationFixture.create();
      fixture = currentFixture;
      final route = NewChatRoute(workspaceId: currentFixture.workspaceId)
          .location;
      final _ = await currentFixture.pump(tester, route, size: size);

      expect(find.byType(ChatInputWidget), findsOneWidget);
      expect(find.byType(DropTarget), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureUxWidget(
        tester,
        'chat-composer-file-drop-idle',
        route,
        locale: 'en',
        size: size,
        scale: 1,
        dark: false,
        controlMeasurements: const {
          'platform': 'macOS native desktop target',
          'state': 'idle composer before file hover',
        },
      );

      tester
          .widget<DropTarget>(find.byType(DropTarget))
          .onMove
          ?.call(
            .new(
              globalPosition: .zero,
              localPosition: .zero,
              items: const [.new(kind: .file)],
            ),
          );
      await tester.pump();

      expect(find.text('Drop files to attach'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chat_input_drop_highlight')),
        findsOneWidget,
      );
      await captureUxWidget(
        tester,
        'chat-composer-file-drop-hover',
        route,
        locale: 'en',
        size: size,
        scale: 1,
        dark: false,
        controlMeasurements: const {
          'platform': 'macOS native desktop target',
          'state': 'file hover drop feedback',
        },
      );
      expect(tester.takeException(), isNull);
    } finally {
      try {
        if (fixture case final currentFixture?) {
          await currentFixture.close(tester);
        }
      } finally {
        debugPrint = previousDebugPrint;
        debugDefaultTargetPlatformOverride =
            previousDebugDefaultTargetPlatformOverride;
        debugDoublePrecision = previousDebugDoublePrecision;
        debugBrightnessOverride = previousDebugBrightnessOverride;
      }
    }
  });

  testWidgets('conversation task brief capture flow', (tester) async {
    final fixture = await UxValidationFixture.create();
    const size = Size(466, 678);
    final router = await fixture.pump(
      tester,
      '/workspaces/${fixture.workspaceId}/chats/${fixture.chatId}',
      size: size,
      useProductionRouter: true,
      realSessions: true,
      emptyModels: false,
    );
    for (var attempt = 0; attempt < 250; attempt++) {
      if (find.byType(ChatConversationScreen).evaluate().isNotEmpty &&
          find.text('Project research').evaluate().isNotEmpty) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ChatConversationScreen), findsOneWidget);
    expect(find.text('Project research'), findsWidgets);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/workspaces/${fixture.workspaceId}/chats/${fixture.chatId}',
    );
    await fixture.settle(tester);
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('ux-capture')),
      );
      final rendered = await boundary.toImage();
      final pixels = await rendered.toByteData();
      rendered.dispose();
      expect(pixels, isNotNull);
      final data = pixels ?? (throw StateError('Missing rendered pixels'));
      final colors = <int>{};
      for (var offset = 0; offset < data.lengthInBytes; offset += 4) {
        final _ = colors.add(data.getUint32(offset));
        if (colors.length > 2) break;
      }
      expect(
        colors.length,
        greaterThan(2),
        reason: 'The production route must paint real content before capture.',
      );
    });
    final button = find.byKey(const ValueKey('conversation-task-brief-button'));
    const baseline = bool.fromEnvironment('TASK_BRIEF_CAPTURE_BASELINE');
    if (!baseline) expect(button, findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureUxWidget(
      tester,
      'conversation-task-brief-controls',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'en',
      size: size,
      scale: 1,
      dark: false,
    );
    if (baseline) {
      await fixture.close(tester);

      return;
    }
    await tester.tap(button);
    await fixture.settle(tester);
    final editor = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    const brief =
        'Objective: Plan the weekend trip.\n'
        'Constraints: Stay within the budget.\n'
        'Open tasks: Confirm the train times.';
    await tester.enterText(editor, brief);
    await fixture.settle(tester);
    expect(tester.takeException(), isNull);
    await captureUxWidget(
      tester,
      'conversation-task-brief-editor',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'en',
      size: size,
      scale: 1,
      dark: false,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await fixture.settle(tester);
    final saved = await fixture.database
        .customSelect(
          'SELECT task_brief FROM conversations WHERE id = ?',
          variables: [Variable<String>(fixture.chatId)],
        )
        .getSingle();
    expect(saved.read<String>('task_brief'), brief);
    expect(tester.takeException(), isNull);
    await captureUxWidget(
      tester,
      'conversation-task-brief-saved',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'en',
      size: size,
      scale: 1,
      dark: false,
    );
    await fixture.close(tester);
  });

  testWidgets('workspace erasure confirmation disclosure', (tester) async {
    const size = Size(960, 1400);
    final fixture = await UxValidationFixture.create(
      localWorkspaceId: UxValidationFixture.erasureLocalWorkspaceId,
    );
    final router = await fixture.pump(
      tester,
      WorkspaceManagementRoute(
        workspaceId: fixture.workspaceId,
        view: 'connect',
      ).location,
      size: size,
      accounts: [UxValidationFixture.erasureAccount],
      cloudWorkspaceState: UxValidationFixture.erasureConfirmationState,
    );

    await fixture.settle(tester);
    expect(find.text('Manage Workspaces'), findsOneWidget);
    expect(find.text('Shared research space'), findsOneWidget);
    await tester.ensureVisible(find.text('Erase workspace data'));
    await tester.tap(find.text('Erase workspace data'));
    await fixture.settle(tester);
    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    expect(find.text('Manage Workspaces'), findsOneWidget);
    expect(find.text('Shared research space'), findsOneWidget);
    await captureUxWidget(
      tester,
      'workspace-erasure-confirmation-disclosure',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'en',
      size: size,
      scale: 1,
      dark: false,
    );
    await fixture.close(tester);
  });

  testWidgets('cloud workspace populated membership capture', (tester) async {
    const size = Size(466, 678);
    final fixture = await UxValidationFixture.create();
    final scenario = _scenario('CloudWorkspaceDetailRoute', fixture);
    final router = await fixture.pump(
      tester,
      scenario.location,
      size: size,
      accounts: _accounts,
      overrides: _overrides(fixture, 'CloudWorkspaceDetailRoute'),
    );
    await fixture.settle(tester);
    expect(find.text('Shared research'), findsOneWidget);
    expect(find.text('Account: reviewer@example.test'), findsOneWidget);
    expect(find.text('Owner: owner@example.test'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Connection to this app')).dy,
      lessThan(tester.getTopLeft(find.text('Not connected to this app')).dy),
    );
    final list = find.ancestor(
      of: find.text('Members'),
      matching: find.byType(ListView),
    );
    await tester.drag(list.first, const Offset(0, -480));
    await fixture.settle(tester);
    expect(find.text('Pending invitations'), findsOneWidget);
    final invitation = find.ancestor(
      of: find.text('invited@example.test'),
      matching: find.byType(AuraTile),
    );
    expect(
      find.descendant(of: invitation, matching: find.text('Member')),
      findsOneWidget,
    );
    await captureUxWidget(
      tester,
      'cloud-workspace-populated-membership',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'en',
      size: size,
      scale: 1,
      dark: false,
    );
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('cloud workspace invite dialog capture', (tester) async {
    const size = Size(466, 678);
    final fixture = await UxValidationFixture.create();
    final scenario = _scenario('CloudWorkspaceDetailRoute', fixture);
    final router = await fixture.pump(
      tester,
      scenario.location,
      size: size,
      accounts: _accounts,
      overrides: _overrides(fixture, 'CloudWorkspaceDetailRoute'),
    );
    await fixture.settle(tester);
    await tester.scrollUntilVisible(
      find.text('Invite member'),
      200,
      scrollable: find.descendant(
        of: find.byType(CloudWorkspaceDetailScreen),
        matching: find.byType(Scrollable),
      ),
    );
    await fixture.settle(tester);
    await tester.tap(find.text('Invite member'));
    await fixture.settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await captureUxWidget(
      tester,
      'cloud-workspace-invite-dialog',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'en',
      size: size,
      scale: 1,
      dark: false,
    );
    await fixture.close(tester);
  });

  testWidgets('captures device-local archive before and after', (tester) async {
    const size = Size(960, 1400);
    final fixture = await UxValidationFixture.create();
    final router = await fixture.pump(
      tester,
      ChatsRoute(workspaceId: fixture.workspaceId).location,
      size: size,
    );

    await fixture.settle(tester);
    expect(find.text('Project research'), findsOneWidget);
    await tester.tap(find.byTooltip('More options'));
    await fixture.settle(tester);
    expect(find.text('Archive'), findsOneWidget);
    await captureUxWidget(
      tester,
      'conversation-archive-before',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'en',
      size: size,
      scale: 1,
      dark: false,
      fixture:
          'Persisted local workspace and seeded parent conversation; '
          'conversation options open before device-local archive, '
          'with no remote access',
    );

    await tester.tap(find.text('Archive'));
    await fixture.settle(tester);
    expect(find.text('Project research'), findsNothing);
    final archivedConversationsButton = find.descendant(
      of: find.byType(ChatsListScreen),
      matching: find.byTooltip('Archived conversations'),
    );
    expect(archivedConversationsButton, findsOneWidget);
    await tester.tap(archivedConversationsButton);
    await fixture.settle(tester);
    expect(
      router.routeInformationProvider.value.uri.path,
      ArchivedConversationsRoute(workspaceId: fixture.workspaceId).location,
    );
    final archivedScreen = find.byType(ArchivedConversationsScreen);
    final archivedScreenIncludingOffstage = find.byType(
      ArchivedConversationsScreen,
      skipOffstage: false,
    );
    expect(
      archivedScreenIncludingOffstage,
      findsOneWidget,
      reason:
          'The route URI changed to '
          '${router.routeInformationProvider.value.uri}, '
          'but the archived destination was not mounted. Router configuration: '
          '${router.routerDelegate.currentConfiguration}. Router state: '
          'fullPath=${router.state.fullPath}, '
          'matchedLocation=${router.state.matchedLocation}, '
          'topRoute=${router.state.topRoute?.path}, '
          'error=${router.state.error}',
    );
    expect(
      archivedScreen,
      findsOneWidget,
      reason: 'The archived destination was mounted but is not visible.',
    );
    expect(find.text('Project research'), findsOneWidget);
    // Let the archive confirmation snackbar dismiss so the evidence captures
    // the stable archived list rather than a transient notification.
    await tester.pump(const Duration(seconds: 5));
    await fixture.settle(tester);
    await captureUxWidget(
      tester,
      'conversation-archive-after',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'en',
      size: size,
      scale: 1,
      dark: false,
      fixture:
          'Same persisted local workspace after archiving the conversation; '
          'archived conversation list visible, with no remote access',
    );
    await fixture.close(tester);
  });

  testWidgets('cloud workspace detail supports enlarged Spanish text', (
    tester,
  ) async {
    final fixture = await UxValidationFixture.create();
    final scenario = _scenario('CloudWorkspaceDetailRoute', fixture);
    final _ = await fixture.pump(
      tester,
      scenario.location,
      size: const Size(360, 678),
      locale: 'es',
      scale: 1.4,
      accounts: _accounts,
      overrides: _overrides(fixture, 'CloudWorkspaceDetailRoute'),
    );
    await fixture.settle(tester);
    await tester.scrollUntilVisible(
      find.text('Invitar miembro'),
      200,
      scrollable: find.descendant(
        of: find.byType(CloudWorkspaceDetailScreen),
        matching: find.byType(Scrollable),
      ),
    );
    await fixture.settle(tester);
    await tester.tap(find.text('Invitar miembro'));
    await fixture.settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'actual themed controls contrast targets and keyboard dark=$dark',
      (tester) async {
        final fixture = await UxValidationFixture.create();
        final router = await fixture.pump(
          tester,
          NewChatRoute(workspaceId: fixture.workspaceId).location,
          dark: dark,
        );
        final semantics = tester.ensureSemantics();
        try {
          await tester.pump();
          final button = find.widgetWithText(AuraButton, 'Add provider');
          expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          final rich = tester.widget<RichText>(
            find.descendant(of: button, matching: find.byType(RichText)).first,
          );
          final foreground =
              rich.text.style?.color ??
              (throw StateError('Missing rendered button color'));
          final background = tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: button,
                  matching: find.byType(DecoratedBox),
                ),
              )
              .map((box) => box.decoration)
              .whereType<BoxDecoration>()
              .map((box) => box.color)
              .whereType<Color>()
              .first;
          final ratio = _contrast(foreground, background);
          expect(ratio, greaterThanOrEqualTo(4.5));
          final colors = tester.element(button).auraColors;
          expect(
            _contrast(colors.onBackground, colors.background),
            greaterThanOrEqualTo(4.5),
          );
          final selectedNavigationItem = find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.selected == true,
          );
          expect(selectedNavigationItem, findsOneWidget);
          final selectedSemantics = tester.getSemantics(selectedNavigationItem);
          expect(selectedSemantics.label, 'New Chat');
          expect(
            selectedSemantics.flagsCollection.isSelected,
            ui.Tristate.isTrue,
          );
          final connections = find.bySemanticsLabel('Connections');
          expect(tester.getSize(connections).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(connections).width, greaterThanOrEqualTo(48));
          final focusRing = find.descendant(
            of: connections,
            matching: find.byType(CustomPaint),
          );
          var focused = false;
          for (var i = 0; i < 35 && !focused; i++) {
            final _ = await tester.sendKeyEvent(.tab);
            await tester.pump();
            focused = tester
                .widgetList<CustomPaint>(focusRing)
                .any((paint) => paint.foregroundPainter != null);
          }
          expect(focused, isTrue);
          final _ = await tester.sendKeyEvent(.enter);
          await fixture.settle(tester);
          expect(find.byType(ServiceConnectionsScreen), findsOneWidget);
          expect(
            router.routeInformationProvider.value.uri.path,
            ServiceConnectionsRoute(workspaceId: fixture.workspaceId).location,
          );
          expect(tester.takeException(), isNull);
          const output = String.fromEnvironment('UX_CAPTURE_DIR');
          if (output.isNotEmpty) {
            await tester.runAsync(() async {
              final _ = await Directory(output).create(recursive: true);
              final _ =
                  await File(
                    '$output/accessibility-${dark ? 'dark' : 'light'}.json',
                  ).writeAsString(
                    jsonEncode({
                      'sourceFingerprint': const String.fromEnvironment(
                        'UX_SOURCE_FINGERPRINT',
                      ),
                      'theme': dark ? 'dark' : 'light',
                      'accentHue': 186.0,
                      'fonts': uxCaptureFontMetadata,
                      'fontLimitations':
                          'Family-free Copy code uses test Ahem; '
                          'native control typography is unverified.',
                      'control': 'NewChat Add provider',
                      'foreground': foreground.toARGB32(),
                      'background': background.toARGB32(),
                      'contrastRatio': ratio,
                      'bodyContrastRatio': _contrast(
                        colors.onBackground,
                        colors.background,
                      ),
                      'targets':
                          'Add provider and Connections navigation '
                          'at least 48 x 48 logical pixels',
                      'keyboard':
                          'Tab visible focus and Enter into '
                          'production Connections',
                      'semantics': 'New Chat selected',
                      'limit':
                          'Widget semantics and keyboard only; '
                          'no native screen reader measurement',
                    }),
                  );
            });
          }
          await fixture.close(tester);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
  for (final field in const [
    (
      route: 'AgentDetailRoute',
      launcher: 'agents.edit_prompt',
      title: 'markdown_editor.agent_instructions',
      hint: 'markdown_editor.agent_hint',
      cap: null,
    ),
    (
      route: 'SkillDetailRoute',
      launcher: 'skills_screen.edit_description',
      title: 'markdown_editor.skill_description',
      hint: 'markdown_editor.skill_hint',
      cap: 1024,
    ),
    (
      route: 'SkillDetailRoute',
      launcher: 'skills_screen.edit_content',
      title: 'markdown_editor.skill_instructions',
      hint: 'markdown_editor.skill_hint',
      cap: null,
    ),
    (
      route: 'SkillResourceEditRoute',
      launcher: 'skills_resource.edit_description',
      title: 'markdown_editor.resource_description',
      hint: 'markdown_editor.resource_hint',
      cap: 240,
    ),
    (
      route: 'SkillResourceEditRoute',
      launcher: 'skills_resource.edit_content',
      title: 'markdown_editor.resource_content',
      hint: 'markdown_editor.resource_hint',
      cap: 50000,
    ),
  ]) {
    for (final locale in const ['en', 'es']) {
      testWidgets('actual Markdown ${field.title} $locale boundary', (
        tester,
      ) async {
        final f = await UxValidationFixture.create();
        final scenario = _scenario(field.route, f);
        final router = await f.pump(
          tester,
          scenario.location,
          locale: locale,
          size: const Size(960, 1400),
          scale: locale == 'es' ? 1.4 : 1,
        );
        final context = tester.element(find.byType(scenario.screen));
        final label = field.launcher.tr(context: context);
        await tester.scrollUntilVisible(
          find.text(label),
          350,
          scrollable: find
              .descendant(
                of: find.byType(scenario.screen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(find.text(label));
        final _ = await tester.pumpAndSettle();
        final editor = tester.widget<MarkdownEditorScreen>(
          find.byType(MarkdownEditorScreen),
        );
        expect(editor.maxCharacters, field.cap);
        final editorContext = tester.element(find.byType(MarkdownEditorScreen));
        expect(
          find.text(field.title.tr(context: editorContext)),
          findsOneWidget,
        );
        expect(
          find.text(field.hint.tr(context: editorContext)),
          findsOneWidget,
        );
        await captureUxWidget(
          tester,
          '${field.title}-$locale',
          router.routeInformationProvider.value.uri.toString(),
          locale: locale,
          size: const Size(960, 1400),
          scale: locale == 'es' ? 1.4 : 1,
          dark: false,
        );
        final apply = find.byTooltip(
          'markdown_editor.apply'.tr(context: editorContext),
        );
        if (field.cap case final cap?) {
          await tester.enterText(
            find.byType(EditableText).last,
            'x' * (cap + 1),
          );
          final _ = await tester.pumpAndSettle();
          await tester.tap(apply);
          final _ = await tester.pumpAndSettle();
          expect(find.byType(MarkdownEditorScreen), findsOneWidget);
          final overLimitCount = 'markdown_editor.character_count'.tr(
            context: editorContext,
            namedArgs: {'count': '${cap + 1}', 'limit': '$cap'},
          );
          final limitExceeded = 'markdown_editor.limit_exceeded'.tr(
            context: editorContext,
          );
          expect(find.text('$overLimitCount: $limitExceeded'), findsOneWidget);
        }
        final legal = 'x' * (field.cap ?? 60000);
        await tester.enterText(find.byType(EditableText).last, legal);
        final _ = await tester.pumpAndSettle();
        await tester.tap(apply);
        final _ = await tester.pumpAndSettle();
        expect(find.byType(MarkdownEditorScreen), findsNothing);
        expect(find.byType(scenario.screen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await f.close(tester);
      });
    }
  }
  testWidgets('failed connections return to workspace start', (tester) async {
    final fixture = await UxValidationFixture.create();
    final router = await fixture.pump(
      tester,
      ServiceConnectionsRoute(workspaceId: fixture.workspaceId).location,
      overrides: [
        serviceConnectionsProvider(fixture.workspaceId).overrideWith(
          (_) => Stream.error(StateError('Connections unavailable')),
        ),
      ],
    );
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Return to workspace'));
    await fixture.settle(tester);

    expect(find.byType(NewChatScreen), findsOneWidget);
    expect(find.byType(ServiceConnectionsScreen), findsNothing);
    expect(
      router.routeInformationProvider.value.uri.path,
      NewChatRoute(workspaceId: fixture.workspaceId).location,
    );
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('captures service connections audit task states', (tester) async {
    const size = Size(1280, 800);
    final fixture = await UxValidationFixture.create();
    final router = await fixture.pump(
      tester,
      ServiceConnectionsRoute(
        workspaceId: fixture.workspaceId,
        view: 'services',
      ).location,
      size: size,
      overrides: [
        serviceConnectionsProvider(fixture.workspaceId).overrideWith(
          (_) => Stream.value(
            _serviceConnectionsAuditFixture(fixture.workspaceId),
          ),
        ),
      ],
    );
    expect(find.byType(ServiceConnectionsScreen), findsOneWidget);
    expect(find.text('Notion'), findsOneWidget);
    expect(find.text('Linear'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureUxWidget(
      tester,
      'service-connections-services-entry',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'en',
      size: size,
      scale: 1,
      dark: false,
    );

    final searchField = find.descendant(
      of: find.byKey(const ValueKey('service_connections_search')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(searchField, 'no matching service');
    await fixture.settle(tester);
    expect(
      find.text('No connections match your search or filters.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await captureUxWidget(
      tester,
      'service-connections-search-empty',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'en',
      size: size,
      scale: 1,
      dark: false,
    );
    await fixture.close(tester);
  });

  testWidgets('captures service connection network recovery copy', (
    tester,
  ) async {
    const size = Size(1280, 800);
    final fixture = await UxValidationFixture.create();
    final testUsecase = _AuditTestMcpConnectionUsecase();
    when(() => testUsecase('notion-server')).thenAnswer((_) async {
      return (
        status: McpConnectionTestStatus.network,
        testedAt: DateTime.utc(2026, 10, 29, 12),
        transport: const McpTransportTypeStreamableHttp(),
        toolCount: 0,
        durationMilliseconds: 5,
        errorDetails: 'Connection timed out',
      );
    });
    final router = await fixture.pump(
      tester,
      ServiceConnectionsRoute(
        workspaceId: fixture.workspaceId,
        view: 'services',
      ).location,
      size: size,
      overrides: [
        serviceConnectionsProvider(fixture.workspaceId).overrideWith(
          (_) => Stream.value(
            _serviceConnectionsAuditFixture(fixture.workspaceId),
          ),
        ),
        testMcpConnectionUsecaseProvider(fixture.workspaceId)
            .overrideWith((_) async => testUsecase),
      ],
    );
    await tester.tap(
      find.byKey(const ValueKey('service_connection_test_notion')),
    );
    await fixture.settle(tester);
    expect(find.textContaining('Tested '), findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureUxWidget(
      tester,
      'service-connections-network-error',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'en',
      size: size,
      scale: 1,
      dark: false,
    );
    await fixture.close(tester);
  });

  testWidgets('compact conversation header keeps its title readable', (
    tester,
  ) async {
    final fixture = await UxValidationFixture.create();
    final _ = await fixture.pump(
      tester,
      '/workspaces/${fixture.workspaceId}/chats/${fixture.chatId}',
      size: const Size(466, 678),
    );

    final title = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(AuraAppBar),
        matching: find.text('Project research'),
      ),
    );
    expect(title.didExceedMaxLines, isFalse);
    expect(_conversationOptions(), findsOneWidget);
    await fixture.close(tester);
  });

  for (final action in const [
    'Conversation branches',
    'View',
    'Model usage',
    'Saved messages',
  ]) {
    testWidgets('compact conversation menu opens $action', (tester) async {
      final fixture = await UxValidationFixture.create();
      final router = await fixture.pump(
        tester,
        '/workspaces/${fixture.workspaceId}/chats/${fixture.chatId}',
        size: const Size(360, 678),
      );
      await tester.tap(_conversationOptions());
      await tester.pump();
      for (final label in const [
        'Conversation branches',
        'View',
        'Model usage',
        'Saved messages',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      if (action == 'Conversation branches') {
        await captureUxWidget(
          tester,
          'ConversationRoute-compact-menu',
          router.routeInformationProvider.value.uri.toString(),
          locale: 'en',
          size: const Size(360, 678),
          scale: 1,
          dark: false,
        );
      }
      await tester.tap(find.text(action));
      await fixture.settle(tester);

      switch (action) {
        case 'Conversation branches':
          expect(
            find.byKey(const ValueKey('conversation-current-branch')),
            findsOneWidget,
          );
        case 'View':
          expect(find.byType(AlertDialog), findsOneWidget);
        case 'Model usage':
          expect(find.byType(ModelUsageDetailsSheet), findsOneWidget);
        case 'Saved messages':
          expect(find.byType(MessageBookmarksScreen), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
    });
  }

  testWidgets('compact conversation menu supports larger Spanish text', (
    tester,
  ) async {
    final fixture = await UxValidationFixture.create();
    final _ = await fixture.pump(
      tester,
      '/workspaces/${fixture.workspaceId}/chats/${fixture.chatId}',
      size: const Size(360, 800),
      locale: 'es',
      scale: 1.5,
    );
    final optionsLabel =
        'M${String.fromCharCode(0xe1)}s opciones: Project research';
    final branchesLabel = 'Ramas de la conversaci${String.fromCharCode(0xf3)}n';
    await tester.tap(_conversationOptions(optionsLabel));
    await tester.pump();
    expect(find.text(branchesLabel), findsOneWidget);
    expect(find.text('Uso del modelo'), findsOneWidget);
    expect(find.text('Mensajes guardados'), findsOneWidget);
    expect(await tester.sendKeyEvent(.escape), isTrue);
    await tester.pump();
    expect(find.text(branchesLabel), findsNothing);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });

  testWidgets('delegated conversation notice stays inside the content edge', (
    tester,
  ) async {
    final fixture = await UxValidationFixture.create();
    final _ = await fixture.pump(
      tester,
      '/workspaces/${fixture.workspaceId}/chats/${fixture.chatId}'
      '/sub-agents/${fixture.childId}',
      size: const Size(360, 678),
    );
    final notice = find.text(
      'This delegated conversation is read-only. '
      'Continue the task in the parent chat.',
    );
    expect(tester.getTopLeft(notice).dx, greaterThanOrEqualTo(16));
    expect(tester.getBottomRight(notice).dx, lessThanOrEqualTo(344));
    await fixture.close(tester);
  });

  for (final route in const ['new', 'existing']) {
    testWidgets('compact $route chat keeps network disclosure in the header', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final fixture = await UxValidationFixture.create();
        final location = route == 'new'
            ? '/workspaces/${fixture.workspaceId}/chat/new'
            : '/workspaces/${fixture.workspaceId}/chats/${fixture.chatId}';
        final router = await fixture.pump(
          tester,
          location,
          size: const Size(320, 800),
        );

        await captureUxWidget(
          tester,
          '$route-chat-compact-disclosure',
          router.routeInformationProvider.value.uri.toString(),
          locale: 'en',
          size: const Size(320, 800),
          scale: 1,
          dark: false,
        );
        final disclosure = find.byKey(
          const ValueKey('local_workspace_network_disclosure'),
        );
        final agent = find.bySemanticsIdentifier('chat_agent_selector');
        expect(disclosure, findsOneWidget);
        expect(agent, findsOneWidget);
        expect(
          tester.getCenter(disclosure).dy,
          closeTo(tester.getCenter(agent).dy, 1),
        );
        await tester.tap(disclosure);
        final _ = await tester.pumpAndSettle();
        expect(
          find.text('Local storage does not mean offline.'),
          findsOneWidget,
        );
        await fixture.close(tester);
      } finally {
        semantics.dispose();
      }
    });
  }
  testWidgets(
    'production direct route ConversationRoute queued prompts reorder',
    (tester) async {
      final fixture = await UxValidationFixture.create();
      const size = Size(466, 678);
      final location = ConversationRoute(
        workspaceId: fixture.workspaceId,
        chatId: fixture.chatId,
      ).location;
      final router = await fixture.pump(
        tester,
        location,
        size: size,
        overrides: [
          conversationSendQueueProvider.overrideWith(
            () => _CaptureQueuedDrafts(fixture.chatId),
          ),
        ],
      );

      expect(find.byType(ChatConversationScreen), findsOneWidget);
      expect(find.text('Outline the plan'), findsOneWidget);
      expect(find.text('Draft the summary'), findsOneWidget);
      expect(find.text('Review the result'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final route = router.routeInformationProvider.value.uri.toString();
      const firstId = 'capture-0';
      final firstActions = find.byKey(
        const ValueKey('queued-prompt-$firstId-actions'),
      );
      const expectReorder = bool.fromEnvironment(
        'UX_EXPECT_REORDER',
        defaultValue: true,
      );
      expect(firstActions, expectReorder ? findsOneWidget : findsNothing);
      expect(
        tester.getTopLeft(find.text('Outline the plan')).dy,
        lessThan(tester.getTopLeft(find.text('Draft the summary')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Draft the summary')).dy,
        lessThan(tester.getTopLeft(find.text('Review the result')).dy),
      );
      await captureUxWidget(
        tester,
        'queued-prompts-before',
        route,
        locale: 'en',
        size: size,
        scale: 1,
        dark: false,
      );
      if (expectReorder) {
        final _ = await tester.tap(firstActions);
        final _ = await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('queued-prompt-$firstId-move-down')),
        );
        await fixture.settle(tester);
        expect(
          tester.getTopLeft(find.text('Draft the summary')).dy,
          lessThan(tester.getTopLeft(find.text('Outline the plan')).dy),
        );
        expect(
          tester.getTopLeft(find.text('Outline the plan')).dy,
          lessThan(tester.getTopLeft(find.text('Review the result')).dy),
        );
        await captureUxWidget(
          tester,
          'queued-prompts-after',
          route,
          locale: 'en',
          size: size,
          scale: 1,
          dark: false,
        );
      }

      await fixture.close(tester);
    },
  );

  for (final viewport in const [
    (name: 'duo_closed', size: Size(466, 678)),
    (name: 'duo_open_content', size: Size(671, 669)),
    (name: 'duo_open', size: Size(951, 669)),
    (name: 'desktop', size: Size(1280, 1200)),
  ]) {
    for (final name in _routeNames) {
      for (final dark in [false, true]) {
        final testName =
            'production direct route $name ${viewport.name} '
            '${dark ? 'dark' : 'light'}';
        testWidgets(testName, (tester) async {
          addTearDown(() {
            tester.view.resetPadding();
            tester.view.resetViewPadding();
          });
          expect(tester.view.padding.left, 0);
          expect(tester.view.padding.right, 0);
          expect(tester.view.viewPadding.left, 0);
          expect(tester.view.viewPadding.right, 0);
          final fixture = await UxValidationFixture.create(
            empty: name == 'IntroRoute',
          );
          if (name == 'CloudTools') {
            expect(
              await fixture.database.workspaceDao.patchWorkspace(
                fixture.workspaceId,
                const .new(
                  type: .new(.remote),
                  url: .new('https://fixture.example'),
                  cloudAccountId: .new('fixture-account'),
                  cloudWorkspaceId: .new('7'),
                ),
              ),
              isTrue,
            );
          }
          final scenario = _scenario(name, fixture);
          final router = await fixture.pump(
            tester,
            scenario.location,
            size: viewport.size,
            accounts: switch (name) {
              'CloudWorkspaceDetailRoute' || 'CloudTools' => _accounts,
              'MixedAccounts' => _mixedAccounts,
              _ => const [],
            },
            sessionOverride: name == 'CloudTools'
                ? WorkspaceSession(
                    CloudWorkspaceRef(
                      localWorkspaceId: fixture.workspaceId,
                      serverUrl: 'https://fixture.example',
                      accountId: 'fixture-account',
                      cloudWorkspaceId: 7,
                    ),
                  )
                : null,
            dark: dark,
            sessionFailure: name == 'FailedWorkspace'
                ? const WorkspaceRouteFailure(invalidMirror: false)
                : null,
            overrides: _overrides(fixture, name),
          );
          expect(find.byType(scenario.screen), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (name == 'CloudTools') {
            if (viewport.name != 'duo_open') {
              expect(find.text('Design studio / Cloud'), findsOneWidget);
            }
            expect(find.textContaining('Tap the + button'), findsNothing);
            expect(find.byIcon(Icons.add), findsNothing);
            expect(
              find.textContaining(
                'Built-in tools can only be added in local workspaces.',
              ),
              findsOneWidget,
            );
            expect(
              find.textContaining('connect a service to add its tools.'),
              findsOneWidget,
            );
          }
          if (name == 'LocalEmptyTools') {
            expect(find.textContaining('Tap the + button'), findsOneWidget);
            expect(find.byIcon(Icons.add), findsOneWidget);
          }
          if (name == 'AgentsRoute' || name == 'DarkAgents') {
            final measurement = _disabledBadgeMeasurement(tester);
            expect(
              measurement['ratio'],
              greaterThanOrEqualTo(4.5),
              reason: jsonEncode(measurement),
            );
          }
          if (name == 'BuiltInSkillDetail') {
            await tester.scrollUntilVisible(
              find.text('reader_url_and_document_modes'),
              350,
              scrollable: find
                  .descendant(
                    of: find.byType(scenario.screen),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            final slug = tester.renderObject<RenderParagraph>(
              find.text('reader_url_and_document_modes'),
            );
            final family = slug.text.style?.fontFamily;
            expect(family, isNotNull);
            expect(
              uxCaptureFontMetadata.map((font) => font['family']),
              contains(family),
              reason:
                  'Actual resource identifier font must be loaded for capture',
            );
          }
          if (name == 'BuiltInResource') {
            expect(find.text('Save resource'), findsNothing);
            expect(find.text('Copy code'), findsNWidgets(2));
          }
          if (scenario.selection != null) {
            expect(
              tester
                  .widget<AppWithResponsiveDrawer>(
                    find.byType(AppWithResponsiveDrawer),
                  )
                  .selectedIndex,
              scenario.selection,
            );
          }
          expect(
            router.routeInformationProvider.value.uri.path,
            Uri.parse(scenario.expected ?? scenario.location).path,
          );
          expect(
            find.byType(AppScreen),
            findsWidgets,
            reason: '$name route must apply the app side safe area',
          );
          if (viewport.name != 'desktop') {
            final expectedFixture = viewport.name == 'duo_closed' && !dark
                ? switch (name) {
                    'IntroRoute' =>
                      'Empty in-memory database; no workspace or account',
                    'MixedAccounts' =>
                      'Two origins with stored accounts; controlled expired '
                          'and unknown health',
                    'CloudWorkspaceDetailRoute' =>
                      'Controlled cloud workspace admin detail with '
                          'authoritative capability values; no remote mutation',
                    _ => null,
                  }
                : null;
            final testOutput =
                expectedFixture != null &&
                    const String.fromEnvironment('UX_CAPTURE_DIR').isEmpty
                ? Directory.systemTemp.createTempSync('ux-capture-')
                : null;
            if (testOutput != null) {
              addTearDown(() => testOutput.deleteSync(recursive: true));
            }
            File? sidecar;
            await captureUxWidget(
              tester,
              '$name-${viewport.name}-${dark ? 'dark' : 'light'}',
              router.routeInformationProvider.value.uri.toString(),
              locale: 'en',
              size: viewport.size,
              scale: 1,
              dark: dark,
              controlMeasurements: name == 'AgentsRoute' || name == 'DarkAgents'
                  ? _disabledBadgeMeasurement(tester)
                  : null,
              fixture: expectedFixture,
              outputDirectory: testOutput?.path,
              onSidecar: (file) {
                sidecar = file;
              },
            );
            if (expectedFixture != null) {
              final capturedSidecar = sidecar;
              if (capturedSidecar == null) {
                fail('Capture did not produce a JSON sidecar');
              }
              final metadata = jsonDecode(
                capturedSidecar.readAsStringSync(),
              ) as Map<String, Object?>;
              expect(metadata['fixture'], expectedFixture);
            }
          }
          for (final side in const [
            (name: 'left', padding: FakeViewPadding(left: 40)),
            (name: 'right', padding: FakeViewPadding(right: 40)),
          ]) {
            tester.view
              ..padding = side.padding
              ..viewPadding = side.padding;
            await tester.pump();
            expect(
              tester.takeException(),
              isNull,
              reason: '$name ${viewport.name} ${side.name} safe-area layout',
            );
            _expectTextInsideSideSafeArea(
              tester,
              viewport.size,
              side.padding,
              '$name ${viewport.name} ${side.name}',
            );
          }
          await fixture.close(tester);
        });
      }
    }
  }
  for (final viewport in const [
    (name: 'duo_closed', size: Size(466, 678), keyboardInset: 250.0),
    (name: 'duo_open', size: Size(951, 669), keyboardInset: 433.0),
  ]) {
    testWidgets('new chat composer stays above keyboard ${viewport.name}', (
      tester,
    ) async {
      final fixture = await UxValidationFixture.create();
      final _ = await fixture.pump(
        tester,
        NewChatRoute(workspaceId: fixture.workspaceId).location,
        size: viewport.size,
      );
      tester.view.viewInsets = .new(bottom: viewport.keyboardInset);
      addTearDown(tester.view.resetViewInsets);
      expect(await tester.pumpAndSettle(), greaterThan(0));

      final composer = tester.getRect(find.byType(ChatInputWidget));
      expect(composer.top, greaterThanOrEqualTo(0));
      expect(
        composer.bottom,
        lessThanOrEqualTo(viewport.size.height - viewport.keyboardInset),
      );
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
    });
  }
  for (final viewport in const [
    (name: 'duo_closed', size: Size(466, 678), keyboardInset: 250.0),
    (name: 'duo_open', size: Size(951, 669), keyboardInset: 433.0),
  ]) {
    for (final name in const [
      'CloudAccountLoginRoute',
      'ServiceConnectionCreateRoute',
      'SkillResourceCreateRoute',
    ]) {
      testWidgets('$name form scrolls above keyboard ${viewport.name}', (
        tester,
      ) async {
        final fixture = await UxValidationFixture.create();
        final scenario = _scenario(name, fixture);
        final _ = await fixture.pump(
          tester,
          scenario.location,
          size: viewport.size,
          overrides: _overrides(fixture, name),
        );
        tester.view.viewInsets = .new(bottom: viewport.keyboardInset);
        addTearDown(tester.view.resetViewInsets);
        await fixture.settle(tester);

        final field = find
            .descendant(
              of: find.byType(scenario.screen),
              matching: find.byType(EditableText),
            )
            .last;
        await tester.ensureVisible(field);
        await fixture.settle(tester);

        final fieldBounds = tester.getRect(field);
        expect(
          fieldBounds.bottom,
          lessThanOrEqualTo(viewport.size.height - viewport.keyboardInset),
        );
        expect(tester.takeException(), isNull);
        await fixture.close(tester);
      });
    }
  }
  for (final name in const [
    'NewChatRoute',
    'SkillsRoute',
    'ToolsRoute',
    'ServiceConnectionsRoute',
    'WorkspaceSettingsRoute',
    'CloudAccountLoginRoute',
  ]) {
    for (final variant in const [
      (width: 899.0, locale: 'en', scale: 1.0, dark: false),
      (width: 900.0, locale: 'en', scale: 1.0, dark: false),
      (width: 360.0, locale: 'es', scale: 1.4, dark: false),
      (width: 1280.0, locale: 'es', scale: 1.4, dark: true),
    ]) {
      if (name == 'ToolsRoute' && variant.width != 360) continue;
      testWidgets(
        'reflow $name ${variant.width} ${variant.locale} ${variant.scale}',
        (tester) async {
          final fixture = await UxValidationFixture.create();
          if (name == 'CloudTools') {
            expect(
              await fixture.database.workspaceDao.patchWorkspace(
                fixture.workspaceId,
                const .new(
                  type: .new(.remote),
                  url: .new('https://fixture.example'),
                  cloudAccountId: .new('fixture-account'),
                  cloudWorkspaceId: .new('7'),
                ),
              ),
              isTrue,
            );
          }
          final scenario = _scenario(name, fixture);
          final router = await fixture.pump(
            tester,
            scenario.location,
            size: .new(variant.width, 1200),
            locale: variant.locale,
            scale: variant.scale,
            dark: variant.dark,
          );
          expect(find.byType(scenario.screen), findsOneWidget);
          expect(tester.takeException(), isNull);
          final context = tester.element(find.byType(scenario.screen));
          expect(
            ResponsiveSlidingDrawerProvider.of(context).isDesktop,
            variant.width >= 900,
          );
          expect(MediaQuery.disableAnimationsOf(context), isTrue);
          if ((name == 'SkillsRoute' || name == 'ToolsRoute') &&
              variant.width == 360) {
            if (name == 'SkillsRoute') {
              await tester.tap(
                find.byKey(const ValueKey('app_filter_sheet')).first,
              );
              final _ = await tester.pumpAndSettle();
            }
            final sort = tester.getRect(
              find.byKey(
                ValueKey(name == 'SkillsRoute' ? 'skills-sort' : 'tools-sort'),
              ),
            );
            expect(
              sort.height,
              lessThanOrEqualTo(120),
              reason: 'Sort label and value must remain readable: $sort',
            );
            expect(sort.width, greaterThanOrEqualTo(200));
            if (name == 'SkillsRoute') {
              await tester.tapAt(const Offset(10, 10));
              final _ = await tester.pumpAndSettle();
            }
          }
          await captureUxWidget(
            tester,
            '$name-${variant.width}-${variant.locale}-${variant.scale}',
            router.routeInformationProvider.value.uri.toString(),
            locale: variant.locale,
            size: .new(variant.width, 1200),
            scale: variant.scale,
            dark: variant.dark,
            fixture: name,
          );
          await fixture.close(tester);
        },
      );
    }
  }
}

Finder _conversationOptions([
  String label = 'More options: Project research',
]) => find.descendant(
  of: find.byType(AuraAppBar),
  matching: find.byTooltip(label),
);

typedef _RouteScenario = ({
  String location,
  Type screen,
  int? selection,
  String? expected,
});

_RouteScenario _scenario(String name, UxValidationFixture f) {
  final w = f.workspaceId;
  final base = '/workspaces/$w';

  return switch (name) {
    'CloudWorkspaceDetailRoute' => (
      location:
          '$base/manage-workspaces/cloud/fixture-account/7?server-url=https%3A%2F%2Ffixture.example',
      screen: CloudWorkspaceDetailScreen,
      selection: -1,
      expected: null,
    ),
    'ServiceConnectionEditRoute' => (
      location: '$base/service-connections/fixture-service',
      screen: ServiceConnectionEditScreen,
      selection: 2,
      expected: null,
    ),
    'BuiltInSkillDetail' => (
      location: '$base/skills/jina',
      screen: SkillDetailScreen,
      selection: 1,
      expected: null,
    ),
    'BuiltInResource' => (
      location: '$base/skills/jina/resources/reader_url_and_document_modes',
      screen: SkillResourceEditScreen,
      selection: 1,
      expected: null,
    ),
    'MixedConnections' => (
      location: '$base/service-connections',
      screen: ServiceConnectionsScreen,
      selection: 2,
      expected: null,
    ),
    'MixedAccounts' => (
      location: '$base/cloud-accounts',
      screen: CloudAccountsScreen,
      selection: 4,
      expected: null,
    ),
    'CloudTools' || 'LocalEmptyTools' => (
      location: '$base/tools',
      screen: ToolsScreen,
      selection: 2,
      expected: null,
    ),
    'FailedWorkspace' => (
      location: '$base/chat/new',
      screen: RouteRecoveryView,
      selection: null,
      expected: null,
    ),
    'IntroRoute' => (
      location: '/intro',
      screen: IntroScreen,
      selection: null,
      expected: null,
    ),
    'WorkspaceRoute' => (
      location: base,
      screen: NewChatScreen,
      selection: 0,
      expected: '$base/chat/new',
    ),
    'NewChatRoute' => (
      location: '$base/chat/new',
      screen: NewChatScreen,
      selection: 0,
      expected: null,
    ),
    'ChatsRoute' => (
      location: '$base/chats',
      screen: ChatsListScreen,
      selection: -1,
      expected: null,
    ),
    'ConversationRoute' => (
      location: '$base/chats/${f.chatId}',
      screen: ChatConversationScreen,
      selection: -1,
      expected: null,
    ),
    'SubAgentConversationRoute' => (
      location: '$base/chats/${f.chatId}/sub-agents/${f.childId}',
      screen: ChatConversationScreen,
      selection: -1,
      expected: null,
    ),
    'SettingsRoute' => (
      location: '$base/settings',
      screen: SettingsScreen,
      selection: 3,
      expected: null,
    ),
    'WorkspaceSettingsRoute' => (
      location: '$base/workspace-settings',
      screen: WorkspaceSettingsScreen,
      selection: -1,
      expected: null,
    ),
    'WorkspaceSetupPreflightRoute' => (
      location: '$base/setup-preflight',
      screen: WorkspaceSetupPreflightScreen,
      selection: -1,
      expected: null,
    ),
    'WorkspaceManagementRoute' => (
      location: '$base/manage-workspaces',
      screen: WorkspaceManagementScreen,
      selection: -1,
      expected: null,
    ),
    'WorkspaceCreateRoute' => (
      location: '$base/manage-workspaces/create',
      screen: CreateWorkspaceScreen,
      selection: -1,
      expected: null,
    ),
    'CloudAccountsRoute' => (
      location: '$base/cloud-accounts',
      screen: CloudAccountsScreen,
      selection: 4,
      expected: null,
    ),
    'CloudAccountAddRoute' => (
      location: '$base/cloud-accounts/add',
      screen: CloudAccountAddScreen,
      selection: 4,
      expected: null,
    ),
    'CloudAccountLoginRoute' => (
      location: '$base/cloud-accounts/login',
      screen: CloudAccountLoginScreen,
      selection: 4,
      expected: null,
    ),
    'CloudAccountRegisterRoute' => (
      location: '$base/cloud-accounts/register',
      screen: CloudAccountRegisterScreen,
      selection: 4,
      expected: null,
    ),
    'CloudAccountForgotPasswordRoute' => (
      location: '$base/cloud-accounts/forgot-password',
      screen: CloudAccountForgotPasswordScreen,
      selection: 4,
      expected: null,
    ),
    'ModelsRoute' => (
      location: '$base/models',
      screen: ServiceConnectionsScreen,
      selection: 2,
      expected: '$base/service-connections',
    ),
    'ServiceConnectionsRoute' => (
      location: '$base/service-connections',
      screen: ServiceConnectionsScreen,
      selection: 2,
      expected: null,
    ),
    'ServiceConnectionCreateRoute' => (
      location: '$base/service-connections/new?type=connector&connectorId=jina',
      screen: ServiceConnectionCreateScreen,
      selection: 2,
      expected: null,
    ),
    'ToolsRoute' => (
      location: '$base/tools',
      screen: ToolsScreen,
      selection: 2,
      expected: null,
    ),
    'AgentsRoute' || 'DarkAgents' => (
      location: '$base/agents',
      screen: AgentsScreen,
      selection: 1,
      expected: null,
    ),
    'AgentCreateRoute' => (
      location: '$base/agents/new',
      screen: AgentDetailScreen,
      selection: 1,
      expected: null,
    ),
    'AgentDetailRoute' => (
      location: '$base/agents/${f.agentId}',
      screen: AgentDetailScreen,
      selection: 1,
      expected: null,
    ),
    'SkillsRoute' => (
      location: '$base/skills',
      screen: SkillsScreen,
      selection: 1,
      expected: null,
    ),
    'SkillCreateRoute' => (
      location: '$base/skills/new',
      screen: SkillDetailScreen,
      selection: 1,
      expected: null,
    ),
    'SkillDetailRoute' => (
      location: '$base/skills/${f.skillId}',
      screen: SkillDetailScreen,
      selection: 1,
      expected: null,
    ),
    'SkillResourceCreateRoute' => (
      location: '$base/skills/${f.skillId}/resources/new',
      screen: SkillResourceEditScreen,
      selection: 1,
      expected: null,
    ),
    'SkillResourceEditRoute' => (
      location: '$base/skills/${f.skillId}/resources/${f.resourceId}',
      screen: SkillResourceEditScreen,
      selection: 1,
      expected: null,
    ),
    _ => throw ArgumentError(name),
  };
}

const _routeNames = [
  'MixedConnections',
  'MixedAccounts',
  'CloudTools',
  'LocalEmptyTools',
  'DarkAgents',
  'FailedWorkspace',
  'BuiltInSkillDetail',
  'BuiltInResource',
  'CloudWorkspaceDetailRoute',
  'ServiceConnectionEditRoute',
  'IntroRoute',
  'WorkspaceRoute',
  'NewChatRoute',
  'ChatsRoute',
  'ConversationRoute',
  'SubAgentConversationRoute',
  'SettingsRoute',
  'WorkspaceSettingsRoute',
  'WorkspaceSetupPreflightRoute',
  'WorkspaceManagementRoute',
  'WorkspaceCreateRoute',
  'CloudAccountsRoute',
  'CloudAccountAddRoute',
  'CloudAccountLoginRoute',
  'CloudAccountRegisterRoute',
  'CloudAccountForgotPasswordRoute',
  'ModelsRoute',
  'ServiceConnectionsRoute',
  'ServiceConnectionCreateRoute',
  'ToolsRoute',
  'AgentsRoute',
  'AgentCreateRoute',
  'AgentDetailRoute',
  'SkillsRoute',
  'SkillCreateRoute',
  'SkillDetailRoute',
  'SkillResourceCreateRoute',
  'SkillResourceEditRoute',
];

void _expectTextInsideSideSafeArea(
  WidgetTester tester,
  Size viewport,
  FakeViewPadding padding,
  String route,
) {
  final paragraphs = tester.renderObjectList<RenderParagraph>(
    find.descendant(
      of: find.byType(AuraScreen),
      matching: find.byType(RichText),
    ),
  );
  final viewportBounds = Offset.zero & viewport;
  for (final paragraph in paragraphs) {
    final bounds = MatrixUtils.transformRect(
      paragraph.getTransformTo(null),
      paragraph.paintBounds,
    );
    var visibleBounds = bounds;
    var child = paragraph.parent ?? paragraph;
    for (
      var ancestor = paragraph.parent;
      ancestor != null;
      ancestor = ancestor.parent
    ) {
      final clip = ancestor.describeApproximatePaintClip(child);
      if (clip != null) {
        visibleBounds = visibleBounds.intersect(
          MatrixUtils.transformRect(ancestor.getTransformTo(null), clip),
        );
      }
      child = ancestor;
    }
    if (visibleBounds.isEmpty || !visibleBounds.overlaps(viewportBounds)) {
      continue;
    }
    expect(
      visibleBounds.left,
      greaterThanOrEqualTo(padding.left - 1),
      reason:
          '$route text ${paragraph.text.toPlainText()} enters the '
          'left unsafe area: $visibleBounds',
    );
    expect(
      visibleBounds.right,
      lessThanOrEqualTo(viewport.width - padding.right + 1),
      reason:
          '$route text ${paragraph.text.toPlainText()} enters the '
          'right unsafe area: $visibleBounds',
    );
  }
}

const _accounts = [
  CloudAccountSession(
    serverUrl: 'https://fixture.example',
    userId: 'fixture-account',
    email: 'reviewer@example.test',
  ),
];

List<Object> _overrides(UxValidationFixture fixture, String name) {
  if (name == 'MixedConnections') {
    return [
      serviceConnectionsProvider(fixture.workspaceId).overrideWith(
        (ref) => Stream.value([
          for (final item in const [
            (
              name: 'Research provider',
              kind: ServiceConnectionListItemKind.modelProvider,
              status: ServiceConnectionDisplayStatus.unknown,
            ),
            (
              name: 'Expired reference server',
              kind: ServiceConnectionListItemKind.mcpServer,
              status: ServiceConnectionDisplayStatus.expired,
            ),
            (
              name: 'Research Connector',
              kind: ServiceConnectionListItemKind.connector,
              status: ServiceConnectionDisplayStatus.unknown,
            ),
            (
              name: 'Saved Connector',
              kind: ServiceConnectionListItemKind.connector,
              status: ServiceConnectionDisplayStatus.unknown,
            ),
          ])
            ServiceConnectionListItem(
              id: item.name,
              workspaceId: fixture.workspaceId,
              name: item.name,
              serviceName: 'Research',
              kind: item.kind,
              keySuffix: '1234',
              mcpServerId: null,
              authenticationType: null,
              displayStatus: item.status,
              expiresAt: null,
              lastRefreshedAt: null,
              lastAuthError: null,
              metadataValues: [],
              canRefresh: false,
              canReconnect: false,
            ),
        ]),
      ),
    ];
  }
  if (name == 'MixedAccounts') {
    return [
      cloudAccountHealthProvider.overrideWith(
        (ref, key) async => CloudAccountHealth(
          status: key.accountId == 'expired-account' ? .needsSignIn : .unknown,
        ),
      ),
    ];
  }
  if (name == 'LocalEmptyTools') {
    return [
      workspaceToolsProvider(fixture.workspaceId).overrideWith(_EmptyTools.new),
      groupedToolsProvider(fixture.workspaceId).overrideWith(_EmptyGroups.new),
    ];
  }
  if (name == 'CloudTools') {
    return [
      workspaceAvailabilityProvider(fixture.workspaceId).overrideWith(
        (ref) async => WorkspaceAvailable(
          await ref.watch(
            workspaceSessionForRouteProvider(fixture.workspaceId).future,
          ),
        ),
      ),
      conversationsStreamProvider.overrideWith((ref, args) => Stream.value([])),
      workspaceToolsProvider(fixture.workspaceId).overrideWith(_EmptyTools.new),
      groupedToolsProvider(fixture.workspaceId).overrideWith(_EmptyGroups.new),
    ];
  }
  if (name == 'ServiceConnectionEditRoute') {
    return [
      serviceConnectionOperationsProvider(fixture.workspaceId).overrideWith(
        (ref) async => ServiceConnectionOperations(
          createConnectorConnection: ({
            required workspaceId,
            required connectorId,
            required name,
            required apiKey,
          }) async => throw UnimplementedError(),
          getGenericForEdit: (id) async => id == 'fixture-service'
              ? const GenericServiceConnectionForEdit(
                  id: 'fixture-service',
                  name: 'Saved research Connector',
                  serviceId: 'jina',
                  hasSecret: true,
                  keySuffix: '1234',
                )
              : null,
          updateGeneric: (_, _) async => throw UnimplementedError(),
        ),
      ),
    ];
  }
  if (name != 'CloudWorkspaceDetailRoute') return [];

  return [
    cloudAccountHealthProvider.overrideWith(
      (ref, key) async =>
          CloudAccountHealth(status: .verified, checkedAt: .utc(2026, 9, 30)),
    ),
    cloudWorkspaceDetailProvider.overrideWith(
      (ref, key) async => CloudWorkspaceDetailState(
        detail: .new(
          workspace: .new(
            id: 7,
            name: 'Shared research',
            role: 'admin',
            revision: 1,
            sequence: 0,
            createdAt: .utc(2026),
            updatedAt: .utc(2026),
          ),
          ownerUserId: 'other-owner',
          ownerEmail: 'owner@example.test',
          capabilities: .new(
            canViewMembers: true,
            canInviteMembers: true,
            canInviteAdmins: false,
            canManageMembers: true,
            canManageAdmins: false,
            canRename: false,
            canTransferOwnership: false,
            canLeave: true,
            canDelete: false,
          ),
        ),
        members: [
          CloudWorkspaceMemberSummary(
            userId: 'member-1',
            email: 'member@example.test',
            role: 'member',
            revision: 1,
            createdAt: .utc(2026),
          ),
        ],
        invites: [
          CloudWorkspaceInviteSummary(
            id: 1,
            email: 'invited@example.test',
            role: 'member',
            invitedByUserId: 'fixture-account',
            revision: 1,
            createdAt: .utc(2026),
            expiresAt: .utc(2026, 12),
          ),
        ],
      ),
    ),
  ];
}

const _mixedAccounts = [
  CloudAccountSession(
    serverUrl: 'https://one.example',
    userId: 'expired-account',
    email: 'expired@example.test',
  ),
  CloudAccountSession(
    serverUrl: 'https://two.example',
    userId: 'unknown-account',
    email: 'unavailable@example.test',
  ),
];

class _EmptyTools extends WorkspaceToolsNotifier {
  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async => [];
}

class _EmptyGroups extends GroupedToolsNotifier {
  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async => [];
}

Map<String, Object> _disabledBadgeMeasurement(WidgetTester tester) {
  final text = find.text('Disabled');
  final badge = find.ancestor(of: text, matching: find.byType(AuraBadge));
  final foreground =
      tester.renderObject<RenderParagraph>(text).text.style?.color ??
      (throw StateError('Missing rendered badge foreground'));
  final box = tester.widget<Container>(
    find.descendant(of: badge, matching: find.byType(Container)).first,
  );
  final decoration = box.decoration as BoxDecoration?;
  final background =
      decoration?.color ??
      (throw StateError('Missing rendered badge background'));
  final colors = tester.element(badge).auraColors;
  final composite = Color.alphaBlend(background, colors.background);

  return {
    'foreground': foreground.toARGB32(),
    'background': background.toARGB32(),
    'compositedBackground': composite.toARGB32(),
    'ratio': _contrast(.alphaBlend(foreground, composite), composite),
    'surfaceVariant': colors.surfaceVariant.toARGB32(),
    'onSurfaceVariant': colors.onSurfaceVariant.toARGB32(),
    'foregroundOnSurface': colors.foregroundOnSurface.toARGB32(),
  };
}

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();

  return ((a > b ? a : b) + 0.05) / ((a > b ? b : a) + 0.05);
}

class _CaptureQueuedDrafts(final String conversationId)
    extends ConversationSendQueue {
  @override
  Map<String, List<ConversationQueuedDraft>> build() => {
    conversationId: [
      ConversationQueuedDraft(
        id: 'capture-0',
        draft: const ChatDraft(text: 'Outline the plan'),
      ),
      ConversationQueuedDraft(
        id: 'capture-1',
        draft: const ChatDraft(text: 'Draft the summary'),
      ),
      ConversationQueuedDraft(
        id: 'capture-2',
        draft: const ChatDraft(text: 'Review the result'),
      ),
    ],
  };
}

List<ServiceConnectionListItem> _serviceConnectionsAuditFixture(
  String workspaceId,
) => [
  ServiceConnectionListItem(
    id: 'notion',
    workspaceId: workspaceId,
    name: 'Notion',
    serviceName: 'mcp.notion.test',
    kind: .mcpServer,
    keySuffix: null,
    mcpServerId: 'notion-server',
    authenticationType: 'oauth2',
    displayStatus: .needsReauth,
    expiresAt: null,
    lastRefreshedAt: null,
    lastAuthError: null,
    metadataValues: const [],
    canRefresh: false,
    canReconnect: true,
    transport: const McpTransportTypeStreamableHttp(),
  ),
  ServiceConnectionListItem(
    id: 'linear',
    workspaceId: workspaceId,
    name: 'Linear',
    serviceName: 'mcp.linear.test',
    kind: .mcpServer,
    keySuffix: null,
    mcpServerId: 'linear-server',
    authenticationType: 'oauth2',
    displayStatus: .connected,
    expiresAt: null,
    lastRefreshedAt: null,
    lastAuthError: null,
    metadataValues: const [],
    canRefresh: false,
    canReconnect: false,
    transport: const McpTransportTypeStreamableHttp(),
  ),
  ServiceConnectionListItem(
    id: 'sentry',
    workspaceId: workspaceId,
    name: 'Sentry',
    serviceName: 'mcp.sentry.test',
    kind: .mcpServer,
    keySuffix: null,
    mcpServerId: 'sentry-server',
    authenticationType: 'oauth2',
    displayStatus: .failed,
    expiresAt: null,
    lastRefreshedAt: null,
    lastAuthError: null,
    metadataValues: const [],
    canRefresh: false,
    canReconnect: true,
    transport: const McpTransportTypeStreamableHttp(),
  ),
];

class _AuditTestMcpConnectionUsecase extends Mock
    implements TestMcpConnectionUsecase;
