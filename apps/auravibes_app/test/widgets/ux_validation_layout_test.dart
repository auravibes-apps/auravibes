import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/agents/screens/agent_detail_screen.dart';
import 'package:auravibes_app/features/agents/screens/agents_screen.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/screens/chats_list_screen.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_health.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_add_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_forgot_password_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_login_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_register_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_accounts_screen.dart';
import 'package:auravibes_app/features/cloud_workspaces/models/cloud_workspace_detail_state.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart';
import 'package:auravibes_app/features/intro/screens/intro_screen.dart';
import 'package:auravibes_app/features/markdown/screens/markdown_editor_screen.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_edit_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connections_screen.dart';
import 'package:auravibes_app/features/settings/screens/more_screen.dart';
import 'package:auravibes_app/features/settings/screens/settings_screen.dart';
import 'package:auravibes_app/features/settings/screens/workspace_settings_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_credential_definition_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_credential_definitions_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_resource_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_tool_edit_screen.dart';
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
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_with_responsive_drawer.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_app/widgets/route_recovery_view.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/ux_validation_fixture.dart';

final _captureFontMetadata = <Map<String, String>>[];

void main() {
  tearDownAll(UxValidationFixture.closeDatabase);
  setUpAll(() async {
    for (final font in const {
      'Inter': 'assets/fonts/Inter.ttf',
      'JetBrains Mono':
          'packages/gpt_markdown/lib/fonts/JetBrainsMono-Regular.ttf',
      'packages/gpt_markdown/JetBrainsMono':
          'packages/gpt_markdown/lib/fonts/JetBrainsMono-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await _registerCaptureFont(
        font.key,
        font.value,
        await rootBundle.load(font.value),
      );
    }
    await _registerCaptureFont(
      'Roboto',
      'Flutter SDK artifacts/material_fonts/Roboto-Regular.ttf',
      await _sdkRoboto(),
    );
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
          final chats = find.bySemanticsLabel('Chats');
          expect(chats, findsOneWidget);
          expect(
            tester.getSemantics(chats).flagsCollection.isSelected,
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
                      'fonts': _captureFontMetadata,
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
                      'semantics': 'Chats selected',
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
    (
      route: 'SkillToolEditRoute',
      launcher: 'skills_screen.edit_description',
      title: 'markdown_editor.tool_description',
      hint: 'markdown_editor.tool_hint',
      cap: 1024,
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
        await _capture(
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
          expect(find.text('${cap + 1}/$cap'), findsOneWidget);
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
  for (final name in _routeNames) {
    testWidgets('production direct route $name', (tester) async {
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
        dark: name == 'DarkAgents',
        sessionFailure: name == 'FailedWorkspace'
            ? const WorkspaceRouteFailure(invalidMirror: false)
            : null,
        overrides: _overrides(fixture, name),
      );
      expect(find.byType(scenario.screen), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (name == 'CloudTools') {
        expect(find.text('Design studio / Cloud'), findsOneWidget);
        expect(find.textContaining('Tap the + button'), findsNothing);
        expect(find.byIcon(Icons.add), findsNothing);
        expect(
          find.textContaining(
            'Built-in tools can only be added in local workspaces.',
          ),
          findsNWidgets(2),
        );
        expect(
          find.textContaining('connect a service to add its tools.'),
          findsNWidgets(2),
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
        final slug = tester.renderObject<RenderParagraph>(
          find.text('reader_url_and_document_modes'),
        );
        final family = slug.text.style?.fontFamily;
        expect(family, isNotNull);
        expect(
          _captureFontMetadata.map((font) => font['family']),
          contains(family),
          reason: 'Actual resource identifier font must be loaded for capture',
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
      await _capture(
        tester,
        name,
        router.routeInformationProvider.value.uri.toString(),
        locale: 'en',
        size: const Size(1280, 1200),
        scale: 1,
        dark: name == 'DarkAgents',
        controlMeasurements: name == 'AgentsRoute' || name == 'DarkAgents'
            ? _disabledBadgeMeasurement(tester)
            : null,
      );
      await fixture.close(tester);
    });
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
      (width: 959.0, locale: 'en', scale: 1.0, dark: false),
      (width: 960.0, locale: 'en', scale: 1.0, dark: false),
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
            variant.width >= 960,
          );
          expect(MediaQuery.disableAnimationsOf(context), isTrue);
          if ((name == 'SkillsRoute' || name == 'ToolsRoute') &&
              variant.width == 360) {
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
          }
          await _capture(
            tester,
            '$name-${variant.width}-${variant.locale}-${variant.scale}',
            router.routeInformationProvider.value.uri.toString(),
            locale: variant.locale,
            size: .new(variant.width, 1200),
            scale: variant.scale,
            dark: variant.dark,
          );
          await fixture.close(tester);
        },
      );
    }
  }
}

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
          '$base/more/manage-workspaces/cloud/fixture-account/7?server-url=https%3A%2F%2Ffixture.example',
      screen: CloudWorkspaceDetailScreen,
      selection: -1,
      expected: null,
    ),
    'ServiceConnectionEditRoute' => (
      location: '$base/more/service-connections/fixture-service',
      screen: ServiceConnectionEditScreen,
      selection: 2,
      expected: null,
    ),
    'BuiltInSkillDetail' => (
      location: '$base/more/skills/jina',
      screen: SkillDetailScreen,
      selection: 1,
      expected: null,
    ),
    'BuiltInResource' => (
      location:
          '$base/more/skills/jina/resources/reader_url_and_document_modes',
      screen: SkillResourceEditScreen,
      selection: 1,
      expected: null,
    ),
    'MixedConnections' => (
      location: '$base/more/service-connections',
      screen: ServiceConnectionsScreen,
      selection: 2,
      expected: null,
    ),
    'MixedAccounts' => (
      location: '$base/more/cloud-accounts',
      screen: CloudAccountsScreen,
      selection: 4,
      expected: null,
    ),
    'CloudTools' || 'LocalEmptyTools' => (
      location: '$base/more/tools',
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
      selection: 0,
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
    'MoreRoute' => (
      location: '$base/more',
      screen: MoreScreen,
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
    'WorkspaceManagementRoute' => (
      location: '$base/more/manage-workspaces',
      screen: WorkspaceManagementScreen,
      selection: -1,
      expected: null,
    ),
    'WorkspaceCreateRoute' => (
      location: '$base/more/manage-workspaces/create',
      screen: CreateWorkspaceScreen,
      selection: -1,
      expected: null,
    ),
    'CloudAccountsRoute' => (
      location: '$base/more/cloud-accounts',
      screen: CloudAccountsScreen,
      selection: 4,
      expected: null,
    ),
    'CloudAccountAddRoute' => (
      location: '$base/more/cloud-accounts/add',
      screen: CloudAccountAddScreen,
      selection: 4,
      expected: null,
    ),
    'CloudAccountLoginRoute' => (
      location: '$base/more/cloud-accounts/login',
      screen: CloudAccountLoginScreen,
      selection: 4,
      expected: null,
    ),
    'CloudAccountRegisterRoute' => (
      location: '$base/more/cloud-accounts/register',
      screen: CloudAccountRegisterScreen,
      selection: 4,
      expected: null,
    ),
    'CloudAccountForgotPasswordRoute' => (
      location: '$base/more/cloud-accounts/forgot-password',
      screen: CloudAccountForgotPasswordScreen,
      selection: 4,
      expected: null,
    ),
    'ModelsRoute' => (
      location: '$base/more/models',
      screen: ServiceConnectionsScreen,
      selection: 2,
      expected: '$base/more/service-connections',
    ),
    'ServiceConnectionsRoute' => (
      location: '$base/more/service-connections',
      screen: ServiceConnectionsScreen,
      selection: 2,
      expected: null,
    ),
    'ServiceConnectionCreateRoute' => (
      location:
          '$base/more/service-connections/new?type=skillCredential&credentialDefinitionId=${f.definitionId}',
      screen: ServiceConnectionCreateScreen,
      selection: 2,
      expected: null,
    ),
    'ToolsRoute' => (
      location: '$base/more/tools',
      screen: ToolsScreen,
      selection: 2,
      expected: null,
    ),
    'AgentsRoute' || 'DarkAgents' => (
      location: '$base/more/agents',
      screen: AgentsScreen,
      selection: 1,
      expected: null,
    ),
    'AgentCreateRoute' => (
      location: '$base/more/agents/new',
      screen: AgentDetailScreen,
      selection: 1,
      expected: null,
    ),
    'AgentDetailRoute' => (
      location: '$base/more/agents/${f.agentId}',
      screen: AgentDetailScreen,
      selection: 1,
      expected: null,
    ),
    'SkillsRoute' => (
      location: '$base/more/skills',
      screen: SkillsScreen,
      selection: 1,
      expected: null,
    ),
    'SkillCreateRoute' => (
      location: '$base/more/skills/new',
      screen: SkillDetailScreen,
      selection: 1,
      expected: null,
    ),
    'SkillDetailRoute' => (
      location: '$base/more/skills/${f.skillId}',
      screen: SkillDetailScreen,
      selection: 1,
      expected: null,
    ),
    'SkillResourceCreateRoute' => (
      location: '$base/more/skills/${f.skillId}/resources/new',
      screen: SkillResourceEditScreen,
      selection: 1,
      expected: null,
    ),
    'SkillResourceEditRoute' => (
      location: '$base/more/skills/${f.skillId}/resources/${f.resourceId}',
      screen: SkillResourceEditScreen,
      selection: 1,
      expected: null,
    ),
    'SkillToolCreateRoute' => (
      location: '$base/more/skills/${f.skillId}/tools/new',
      screen: SkillToolEditScreen,
      selection: 1,
      expected: null,
    ),
    'SkillToolEditRoute' => (
      location: '$base/more/skills/${f.skillId}/tools/${f.toolId}',
      screen: SkillToolEditScreen,
      selection: 1,
      expected: null,
    ),
    'SkillCredentialDefinitionsRoute' => (
      location: '$base/more/skill-credential-definitions',
      screen: SkillCredentialDefinitionsScreen,
      selection: 2,
      expected: null,
    ),
    'SkillCredentialDefinitionCreateRoute' => (
      location: '$base/more/skill-credential-definitions/new',
      screen: SkillCredentialDefinitionEditScreen,
      selection: 2,
      expected: null,
    ),
    'SkillCredentialDefinitionEditRoute' => (
      location: '$base/more/skill-credential-definitions/${f.definitionId}',
      screen: SkillCredentialDefinitionEditScreen,
      selection: 2,
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
  'MoreRoute',
  'SettingsRoute',
  'WorkspaceSettingsRoute',
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
  'SkillToolCreateRoute',
  'SkillToolEditRoute',
  'SkillCredentialDefinitionsRoute',
  'SkillCredentialDefinitionCreateRoute',
  'SkillCredentialDefinitionEditRoute',
];

Future<void> _registerCaptureFont(
  String family,
  String source,
  ByteData data,
) async {
  await (FontLoader(family)..addFont(.value(data))).load();
  _captureFontMetadata.add({
    'family': family,
    'source': source,
    'sha256': sha256
        .convert(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        )
        .toString(),
  });
}

Future<ByteData> _sdkRoboto() async {
  for (
    var directory = File(Platform.resolvedExecutable).parent;
    directory.path != directory.parent.path;
    directory = directory.parent
  ) {
    final font = File('${directory.path}/material_fonts/Roboto-Regular.ttf');
    if (font.existsSync()) {
      return (await font.readAsBytes()).buffer.asByteData();
    }
  }

  throw StateError('Flutter SDK Roboto font is unavailable for capture');
}

Future<void> _capture(
  WidgetTester tester,
  String name,
  String route, {
  required String locale,
  required Size size,
  required double scale,
  required bool dark,
  Map<String, Object>? controlMeasurements,
}) async {
  const output = String.fromEnvironment('UX_CAPTURE_DIR');
  if (output.isEmpty) return;
  const fingerprint = String.fromEnvironment('UX_SOURCE_FINGERPRINT');
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('ux-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final directory = Directory(output);
    final _ = await directory.create(recursive: true);
    final artifact = '${(++_captureNumber).toString().padLeft(3, '0')}-$name';
    final _ = await File('$output/$artifact.png').writeAsBytes(
      (bytes ?? (throw StateError('PNG encoding failed'))).buffer.asUint8List(),
    );
    final _ = await File('$output/$artifact.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'name': name,
        'controlMeasurements': ?controlMeasurements,
        'route': route,
        'fixture': _fixtureDescription(name),
        'sourceFingerprint': fingerprint,
        'renderer': 'Flutter widget-test Skia, Linux',
        'viewport': [size.width, size.height],
        'locale': locale,
        'textScale': scale,
        'theme': dark ? 'dark' : 'light',
        'accentHue': 186.0,
        'flavor': 'prod view under controlled widget fixture',
        'disableAnimations': true,
        'fonts': _captureFontMetadata,
        'fontLimitations':
            'Family-free Copy code uses test Ahem; '
            'native control typography is unverified.',
      }),
    );
  });
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
              name: 'Research credential',
              kind: ServiceConnectionListItemKind.skillCredential,
              status: ServiceConnectionDisplayStatus.unknown,
            ),
            (
              name: 'Saved service',
              kind: ServiceConnectionListItemKind.skillCredential,
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
              credentialDefinitionId: null,
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
          createAppSkillCredential: ({
            required workspaceId,
            required appSkillServiceId,
            required name,
            required apiKey,
          }) async => throw UnimplementedError(),
          getGenericForEdit: (id) async => id == 'fixture-service'
              ? const GenericServiceConnectionForEdit(
                  id: 'fixture-service',
                  name: 'Saved research service',
                  serviceId: 'app-skill',
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
          capabilities: .new(
            canViewMembers: true,
            canInviteMembers: true,
            canInviteAdmins: false,
            canManageMembers: true,
            canManageAdmins: false,
            canRename: true,
            canTransferOwnership: false,
            canLeave: true,
            canDelete: false,
          ),
        ),
        members: [],
        invites: [],
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

String _fixtureDescription(String name) => switch (name) {
  'IntroRoute' => 'Empty in-memory database; no workspace or account',
  'MixedConnections' =>
    'Four controlled connection rows: model provider, '
        'expired MCP, two saved credentials; no remote access '
        'claim',
  'MixedAccounts' =>
    'Two origins with stored accounts; controlled expired and unknown health',
  'CloudTools' =>
    'Matching cloud mirror and session; controlled available gate '
        'and empty tools; actual capability restriction',
  'LocalEmptyTools' =>
    'Persisted local workspace with controlled empty tool providers; '
        'actual local capability, add control and empty hint',
  'FailedWorkspace' =>
    'Controlled missing local workspace failure and actual '
        'route recovery screen',
  'CloudWorkspaceDetailRoute' =>
    'Controlled cloud workspace admin detail with '
        'authoritative capability values; no remote mutation',
  'ServiceConnectionEditRoute' =>
    'Controlled saved generic service editor state',
  _ =>
    'Persisted local in-memory workspace, two agents '
        'sharing a custom skill, disabled agent/skill, schema '
        'without credential, template resource/tool, parent and '
        'child chats; no models or cloud accounts',
};

int _captureNumber = 0;
