// Required: Tests repeat finders and fixture lookups for clarity.
import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_drop/flutter_file_drop.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/riverpod.dart';

import '../../../helpers/test_provider_scope.dart';

void main() {
  test('AttachmentDisplayNames.unique keeps first label unchanged', () {
    expect(
      AttachmentDisplayNames.unique('Voice Record', const []),
      'Voice Record',
    );
  });

  test('AttachmentDisplayNames.unique numbers repeated labels', () {
    expect(
      AttachmentDisplayNames.unique('Voice Record', const ['Voice Record']),
      'Voice Record (1)',
    );
    expect(
      AttachmentDisplayNames.unique('Image', const ['Image', 'Image (1)']),
      'Image (2)',
    );
  });

  test('AttachmentDisplayNames.unique preserves file extensions', () {
    expect(
      AttachmentDisplayNames.unique('blueprint.pdf', const ['blueprint.pdf']),
      'blueprint (1).pdf',
    );
  });

  Widget buildSubject({
    required FutureOr<void> Function(ChatDraft) onSendMessage,
    VoidCallback onToolsPress = _noop,
    ConversationToolAccessMode toolAccessMode =
        ConversationToolAccessMode.defaultMode,
    ValueChanged<ConversationToolAccessMode>? onToolAccessModeChanged,
    Locale locale = const Locale('en'),
    bool disabled = false,
    bool acceptDroppedFilesWhenDisabled = false,
    bool isBusy = false,
    bool? showStopButton,
    VoidCallback? onStop,
    VoidCallback? onContinueAgent,
    List<String> modalitiesInput = const [],
    LocalChatAttachmentService? attachmentService,
    Widget modelSheetControl = const SizedBox.shrink(),
    Widget agentSheetControl = const SizedBox.shrink(),
    Widget modelCompactControl = const SizedBox.shrink(),
    Widget agentCompactControl = const SizedBox.shrink(),
    Widget? reasoningSettingsControl,
    VoidCallback? onCompact,
    bool canCompact = true,
    String? compactDisabledHint,
    String? continueDisabledHint,
    Widget? disabledHint,
    bool isCompacting = false,
    ValueChanged<bool>? onDraftStatusChanged,
    ChatDraft? draftToLoad,
    ValueListenable<String?>? activeConversation,
    VoidCallback? onSkillsPress,
    ConversationSkillSelectorState? skillSelectorState,
    WorkspaceFile? sharedFile,
    WorkspaceAssetRepository? sharedAssets,
    WorkspaceSession workspaceSession = const WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: 'ws-1'),
    ),
  }) {
    return EasyLocalization(
      child: TestProviderScope(
        overrides: [
          if (sharedFile != null) ...[
            workspaceFilesProvider(
              'ws-1',
              null,
            ).overrideWith((_) async => [sharedFile]),
            workspaceFoldersProvider(
              'ws-1',
              null,
            ).overrideWith((_) async => []),
          ],
          if (sharedAssets != null)
            workspaceAssetRepositoryProvider('ws-1')
                .overrideWith((_) async => sharedAssets),
          workspaceSessionForRouteProvider('ws-1')
              .overrideWithValue(AsyncData(workspaceSession)),
          if (attachmentService case final service?)
            localChatAttachmentServiceProvider.overrideWithValue(service),
          if (skillSelectorState case final state?)
            conversationSkillSelectorProvider(
              'ws-1',
              'conversation-1',
            ).overrideWith((_) async => state),
        ],
        child: Builder(
          builder: (context) {
            Widget chatInput(String? conversationId) => ChatInputWidget(
              workspaceId: 'ws-1',
              onSendMessage: onSendMessage,
              onToolsPress: onToolsPress,
              modelSheetControl: modelSheetControl,
              agentSheetControl: agentSheetControl,
              modelCompactControl: (onPressed) => AuraTile(
                child: modelCompactControl,
                onTap: onPressed,
                variant: .outlined,
                size: .small,
                leading: const AuraIcon(Icons.memory_outlined, size: .small),
              ),
              agentCompactControl: (onPressed) => AuraTile(
                child: agentCompactControl,
                onTap: onPressed,
                variant: .selected,
                size: .small,
                leading: const AuraIcon(Icons.smart_toy_outlined),
              ),
              onDraftStatusChanged: onDraftStatusChanged,
              conversationId: conversationId,
              toolAccessMode: toolAccessMode,
              onToolAccessModeChanged: onToolAccessModeChanged,
              reasoningSettingsControl: reasoningSettingsControl,
              draftToLoad: draftToLoad,
              modalitiesInput: modalitiesInput,
              onSkillsPress: onSkillsPress,
              onContinueAgent: onContinueAgent,
              continueDisabledHint: continueDisabledHint,
              disabledHint: disabledHint,
              compactDisabledHint: compactDisabledHint,
              disabled: disabled,
              acceptDroppedFilesWhenDisabled: acceptDroppedFilesWhenDisabled,
              isBusy: isBusy,
              showStopButton: showStopButton,
              onStop: onStop,
              onCompact: onCompact,
              canCompact: canCompact,
              isCompacting: isCompacting,
              key: conversationId == null ? null : ValueKey(conversationId),
            );

            return MaterialApp(
              home: AuraThemeScope(
                theme: .light,
                child: Theme(
                  data: .new(),
                  child: AuraLegacyMaterialBridge(
                    child: AuraSnackBarHost(
                      child: Material(
                        child: Portal(
                          child: activeConversation == null
                              ? chatInput(null)
                              : ValueListenableBuilder<String?>(
                                  valueListenable: activeConversation,
                                  builder: (context, conversationId, child) {
                                    if (conversationId == null) {
                                      return const SizedBox.shrink();
                                    }

                                    return chatInput(conversationId);
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              locale: context.locale,
              localizationsDelegates: [
                ...GlobalMaterialLocalizations.delegates,
                sdk_localizations.GlobalMaterialLocalizations.delegate,
                ...context.localizationDelegates,
              ],
              supportedLocales: context.supportedLocales,
            );
          },
        ),
      ),
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: locale,
      useOnlyLangCode: true,
      useFallbackTranslations: true,
      saveLocale: false,
    );
  }

  Future<_TestFlutterFileDropChannel> pumpAndInit(
    WidgetTester tester,
    Widget widget,
  ) async {
    final dropChannel = _TestFlutterFileDropChannel();
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
    });
    await tester.pump();
    await tester.pump();
    await tester.pump();

    return dropChannel;
  }

  void overridePlatform(TargetPlatform platform) {
    debugDefaultTargetPlatformOverride = platform;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  testWidgets('tool access control requires callback', (tester) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(onSendMessage: (_) => _noop()),
    );
    expect(
      find.byKey(const ValueKey<String>('chat_tool_access_mode')),
      findsNothing,
    );
  });

  testWidgets(
    'tool access supports keyboard focus, open, selection and escape',
    (tester) async {
      ConversationToolAccessMode? changed;
      final _ = await pumpAndInit(
        tester,
        buildSubject(
          onSendMessage: (_) => _noop(),
          onToolAccessModeChanged: (mode) => changed = mode,
        ),
      );
      final control = find.byKey(
        const ValueKey<String>('chat_tool_access_mode'),
      );
      final popup = find.ancestor(
        of: control,
        matching: find.byType(AuraPopupMenu),
      );
      final focus =
          (tester
                    .widgetList<Focus>(
                      find.descendant(of: popup, matching: find.byType(Focus)),
                    )
                    .firstWhere((widget) => widget.focusNode != null)
                    .focusNode ??
                (throw StateError('Missing dropdown focus')))
            ..requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      final _ = await tester.sendKeyEvent(.enter);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Allow all'), findsOneWidget);
      final _ = await tester.sendKeyEvent(.tab);
      final _ = await tester.sendKeyEvent(.tab);
      final _ = await tester.sendKeyEvent(.enter);
      final _ = await tester.pumpAndSettle();
      expect(changed, ConversationToolAccessMode.allowAll);
      expect(focus.hasFocus, isTrue);
      expect(focus.descendants.any((node) => node.hasPrimaryFocus), isTrue);
      final _ = await tester.sendKeyEvent(.space);
      final _ = await tester.pumpAndSettle();
      final _ = await tester.sendKeyEvent(.escape);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Default'), findsOneWidget);
      expect(focus.hasFocus, isTrue);
      final _ = await tester.sendKeyEvent(.enter);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Allow all'), findsOneWidget);
    },
  );

  for (final mode in ConversationToolAccessMode.values) {
    testWidgets('tool access exposes $mode and selects both options', (
      tester,
    ) async {
      ConversationToolAccessMode? changed;
      final semantics = tester.ensureSemantics();
      try {
        final _ = await pumpAndInit(
          tester,
          buildSubject(
            onSendMessage: (_) => _noop(),
            toolAccessMode: mode,
            onToolAccessModeChanged: (value) => changed = value,
          ),
        );
        final control = find.byKey(
          const ValueKey<String>('chat_tool_access_mode'),
        );
        expect(
          find.descendant(of: find.byType(AuraInput), matching: control),
          findsOneWidget,
        );
        expect(find.text('Tool access'), findsNothing);
        expect(
          find.text(
            mode == ConversationToolAccessMode.defaultMode
                ? 'Default'
                : 'Allow all',
          ),
          findsOneWidget,
        );
        expect(find.text('Follows normal tool approval rules.'), findsNothing);
        expect(
          find.text('Skips prompts for otherwise permitted tools.'),
          findsNothing,
        );
        expect(find.bySemanticsLabel(RegExp('Tool access')), findsWidgets);
        for (final option in ConversationToolAccessMode.values) {
          await tester.tap(control);
          final _ = await tester.pumpAndSettle();
          expect(
            find.text('Follows normal tool approval rules.'),
            findsOneWidget,
          );
          expect(
            find.text('Skips prompts for otherwise permitted tools.'),
            findsOneWidget,
          );
          await tester.tap(
            find
                .text(
                  option == ConversationToolAccessMode.defaultMode
                      ? 'Default'
                      : 'Allow all',
                )
                .last,
          );
          final _ = await tester.pumpAndSettle();
          expect(changed, option);
        }
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final mode in ConversationToolAccessMode.values) {
    testWidgets('Spanish tool access $mode fits narrow composer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        final _ = await pumpAndInit(
          tester,
          buildSubject(
            onSendMessage: (_) => _noop(),
            toolAccessMode: mode,
            onToolAccessModeChanged: (_) => _noop(),
            locale: const Locale('es'),
          ),
        );
        expect(find.text('Acceso a herramientas'), findsNothing);
        expect(find.text('Normal'), findsNothing);
        expect(find.text('Todas'), findsNothing);
        expect(
          find.bySemanticsLabel(
            mode == ConversationToolAccessMode.defaultMode
                ? 'Acceso a herramientas: Predeterminado'
                : 'Acceso a herramientas: Permitir todas',
          ),
          findsWidgets,
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('chat_tool_access_mode')),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.text('Predeterminado'), findsWidgets);
        expect(find.text('Permitir todas'), findsWidgets);
        expect(
          find.text(
            'Sigue las reglas normales de '
            'aprobaci${String.fromCharCode(0xf3)}n de herramientas.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Omite las confirmaciones de herramientas permitidas.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('reports text draft changes', (tester) async {
    final draftStatuses = <bool>[];

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) => Future<void>.value(),
        onDraftStatusChanged: draftStatuses.add,
      ),
    );

    await tester.enterText(find.byType(EditableText), 'unsent draft');
    await tester.pump();
    expect(draftStatuses.last, isTrue);

    await tester.enterText(find.byType(EditableText), '');
    await tester.pump();
    expect(draftStatuses.last, isFalse);
  });

  testWidgets('skills control shows selected count and opens picker', (
    tester,
  ) async {
    final conversation = ValueNotifier<String?>('conversation-1');
    addTearDown(conversation.dispose);
    var opened = false;
    final semantics = tester.ensureSemantics();
    try {
      final _ = await pumpAndInit(
        tester,
        buildSubject(
          onSendMessage: (_) => Future<void>.value(),
          activeConversation: conversation,
          onSkillsPress: () => opened = true,
          skillSelectorState: _skillSelectorState(1),
        ),
      );

      final button = find.byKey(const ValueKey<String>('chat_skills_button'));
      expect(find.byIcon(Icons.psychology_alt_outlined), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(tester.getSemantics(button).label, 'Skills, 1 added');

      await tester.tap(button);
      expect(opened, isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('skills count stays visible at zero and narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final conversation = ValueNotifier<String?>('conversation-1');
    addTearDown(conversation.dispose);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) => Future<void>.value(),
        activeConversation: conversation,
        onSkillsPress: _noop,
        skillSelectorState: _skillSelectorState(0),
      ),
    );
    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports loaded attachment as a draft', (tester) async {
    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/report.pdf',
      fileName: 'report.pdf',
      displayName: 'report.pdf',
      mimeType: 'application/pdf',
      modality: .file,
      sizeBytes: 2048,
    );
    final draftStatuses = <bool>[];

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) => Future<void>.value(),
        attachmentService: _FakeLocalChatAttachmentService(attachment),
        draftToLoad: const ChatDraft(text: '', attachments: [attachment]),
        onDraftStatusChanged: draftStatuses.add,
      ),
    );

    expect(draftStatuses.last, isTrue);
  });

  testWidgets('reports active recording as a draft', (tester) async {
    if (kIsWeb) return;
    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/recording.m4a',
      fileName: 'recording.m4a',
      displayName: 'recording.m4a',
      mimeType: 'audio/m4a',
      modality: .audio,
      sizeBytes: 2048,
    );
    final draftStatuses = <bool>[];

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) => Future<void>.value(),
        modalitiesInput: const ['audio'],
        attachmentService: _FakeLocalChatAttachmentService(attachment),
        onDraftStatusChanged: draftStatuses.add,
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat_voice_button')));
    await tester.pump();
    expect(draftStatuses.last, isTrue);
    final recordingText = tester.widget<Text>(find.textContaining('00:00'));
    expect(
      recordingText.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('keeps conversation text and attachment across navigation', (
    tester,
  ) async {
    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/report.pdf',
      fileName: 'report.pdf',
      displayName: 'report.pdf',
      mimeType: 'application/pdf',
      modality: .file,
      sizeBytes: 2048,
    );
    final activeConversation = ValueNotifier<String?>('chat-1');
    addTearDown(activeConversation.dispose);
    final attachmentService = _FakeLocalChatAttachmentService(attachment);
    final previousPicker = fp.FilePickerPlatform.instance;
    addTearDown(() => fp.FilePickerPlatform.instance = previousPicker);
    fp.FilePickerPlatform.instance = _FakeFilePickerPlatform([
      _FakePlatformFile(
        name: attachment.fileName,
        size: attachment.sizeBytes,
        path: attachment.localPath,
      ),
    ]);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        activeConversation: activeConversation,
        modalitiesInput: const ['text', 'file'],
        attachmentService: attachmentService,
        onSendMessage: (_) => Future<void>.value(),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'first draft');
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.attach_file));
    final _ = await tester.pumpAndSettle();
    expect(find.text('report.pdf'), findsOneWidget);

    activeConversation.value = 'chat-2';
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    expect(find.text('report.pdf'), findsNothing);
    expect(attachmentService.deletedPaths, isEmpty);
    await tester.enterText(find.byType(EditableText), 'second draft');

    activeConversation.value = null;
    await tester.pump();
    activeConversation.value = 'chat-1';
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'first draft',
    );
    expect(find.text('report.pdf'), findsOneWidget);
    expect(attachmentService.deletedPaths, isEmpty);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();
    await tester.tap(find.text('Discard draft'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    expect(find.text('report.pdf'), findsNothing);
    expect(attachmentService.deletedPaths, [attachment.localPath]);

    activeConversation.value = 'chat-2';
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'second draft',
    );
    activeConversation.value = 'chat-1';
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
  });

  testWidgets('keeps failed send draft and clears successful send draft', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final activeConversation = ValueNotifier<String?>('chat-1');
    addTearDown(activeConversation.dispose);
    var attempts = 0;

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        activeConversation: activeConversation,
        workspaceSession: const WorkspaceSession(
          LocalWorkspaceRef(localWorkspaceId: 'ws-1'),
        ),
        onSendMessage: (_) async {
          attempts++;
          if (attempts == 1) throw StateError('send failed');
        },
      ),
    );
    expect(
      find.byKey(const ValueKey<String>('local_workspace_network_disclosure')),
      findsOneWidget,
    );
    expect(find.text('Local storage does not mean offline.'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'unsent message');
    await tester.pump();
    await tester.tap(
      find.bySemanticsIdentifier('chat_send_button').hitTestable(),
    );
    await tester.pump();
    expect(attempts, 1);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'unsent message',
    );

    activeConversation.value = null;
    await tester.pump();
    activeConversation.value = 'chat-1';
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'unsent message',
    );
    final sendButton = find.bySemanticsIdentifier('chat_send_button');
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton.hitTestable());
    final _ = await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    activeConversation.value = null;
    await tester.pump();
    activeConversation.value = 'chat-1';
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    expect(attempts, 2);
    semantics.dispose();
  });

  testWidgets('cloud workspace does not show the local network disclosure', (
    tester,
  ) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) => Future<void>.value(),
        workspaceSession: const WorkspaceSession(
          CloudWorkspaceRef(
            localWorkspaceId: 'ws-1',
            serverUrl: 'https://server.example',
            accountId: 'account-1',
            cloudWorkspaceId: 1,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('local_workspace_network_disclosure')),
      findsNothing,
    );
  });

  testWidgets('renders without error', (tester) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    expect(find.byType(ChatInputWidget), findsOneWidget);
    expect(find.byType(DropTarget), findsOneWidget);
    expect(find.byType(AuraInput), findsOneWidget);
  });

  testWidgets('shows and clears the drop overlay for file previews', (
    tester,
  ) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        disabled: true,
        acceptDroppedFilesWhenDisabled: true,
        onSendMessage: (_) => _noop(),
      ),
    );

    final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));
    dropTarget.onEnter?.call(
      .new(
        globalPosition: .zero,
        localPosition: .zero,
        items: const [.new(kind: .string)],
      ),
    );
    await tester.pump();

    expect(find.text('Drop files to attach'), findsNothing);

    dropTarget.onMove?.call(
      .new(
        globalPosition: .zero,
        localPosition: .zero,
        items: const [.new(kind: .file)],
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.file_upload_outlined), findsOneWidget);
    expect(find.text('Drop files to attach'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chat_input_drop_highlight')),
      findsOneWidget,
    );

    dropTarget.onLeave?.call();
    await tester.pump();

    expect(find.byIcon(Icons.file_upload_outlined), findsNothing);
    expect(find.text('Drop files to attach'), findsNothing);
  });

  testWidgets('adds dropped files to disabled new-chat draft', (tester) async {
    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/report.pdf',
      fileName: 'report.pdf',
      displayName: 'report.pdf',
      mimeType: 'application/pdf',
      modality: .file,
      sizeBytes: 8,
    );
    final attachmentService = _FakeLocalChatAttachmentService(attachment);
    final bytes = Uint8List.fromList('report!!'.codeUnits);

    final dropChannel = await pumpAndInit(
      tester,
      buildSubject(
        disabled: true,
        acceptDroppedFilesWhenDisabled: true,
        attachmentService: attachmentService,
        onSendMessage: (_) => _noop(),
      ),
    );

    dropChannel.dropFile(
      position: tester.getCenter(find.byType(AuraInput)),
      fileName: 'report.pdf',
      mimeType: 'application/pdf',
      bytes: bytes,
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('report.pdf'), findsOneWidget);
    expect(attachmentService.copiedBytes, bytes);
    expect(attachmentService.copiedFileName, 'report.pdf');
  });

  testWidgets('rejects a dropped file after the streamed byte limit', (
    tester,
  ) async {
    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/report.pdf',
      fileName: 'report.pdf',
      displayName: 'report.pdf',
      mimeType: 'application/pdf',
      modality: .file,
      sizeBytes: 8,
    );
    final attachmentService = _FakeLocalChatAttachmentService(attachment);
    final dropChannel = await pumpAndInit(
      tester,
      buildSubject(
        disabled: true,
        acceptDroppedFilesWhenDisabled: true,
        attachmentService: attachmentService,
        onSendMessage: (_) => _noop(),
      ),
    );

    dropChannel.dropFile(
      position: tester.getCenter(find.byType(AuraInput)),
      fileName: 'report.pdf',
      mimeType: 'application/pdf',
      bytes: .new(0),
      fileSize: ChatAttachmentModality.maxChatAttachmentBytes + 1,
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Attachment must be 25 MB or smaller.'), findsOneWidget);
    expect(attachmentService.copiedBytes, isNull);
  });

  testWidgets('blocks send when draft attachment is unsupported', (
    tester,
  ) async {
    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/report.pdf',
      fileName: 'report.pdf',
      displayName: 'report.pdf',
      mimeType: 'application/pdf',
      modality: .file,
      sizeBytes: 2048,
    );
    final sentDrafts = <ChatDraft>[];

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['text'],
        attachmentService: _FakeLocalChatAttachmentService(attachment),
        draftToLoad: const ChatDraft(
          text: 'Question',
          attachments: [attachment],
        ),
        onSendMessage: sentDrafts.add,
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_upward).hitTestable());
    final _ = await tester.pumpAndSettle();

    expect(sentDrafts, isEmpty);
    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.textContaining('support file input'), findsOneWidget);
  });

  testWidgets('loads a queued draft with its attachments', (tester) async {
    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/report.pdf',
      fileName: 'report.pdf',
      displayName: 'report.pdf',
      mimeType: 'application/pdf',
      modality: .file,
      sizeBytes: 2048,
    );
    ChatDraft? sentDraft;

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['text', 'file'],
        draftToLoad: const ChatDraft(
          text: 'Edited message',
          attachments: [attachment],
        ),
        onSendMessage: (draft) => sentDraft = draft,
      ),
    );

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Edited message',
    );
    await tester.pump();
    final sendButton = find.ancestor(
      of: find.byKey(const ValueKey<String>('chat_send_button')),
      matching: find.byType(AuraButton),
    );
    expect(tester.widget<AuraButton>(sendButton).disabled, isFalse);

    await tester.tap(find.byIcon(Icons.arrow_upward).hitTestable());
    await tester.pump();

    expect(sentDraft?.text, 'Edited message');
    expect(sentDraft?.attachments, [attachment]);
  });

  testWidgets('exposes stable selectors for composer controls', (tester) async {
    final semantics = tester.ensureSemantics();
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['text', 'audio'],
        modelCompactControl: const Text('compact model'),
        modelSheetControl: const Text('sheet model'),
        agentCompactControl: const Text('compact agent'),
        agentSheetControl: const Text('sheet agent'),
        reasoningSettingsControl: const Text('reasoning settings'),
        showStopButton: true,
        onStop: _noop,
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    for (final selector in [
      'chat_composer',
      'chat_agent_selector',
      'chat_model_selector',
      'chat_attachment_options_button',
      'chat_stop_generation',
    ]) {
      expect(find.byKey(ValueKey<String>(selector)), findsOneWidget);
    }
    for (final selector in [
      'chat_attachment_options_button',
      'chat_stop_generation',
    ]) {
      expect(find.bySemanticsIdentifier(selector), findsOneWidget);
      expect(
        find.byKey(ValueKey<String>(selector)).evaluate().single,
        find.bySemanticsIdentifier(selector).evaluate().single,
      );
    }
    expect(
      find.byKey(const ValueKey<String>('chat_send_button')),
      findsNothing,
    );
    expect(find.text('reasoning settings'), findsNothing);
    final composerRadii = tester
        .widgetList<AuraCornerRadiusScope>(
          find.ancestor(
            of: find.byKey(
              const ValueKey<String>('chat_attachment_options_button'),
            ),
            matching: find.byType(AuraCornerRadiusScope),
          ),
        )
        .map((scope) => scope.radius)
        .toList();
    expect(composerRadii, contains(16));
    expect(composerRadii, contains(12));
    expect(
      find.byKey(const ValueKey<String>('chat_voice_button')),
      kIsWeb ? findsNothing : findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('clears text as soon as send is accepted', (tester) async {
    final sendCompleter = Completer<void>();
    ChatDraft? sentDraft;

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (draft) {
          sentDraft = draft;

          return sendCompleter.future;
        },
      ),
    );

    await tester.enterText(find.byType(EditableText), 'Hello agent');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward).hitTestable());
    await tester.pump();

    expect(sentDraft?.text, 'Hello agent');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );

    sendCompleter.complete();
  });

  testWidgets('sends attachment-only drafts once', (tester) async {
    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/report.pdf',
      fileName: 'report.pdf',
      displayName: 'report.pdf',
      mimeType: 'application/pdf',
      modality: .file,
      sizeBytes: 2048,
    );
    final sendCompleter = Completer<void>();
    final sentDrafts = <ChatDraft>[];
    final previousPicker = fp.FilePickerPlatform.instance;
    addTearDown(() => fp.FilePickerPlatform.instance = previousPicker);
    fp.FilePickerPlatform.instance = _FakeFilePickerPlatform([
      _FakePlatformFile(
        name: attachment.fileName,
        size: attachment.sizeBytes,
        path: attachment.localPath,
      ),
    ]);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['text', 'file'],
        attachmentService: _FakeLocalChatAttachmentService(attachment),
        isBusy: true,
        onStop: _noop,
        onSendMessage: (draft) {
          sentDrafts.add(draft);

          return sendCompleter.future;
        },
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('chat_stop_generation')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat_send_button')),
      findsNothing,
    );
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.attach_file));
    final _ = await tester.pumpAndSettle();
    expect(find.text('report.pdf'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat_send_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat_stop_generation')),
      findsNothing,
    );

    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();

    expect(sentDrafts, hasLength(1));
    expect(sentDrafts.single.text, isEmpty);
    expect(sentDrafts.single.attachments, [attachment]);

    sendCompleter.complete();
    await tester.pump();
  });

  testWidgets('shows an error when a selected file exceeds 25 MiB', (
    tester,
  ) async {
    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/large.pdf',
      fileName: 'large.pdf',
      displayName: 'large.pdf',
      mimeType: 'application/pdf',
      modality: .file,
      sizeBytes: 25 * 1024 * 1024 + 1,
    );

    final previousPicker = fp.FilePickerPlatform.instance;
    addTearDown(() => fp.FilePickerPlatform.instance = previousPicker);
    fp.FilePickerPlatform.instance = _FakeFilePickerPlatform([
      _FakePlatformFile(
        name: attachment.fileName,
        size: attachment.sizeBytes,
        path: attachment.localPath,
      ),
    ]);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['text', 'file'],
        attachmentService: _FakeLocalChatAttachmentService(
          attachment,
          copyError: const ChatAttachmentTooLargeException(),
        ),
        onSendMessage: (_) => Future.value(),
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.attach_file));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Attachment must be 25 MB or smaller.'), findsOneWidget);
  });

  testWidgets('warns and cleans up unsupported selected attachments', (
    tester,
  ) async {
    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/image.png',
      fileName: 'image.png',
      displayName: 'image.png',
      mimeType: 'image/png',
      modality: .image,
      sizeBytes: 2048,
    );
    final attachmentService = _FakeLocalChatAttachmentService(attachment);
    final previousPicker = fp.FilePickerPlatform.instance;
    addTearDown(() => fp.FilePickerPlatform.instance = previousPicker);
    fp.FilePickerPlatform.instance = _FakeFilePickerPlatform([
      _FakePlatformFile(
        name: attachment.fileName,
        size: attachment.sizeBytes,
        path: attachment.localPath,
      ),
    ]);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['text', 'file'],
        attachmentService: attachmentService,
        onSendMessage: (_) => Future.value(),
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.attach_file));
    final _ = await tester.pumpAndSettle();

    expect(
      find.text(
        '''The selected model doesn't support image input. '''
        'Switch to a model that accepts images.',
      ),
      findsOneWidget,
    );
    expect(find.text(attachment.fileName), findsNothing);
    expect(attachmentService.deletedPaths, [attachment.localPath]);
  });

  testWidgets('clears all draft attachments and deletes their files', (
    tester,
  ) async {
    const first = MessageAttachmentToCreate(
      localPath: '/tmp/first.pdf',
      fileName: 'first.pdf',
      displayName: 'First',
      mimeType: 'application/pdf',
      modality: .file,
      sizeBytes: 1024,
    );
    const second = MessageAttachmentToCreate(
      localPath: '/tmp/second.pdf',
      fileName: 'second.pdf',
      displayName: 'Second',
      mimeType: 'application/pdf',
      modality: .file,
      sizeBytes: 2048,
    );
    final attachmentService = _FakeLocalChatAttachmentService(first);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['file'],
        attachmentService: attachmentService,
        draftToLoad: const ChatDraft(
          text: 'Keep this text',
          attachments: [first, second],
        ),
        onSendMessage: (_) => Future.value(),
      ),
    );

    expect(find.text('first.pdf'), findsOneWidget);
    expect(find.text('second.pdf'), findsOneWidget);
    final clearAllButton = find.byWidgetPredicate(
      (widget) =>
          widget is AuraIconButton &&
          widget.identifier == 'chat_clear_all_attachments',
    );
    tester.widget<AuraIconButton>(clearAllButton).onPressed?.call();
    await tester.pump();

    expect(find.text('first.pdf'), findsNothing);
    expect(find.text('second.pdf'), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Keep this text',
    );
    expect(attachmentService.deletedPaths, [first.localPath, second.localPath]);
  });

  testWidgets('does not update sending state after unmount', (tester) async {
    final sendCompleter = Completer<void>();

    final _ = await pumpAndInit(
      tester,
      buildSubject(onSendMessage: (_) => sendCompleter.future),
    );

    await tester.enterText(find.byType(EditableText), 'Hello agent');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward).hitTestable());
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    sendCompleter.complete();
    await tester.pump();
  });

  testWidgets('shows tools button when onToolsPress provided', (tester) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        onToolsPress: () {
          final _ = Object();
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
  });

  testWidgets('shows tools button by default', (tester) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
  });

  testWidgets('shows manual compaction when conversation can compact', (
    tester,
  ) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        onCompact: _noop,
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.compress_outlined), findsOneWidget);
  });

  testWidgets('disables manual compaction when conversation cannot compact', (
    tester,
  ) async {
    var wasTapped = false;

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        onCompact: () => wasTapped = true,
        canCompact: false,
        compactDisabledHint:
            LocaleKeys.chats_screens_chat_conversation_model_required,
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    final compactIcon = find.byIcon(Icons.compress_outlined);
    expect(compactIcon, findsOneWidget);
    final compactPressable = find
        .ancestor(of: compactIcon, matching: find.byType(AuraPressable))
        .first;
    expect(tester.widget<AuraPressable>(compactPressable).onPressed, isNull);
    expect(
      find.descendant(
        of: compactPressable,
        matching: find.byIcon(Icons.info_outline),
      ),
      findsOneWidget,
    );

    await tester.tap(compactIcon);
    expect(wasTapped, isFalse);
  });

  testWidgets('blocks sending and shows disabled hint', (tester) async {
    var wasSent = false;

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) => wasSent = true,
        disabled: true,
        disabledHint: const Text('Select a model'),
      ),
    );

    await tester.enterText(find.byType(EditableText), 'Hello agent');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();

    expect(wasSent, isFalse);
    expect(find.text('Select a model'), findsOneWidget);
  });

  testWidgets('shows disabled Continue with reason', (tester) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        continueDisabledHint:
            LocaleKeys.chats_screens_chat_conversation_model_required,
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    final continueIcon = find.byIcon(Icons.play_circle_outline);
    expect(continueIcon, findsOneWidget);
    final continuePressable = find
        .ancestor(of: continueIcon, matching: find.byType(AuraPressable))
        .first;
    expect(tester.widget<AuraPressable>(continuePressable).onPressed, isNull);
    expect(
      find.descendant(
        of: continuePressable,
        matching: find.byIcon(Icons.info_outline),
      ),
      findsOneWidget,
    );
  });

  testWidgets('disables manual compaction while compaction is running', (
    tester,
  ) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        onCompact: _noop,
        isCompacting: true,
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    final compactIcon = find.byIcon(Icons.compress_outlined);
    expect(compactIcon, findsOneWidget);
    expect(
      tester
          .widget<AuraPressable>(
            find
                .ancestor(of: compactIcon, matching: find.byType(AuraPressable))
                .first,
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('shows disabled mic button with an audio support reason', (
    tester,
  ) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    if (kIsWeb) {
      expect(find.byIcon(Icons.mic_none_outlined), findsNothing);

      return;
    }

    final micButton = find.byKey(const ValueKey<String>('chat_voice_button'));
    expect(find.byIcon(Icons.mic_none_outlined), findsOneWidget);
    expect(
      tester
          .widget<AuraIconButton>(
            find.ancestor(of: micButton, matching: find.byType(AuraIconButton)),
          )
          .disabled,
      isTrue,
    );
    expect(
      find.byTooltip(
        '''The selected model doesn't support audio input. '''
        'Switch to a model that accepts audio.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('reports localized microphone permission denial', (tester) async {
    if (kIsWeb) return;

    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/recording.wav',
      fileName: 'recording.wav',
      displayName: 'recording.wav',
      mimeType: 'audio/wav',
      modality: .audio,
      sizeBytes: 1024,
    );
    final attachmentService = _FakeLocalChatAttachmentService(
      attachment,
      startError: const ChatMicrophonePermissionDeniedException(),
    );

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['audio'],
        attachmentService: attachmentService,
        onSendMessage: (_) => Future.value(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat_voice_button')));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Microphone permission denied. Allow microphone access in system '
        'settings, then try again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Recording'), findsNothing);
    expect(attachmentService.startCount, 1);
  });

  testWidgets('explains unsupported file and image inputs', (tester) async {
    overridePlatform(.linux);

    final _ = await pumpAndInit(
      tester,
      buildSubject(onSendMessage: (_) => Future.value()),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    final fileReason = find.byTooltip(
      '''The selected model doesn't support file input. '''
      'Switch to a model that accepts files.',
    );
    for (final label in ['Attach file', 'Choose from Directory']) {
      final row = find
          .ancestor(of: find.text(label), matching: find.byType(Row))
          .first;
      expect(find.descendant(of: row, matching: fileReason), findsOneWidget);
    }
    expect(
      find.byTooltip(
        '''The selected model doesn't support image input. '''
        'Switch to a model that accepts images.',
      ),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('automatically stops a voice recording at two minutes once', (
    tester,
  ) async {
    if (kIsWeb) return;

    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/recording.wav',
      fileName: 'recording.wav',
      displayName: 'recording.wav',
      mimeType: 'audio/wav',
      modality: .audio,
      sizeBytes: 1024,
    );
    final attachmentService = _FakeLocalChatAttachmentService(
      attachment,
      recordingResult: attachment,
    );

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['audio'],
        attachmentService: attachmentService,
        onSendMessage: (_) => Future.value(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat_voice_button')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Recording 00:00 / 02:00'), findsOneWidget);

    await tester.pump(const Duration(minutes: 2));
    await tester.pump();
    await tester.pump();

    expect(attachmentService.stopCount, 1);
    expect(find.text('recording.wav'), findsOneWidget);
    expect(find.textContaining('Recording'), findsNothing);
  });

  testWidgets('coalesces repeated manual recording stops', (tester) async {
    if (kIsWeb) return;

    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/recording.wav',
      fileName: 'recording.wav',
      displayName: 'recording.wav',
      mimeType: 'audio/wav',
      modality: .audio,
      sizeBytes: 1024,
    );
    final stopCompleter = Completer<MessageAttachmentToCreate?>();
    final attachmentService = _FakeLocalChatAttachmentService(
      attachment,
      stopCompleter: stopCompleter,
    );

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['audio'],
        attachmentService: attachmentService,
        onSendMessage: (_) => Future.value(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat_voice_button')));
    await tester.pump();
    await tester.pump();
    final stopButton = find.byKey(
      const ValueKey<String>('chat_voice_stop_button'),
    );
    await tester.tap(stopButton);
    await tester.tap(stopButton);
    await tester.pump();

    expect(attachmentService.stopCount, 1);
    stopCompleter.complete(attachment);
    await tester.pump();
    await tester.pump();

    expect(find.text('recording.wav'), findsOneWidget);
    expect(attachmentService.stopCount, 1);
  });

  testWidgets('canceling a voice recording does not add an attachment', (
    tester,
  ) async {
    if (kIsWeb) return;

    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/recording.wav',
      fileName: 'recording.wav',
      displayName: 'recording.wav',
      mimeType: 'audio/wav',
      modality: .audio,
      sizeBytes: 1024,
    );
    final attachmentService = _FakeLocalChatAttachmentService(attachment);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['audio'],
        attachmentService: attachmentService,
        onSendMessage: (_) => Future.value(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('chat_voice_button')));
    await tester.pump();
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('chat_voice_cancel_button')),
    );
    await tester.pump();
    await tester.pump();

    expect(attachmentService.cancelCount, 1);
    expect(find.text('recording.wav'), findsNothing);
    expect(find.textContaining('Recording'), findsNothing);
  });

  testWidgets('keeps camera cancellation silent', (tester) async {
    overridePlatform(.android);
    final previousImagePicker = ImagePickerPlatform.instance;
    addTearDown(() => ImagePickerPlatform.instance = previousImagePicker);
    ImagePickerPlatform.instance = _FakeImagePickerPlatform();

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['image'],
        onSendMessage: (_) => Future.value(),
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.photo_camera_outlined));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        '''Couldn't open the camera. Check camera permissions and try again.''',
      ),
      findsNothing,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows feedback when camera capture fails', (tester) async {
    overridePlatform(.android);
    final previousImagePicker = ImagePickerPlatform.instance;
    addTearDown(() => ImagePickerPlatform.instance = previousImagePicker);
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(
      error: .new('Camera unavailable'),
    );

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['image'],
        onSendMessage: (_) => Future.value(),
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.photo_camera_outlined));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        '''Couldn't open the camera. Check camera permissions and try again.''',
      ),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows mic button outside menu when audio is supported', (
    tester,
  ) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['text', 'audio'],
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    expect(
      find.byIcon(Icons.mic_none_outlined),
      kIsWeb ? findsNothing : findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
    expect(
      find.byIcon(Icons.mic_none_outlined),
      kIsWeb ? findsNothing : findsOneWidget,
    );
  });

  testWidgets('selects an existing Directory File without copying bytes', (
    tester,
  ) async {
    ChatDraft? sent;
    const asset = WorkspaceAsset(
      id: 'asset',
      name: 'notes.txt',
      mimeType: 'text/plain',
      sizeBytes: 5,
      checksum: 'unused',
    );
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (draft) => sent = draft,
        modalitiesInput: const ['text', 'file'],
        sharedFile: const WorkspaceFile(
          id: 'file',
          name: 'Stored notes',
          assetId: 'asset',
          revision: 1,
          asset: asset,
        ),
        sharedAssets: const _SharedAssets(asset),
      ),
    );
    await tester.tap(find.byIcon(Icons.tune_rounded));
    final _ = await tester.pump();
    await tester.tap(find.text(LocaleKeys.workspace_assets_existing.tr()));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Stored notes'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.bySemanticsIdentifier('chat_send_button').hitTestable(),
    );
    final _ = await tester.pumpAndSettle();
    expect(sent?.attachments.single.assetId, 'asset');
    expect(
      sent?.attachments.single.localPath,
      contains('workspace-asset://asset/'),
    );
    expect(sent?.attachments.single.localPath, contains('/ws-1/asset'));
  });

  testWidgets('discarding a Directory File draft leaves its asset available', (
    tester,
  ) async {
    const asset = WorkspaceAsset(
      id: 'asset',
      name: 'notes.txt',
      mimeType: 'text/plain',
      sizeBytes: 5,
      checksum: 'unused',
    );
    final attachmentService = _FakeLocalChatAttachmentService(
      const MessageAttachmentToCreate(
        localPath: 'workspace-asset://asset/ws-1/asset',
        fileName: 'notes.txt',
        displayName: 'Stored notes',
        mimeType: 'text/plain',
        modality: .file,
        sizeBytes: 5,
        assetId: 'asset',
      ),
    );
    final activeConversation = ValueNotifier<String?>('conversation-1');
    addTearDown(activeConversation.dispose);
    const sharedAssets = _SharedAssets(asset);
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) => Future<void>.value(),
        modalitiesInput: const ['text', 'file'],
        activeConversation: activeConversation,
        attachmentService: attachmentService,
        sharedFile: const WorkspaceFile(
          id: 'file',
          name: 'Stored notes',
          assetId: 'asset',
          revision: 1,
          asset: asset,
        ),
        sharedAssets: sharedAssets,
      ),
    );
    await tester.tap(find.byIcon(Icons.tune_rounded));
    final _ = await tester.pump();
    await tester.tap(find.text(LocaleKeys.workspace_assets_existing.tr()));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Stored notes'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune_rounded));
    final _ = await tester.pump();
    await tester.tap(find.text('Discard draft'));
    final _ = await tester.pumpAndSettle();

    expect(attachmentService.deletedPaths, isEmpty);
    expect(find.text('Stored notes'), findsNothing);
    expect(await sharedAssets.asset('asset'), same(asset));
  });

  testWidgets('shows file and hides photo attachment on macOS', (tester) async {
    overridePlatform(.macOS);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['text', 'image'],
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.attach_file), findsOneWidget);
    expect(find.byIcon(Icons.photo_outlined), findsNothing);
    expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows file attachment for audio on macOS', (tester) async {
    overridePlatform(.macOS);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['text', 'audio'],
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.attach_file), findsOneWidget);
    expect(find.byIcon(Icons.photo_outlined), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('keeps photo attachment visible outside macOS', (tester) async {
    overridePlatform(.linux);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['text', 'image'],
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.attach_file), findsOneWidget);
    expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows stop button when isBusy and onStop provided', (
    tester,
  ) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        isBusy: true,
        onStop: () {
          final _ = Object();
        },
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('chat_stop_generation')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat_send_button')),
      findsNothing,
    );
  });

  testWidgets('shows send for a busy text draft, then returns to stop', (
    tester,
  ) async {
    ChatDraft? sentDraft;
    var stopCount = 0;
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (draft) => sentDraft = draft,
        isBusy: true,
        onStop: () => stopCount++,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('chat_stop_generation')),
      findsOneWidget,
    );
    await tester.enterText(find.byType(EditableText), 'draft while busy');
    await tester.pump();

    final sendButton = find.byKey(const ValueKey<String>('chat_send_button'));
    expect(sendButton, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat_stop_generation')),
      findsNothing,
    );
    await tester.tap(sendButton);
    final _ = await tester.pumpAndSettle();

    expect(sentDraft?.text, 'draft while busy');
    expect(stopCount, 0);
    expect(
      find.byKey(const ValueKey<String>('chat_stop_generation')),
      findsOneWidget,
    );
    expect(sendButton, findsNothing);
  });

  testWidgets('does not expose stop button when isBusy is false', (
    tester,
  ) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        onStop: () {
          final _ = Object();
        },
      ),
    );

    expect(find.byIcon(Icons.stop_rounded).hitTestable(), findsNothing);
  });

  testWidgets('hides stop button while keeping input busy', (tester) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        isBusy: true,
        showStopButton: false,
        onStop: () {
          final _ = Object();
        },
      ),
    );

    final input = tester.widget<ChatInputWidget>(find.byType(ChatInputWidget));
    expect(input.isBusy, isTrue);
    expect(
      find.byKey(const ValueKey<String>('chat_stop_generation')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('chat_send_button')),
      findsOneWidget,
    );
  });

  testWidgets('hides stop button when onStop is null', (tester) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        isBusy: true,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('chat_stop_generation')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('chat_send_button')),
      findsOneWidget,
    );
  });

  testWidgets('tabs through composer controls to model and effort selector', (
    tester,
  ) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        onToolAccessModeChanged: (_) => _noop(),
        modelCompactControl: const Text('compact model'),
        modelSheetControl: const Text('sheet model'),
        reasoningSettingsControl: const Text('reasoning settings'),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(await tester.sendKeyEvent(.tab), isTrue);
    await tester.pump();
    expect(find.byIcon(Icons.build_circle_outlined), findsNothing);

    expect(await tester.sendKeyEvent(.tab), isTrue);
    expect(await tester.sendKeyEvent(.tab), isTrue);

    expect(await tester.sendKeyEvent(.enter), isTrue);
    final pumpCount = await tester.pumpAndSettle();
    expect(pumpCount, greaterThanOrEqualTo(0));

    expect(find.text('sheet model'), findsOneWidget);
    expect(find.text('reasoning settings'), findsOneWidget);
  });

  testWidgets('composer controls share one row in requested order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        onToolAccessModeChanged: (_) => _noop(),
        locale: const Locale('es'),
        modelSheetControl: const Text('sheet model'),
        agentSheetControl: const Text('sheet agent'),
        modelCompactControl: const Text(
          'compact model',
          overflow: .ellipsis,
          maxLines: 1,
        ),
        agentCompactControl: const Text('compact agent'),
        reasoningSettingsControl: const Text('reasoning settings'),
      ),
    );

    expect(find.text('compact model'), findsOneWidget);
    expect(find.text('compact agent'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    final controlKeys = [
      'chat_attachment_options_button',
      'chat_tool_access_mode',
      'chat_model_selector',
      'chat_voice_button',
      'chat_send_button',
    ];
    final centers = [
      for (final key in controlKeys)
        tester.getCenter(find.byKey(ValueKey<String>(key))),
    ];
    for (var index = 1; index < centers.length; index++) {
      expect(centers[index - 1].dy, closeTo(centers[index].dy, 1));
      if (index > 0) {
        expect(centers[index - 1].dx, lessThan(centers[index].dx));
      }
    }
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_selector')),
      findsNothing,
    );

    await tester.tap(find.text('compact model'));
    final pumpCount = await tester.pumpAndSettle();
    expect(pumpCount, greaterThanOrEqualTo(0));

    expect(find.text('sheet model'), findsOneWidget);
    expect(find.text('reasoning settings'), findsOneWidget);
  });

  testWidgets('model selector opens from blank space inside its target', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        modelCompactControl: const SizedBox(
          width: 200,
          height: 48,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('compact model'),
          ),
        ),
        modelSheetControl: const Text('sheet model'),
      ),
    );

    final target = tester.getRect(
      find.byKey(const ValueKey<String>('chat_model_selector')),
    );
    await tester.tapAt(.new(target.right - 8, target.center.dy));
    final pumpCount = await tester.pumpAndSettle();
    expect(pumpCount, greaterThanOrEqualTo(0));

    expect(find.text('sheet model'), findsOneWidget);
  });

  testWidgets('desktop uses menu model agent layout', (tester) async {
    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        modelCompactControl: const Text('compact model'),
        modelSheetControl: const Text('sheet model'),
        agentCompactControl: const Text('compact agent'),
        agentSheetControl: const Text('sheet agent'),
      ),
    );

    expect(find.text('compact model'), findsOneWidget);
    expect(find.text('compact agent'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    await tester.tap(find.text('compact model'));
    final pumpCount = await tester.pumpAndSettle();
    expect(pumpCount, greaterThanOrEqualTo(0));

    expect(find.text('sheet model'), findsOneWidget);
  });

  testWidgets('compact agent control opens sheet control', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        agentCompactControl: const Text('compact agent'),
        agentSheetControl: const Text('sheet agent'),
      ),
    );

    await tester.tapAt(tester.getCenter(find.text('compact agent')));
    final pumpCount = await tester.pumpAndSettle();
    expect(pumpCount, greaterThanOrEqualTo(0));

    expect(find.text('sheet agent'), findsOneWidget);
  });

  testWidgets('agent tile opens sheet', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        agentCompactControl: const Text('compact agent'),
        agentSheetControl: const Text('sheet agent'),
      ),
    );

    await tester.tapAt(tester.getCenter(find.text('compact agent')));
    final pumpCount = await tester.pumpAndSettle();
    expect(pumpCount, greaterThanOrEqualTo(0));

    expect(find.text('sheet agent'), findsOneWidget);
  });

  testWidgets('compact agent and model selectors show hover feedback', (
    tester,
  ) async {
    final previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy = .alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy = previousStrategy,
    );

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _ = await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        modelCompactControl: const Text('compact model'),
        modelSheetControl: const Text('sheet model'),
        agentCompactControl: const Text('compact agent'),
        agentSheetControl: const Text('sheet agent'),
      ),
    );

    final agent = find.byKey(const ValueKey<String>('chat_agent_selector'));
    final model = find.byKey(const ValueKey<String>('chat_model_selector'));
    final agentTile = find.descendant(
      of: agent,
      matching: find.byType(AuraTile),
    );
    final modelTile = find.descendant(
      of: model,
      matching: find.byType(AuraTile),
    );
    expect(agentTile, findsOneWidget);
    expect(modelTile, findsOneWidget);
    expect(tester.widget<AuraTile>(agentTile).onTap, isNotNull);
    expect(tester.widget<AuraTile>(modelTile).onTap, isNotNull);

    final agentLayer = find
        .descendant(of: agentTile, matching: find.byType(AnimatedContainer))
        .first;
    final modelLayer = find
        .descendant(of: modelTile, matching: find.byType(AnimatedContainer))
        .first;
    final agentColor = _animatedContainerColor(tester, agentLayer);
    final modelColor = _animatedContainerColor(tester, modelLayer);
    final mouse = await tester.createGesture(kind: .mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(agent));
    final _ = await tester.pumpAndSettle();
    expect(_animatedContainerColor(tester, agentLayer), isNot(agentColor));

    await mouse.moveTo(tester.getCenter(model));
    final _ = await tester.pumpAndSettle();
    expect(_animatedContainerColor(tester, modelLayer), isNot(modelColor));
  });
}

Color _animatedContainerColor(WidgetTester tester, Finder finder) {
  final decoration = tester.widget<AnimatedContainer>(finder).decoration;
  if (decoration case BoxDecoration(:final Color color)) return color;
  fail('Expected an animated container with a color.');
}

ConversationSkillSelectorState _skillSelectorState(int count) =>
    ConversationSkillSelectorState(
      loaded: [
        for (var index = 0; index < count; index++)
          AvailableSkill(
            id: 'skill-$index',
            slug: 'skill-$index',
            title: 'Skill $index',
            description: 'Description $index',
            content: '',
            source: .user,
            kind: .template,
            connectorReadiness: .ready,
          ),
      ],
      loadable: const [],
    );

void _noop() {
  final _ = Object();
}

class _TestFlutterFileDropChannel {
  static const _readFileChunkChannel =
      'dev.flutter.pigeon.flutter_file_drop_platform_interface.'
      'DropFileHostApi.readFileChunk';
  static const _releaseFileReadStreamChannel =
      'dev.flutter.pigeon.flutter_file_drop_platform_interface.'
      'DropFileHostApi.releaseFileReadStream';
  static const _releaseSessionChannel =
      'dev.flutter.pigeon.flutter_file_drop_platform_interface.'
      'DropFileHostApi.releaseSession';

  new() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockStreamHandler(
        const .new('flutter_file_drop/events'),
        .inline(
          onListen: (_, events) {
            _eventSink = events;
          },
          onCancel: (_) => _eventSink = null,
        ),
      )
      ..setMockMessageHandler(_readFileChunkChannel, _readFileChunk)
      ..setMockMessageHandler(_releaseFileReadStreamChannel, _emptyReply)
      ..setMockMessageHandler(_releaseSessionChannel, _emptyReply);
  }

  final StandardMessageCodec _codec = const .new();
  final _files = <String, ({Uint8List bytes, int size})>{};
  MockStreamHandlerEventSink? _eventSink;
  var _nextHandle = 0;

  void dropFile({
    required Offset position,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    int? fileSize,
  }) {
    final handle = 'file-${_nextHandle++}';
    final size = fileSize ?? bytes.length;
    _files[handle] = (bytes: bytes, size: size);
    final eventSink = _eventSink;
    if (eventSink == null) throw StateError('Drop event channel is not ready.');

    eventSink.success({
      'type': 'drop',
      'sessionId': 'chat-input-test',
      'globalX': position.dx,
      'globalY': position.dy,
      'items': [
        {
          'type': 'file',
          'handle': handle,
          'name': fileName,
          'mimeType': mimeType,
          'size': size,
        },
      ],
    });
  }

  Future<ByteData?> _readFileChunk(ByteData? message) async {
    if (message == null) {
      throw const FormatException('Missing file chunk request.');
    }
    final decoded = _codec.decodeMessage(message);
    if (decoded is! List<Object?> || decoded.length < 5) {
      throw const FormatException('Invalid file chunk request.');
    }
    final handle = decoded[1];
    final offset = decoded[3];
    final maxBytes = decoded[4];
    if (handle is! String || offset is! int || maxBytes is! int) {
      throw const FormatException('Invalid file chunk request fields.');
    }
    final file = _files[handle];
    if (file == null) throw StateError('Unknown dropped file handle.');
    final start = offset < file.size ? offset : file.size;
    final remaining = file.size - start;
    final length = remaining < maxBytes ? remaining : maxBytes;
    final chunk = Uint8List(length);
    final availableBytes = file.bytes.length - start;
    final copyLength = availableBytes < length ? availableBytes : length;
    if (copyLength > 0) {
      chunk.setRange(0, copyLength, file.bytes, start);
    }

    return _codec.encodeMessage(<Object?>[chunk]);
  }

  Future<ByteData?> _emptyReply(ByteData? _) async =>
      _codec.encodeMessage(<Object?>[null]);
}

class _FakeLocalChatAttachmentService(
  final MessageAttachmentToCreate attachment, {
  final Exception? copyError,
  final Exception? startError,
  final MessageAttachmentToCreate? recordingResult,
  final Completer<MessageAttachmentToCreate?>? stopCompleter,
}) implements LocalChatAttachmentService {
  final String storageNamespace = 'test';
  final deletedPaths = <String>[];
  Uint8List? copiedBytes;
  String? copiedFileName;
  int startCount = 0;
  int stopCount = 0;
  int cancelCount = 0;

  @override
  Future<MessageAttachmentToCreate> copyIntoAppStorage(
    String sourcePath, {
    String? displayName,
  }) async {
    if (copyError case final error?) throw error;

    return attachment.copyWith(
      displayName: displayName ?? attachment.displayName,
    );
  }

  @override
  Future<MessageAttachmentToCreate> copyBytesIntoAppStorage(
    Uint8List bytes, {
    required String fileName,
    required String displayName,
  }) async {
    if (copyError case final error?) throw error;
    copiedBytes = .fromList(bytes);
    copiedFileName = fileName;

    return attachment.copyWith(displayName: displayName);
  }

  @override
  Future<void> deleteAttachment(String localPath) {
    deletedPaths.add(localPath);

    return Future.value();
  }

  @override
  Future<void> startVoiceRecording() async {
    startCount++;
    if (startError case final error?) throw error;
  }

  @override
  Future<MessageAttachmentToCreate?> stopVoiceRecording() {
    stopCount++;
    if (stopCompleter case final completer?) return completer.future;

    return Future.value(recordingResult);
  }

  @override
  Future<MessageAttachmentToCreate> createToolResultAttachment({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String toolCallId,
  }) => throw UnimplementedError();

  @override
  @override
  Future<MessageAttachmentToCreate> createArchiveAttachment(
    ConversationArchiveAttachment _,
  ) => throw UnimplementedError();

  @override
  Future<Uint8List> readAttachmentBytes(String _) => throw UnimplementedError();

  @override
  Future<void> cancelVoiceRecording() async {
    cancelCount++;
  }
}

class _FakeImagePickerPlatform({final Exception? error})
    extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    if (error case final error?) throw error;

    return null;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeFilePickerPlatform(final List<fp.PlatformFile> result)
    extends fp.FilePickerPlatform {
  @override
  Future<List<fp.PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    fp.FileType type = fp.FileType.any,
    List<String>? allowedExtensions,
    void Function(fp.FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    fp.AndroidOptions androidOptions = const fp.AndroidOptions(),
    fp.DarwinOptions darwinOptions = const fp.DarwinOptions(),
    fp.WindowsOptions windowsOptions = const fp.WindowsOptions(),
    fp.LinuxOptions linuxOptions = const fp.LinuxOptions(),
    fp.WebOptions webOptions = const fp.WebOptions(),
  }) async => result;
}

base class _FakePlatformFile({
  @override required final String name,
  required final int size,
  required String path,
}) extends fp.PlatformFile {
  @override
  final Uri uri = .file(path);

  @override
  Never get xFile => throw UnimplementedError();

  @override
  int lengthSync() => size;

  @override
  Future<int> length() async => size;

  @override
  Never readAsBytes() => throw UnimplementedError();

  @override
  Never readAsByteStream() => throw UnimplementedError();
}

class const _SharedAssets(final WorkspaceAsset value)
    implements WorkspaceAssetRepository {
  @override
  Future<WorkspaceAsset> asset(String id) async => value;
  @override
  Future<Uint8List> bytes(String id) =>
      throw UnimplementedError('must not copy bytes');
  @override
  Future<WorkspaceAsset> upload(String name, Uint8List bytes) =>
      throw UnimplementedError('must not upload');
}
