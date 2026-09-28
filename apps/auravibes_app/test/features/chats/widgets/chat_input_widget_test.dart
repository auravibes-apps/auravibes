// Required: Tests repeat finders and fixture lookups for clarity.
import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
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
    bool disabled = false,
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
    Widget? reasoningControl,
    VoidCallback? onCompact,
    bool canCompact = true,
    String? compactDisabledHint,
    String? continueDisabledHint,
    Widget? disabledHint,
    bool isCompacting = false,
    ValueChanged<bool>? onDraftStatusChanged,
    ChatDraft? draftToLoad,
    ValueListenable<String?>? activeConversation,
  }) {
    return EasyLocalization(
      child: TestProviderScope(
        overrides: [
          workspaceSessionForRouteProvider('ws-1').overrideWithValue(
            const AsyncData(
              WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws-1')),
            ),
          ),
          if (attachmentService case final service?)
            localChatAttachmentServiceProvider.overrideWithValue(service),
        ],
        child: Builder(
          builder: (context) {
            Widget chatInput(String? conversationId) => ChatInputWidget(
              workspaceId: 'ws-1',
              onSendMessage: onSendMessage,
              onToolsPress: onToolsPress,
              modelSheetControl: modelSheetControl,
              agentSheetControl: agentSheetControl,
              modelCompactControl: modelCompactControl,
              agentCompactControl: agentCompactControl,
              onDraftStatusChanged: onDraftStatusChanged,
              conversationId: conversationId,
              reasoningControl: reasoningControl,
              draftToLoad: draftToLoad,
              modalitiesInput: modalitiesInput,
              onContinueAgent: onContinueAgent,
              continueDisabledHint: continueDisabledHint,
              disabledHint: disabledHint,
              compactDisabledHint: compactDisabledHint,
              disabled: disabled,
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
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            );
          },
        ),
      ),
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }

  Future<void> pumpAndInit(WidgetTester tester, Widget widget) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
    });
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  void overridePlatform(TargetPlatform platform) {
    debugDefaultTargetPlatformOverride = platform;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  testWidgets('reports text draft changes', (tester) async {
    final draftStatuses = <bool>[];

    await pumpAndInit(
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

    await pumpAndInit(
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

    await pumpAndInit(
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

    await pumpAndInit(
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
    final activeConversation = ValueNotifier<String?>('chat-1');
    addTearDown(activeConversation.dispose);
    var attempts = 0;

    await pumpAndInit(
      tester,
      buildSubject(
        activeConversation: activeConversation,
        onSendMessage: (_) async {
          attempts++;
          if (attempts == 1) throw StateError('send failed');
        },
      ),
    );
    await tester.enterText(find.byType(EditableText), 'unsent message');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward).hitTestable());
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
    final sendButton = find.descendant(
      of: find.byKey(const ValueKey<String>('chat_send_button')),
      matching: find.byType(AuraButton),
    );
    expect(tester.widget<AuraButton>(sendButton).disabled, isFalse);

    tester.widget<AuraButton>(sendButton).onPressed();
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
  });

  testWidgets('renders without error', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    expect(find.byType(ChatInputWidget), findsOneWidget);
    expect(find.byType(AuraInput), findsOneWidget);
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

    await pumpAndInit(
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
    final sendButton = find.descendant(
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
    await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['text', 'audio'],
        modelCompactControl: const Text('compact model'),
        modelSheetControl: const Text('sheet model'),
        agentCompactControl: const Text('compact agent'),
        agentSheetControl: const Text('sheet agent'),
        reasoningControl: const Text('reasoning control'),
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
      'chat_send_button',
      'chat_stop_generation',
    ]) {
      expect(find.byKey(ValueKey<String>(selector)), findsOneWidget);
    }
    expect(find.text('reasoning control'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat_voice_button')),
      kIsWeb ? findsNothing : findsOneWidget,
    );
  });

  testWidgets('clears text as soon as send is accepted', (tester) async {
    final sendCompleter = Completer<void>();
    ChatDraft? sentDraft;

    await pumpAndInit(
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

    await pumpAndInit(
      tester,
      buildSubject(
        modalitiesInput: const ['text', 'file'],
        attachmentService: _FakeLocalChatAttachmentService(attachment),
        onSendMessage: (draft) {
          sentDrafts.add(draft);

          return sendCompleter.future;
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.attach_file));
    final _ = await tester.pumpAndSettle();
    expect(find.text('report.pdf'), findsOneWidget);

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

    await pumpAndInit(
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

    await pumpAndInit(
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
        "The selected model doesn't support image input. "
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

    await pumpAndInit(
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

    await pumpAndInit(
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
    await pumpAndInit(
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
    await pumpAndInit(
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
    await pumpAndInit(
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

    await pumpAndInit(
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

    await pumpAndInit(
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
    await pumpAndInit(
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
    await pumpAndInit(
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
    await pumpAndInit(
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
            find.descendant(
              of: micButton,
              matching: find.byType(AuraIconButton),
            ),
          )
          .disabled,
      isTrue,
    );
    expect(
      find.byTooltip(
        "The selected model doesn't support audio input. "
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

    await pumpAndInit(
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

    await pumpAndInit(
      tester,
      buildSubject(onSendMessage: (_) => Future.value()),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    expect(
      find.byTooltip(
        "The selected model doesn't support file input. "
        'Switch to a model that accepts files.',
      ),
      findsOneWidget,
    );
    expect(
      find.byTooltip(
        "The selected model doesn't support image input. "
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

    await pumpAndInit(
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

    await pumpAndInit(
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

    await pumpAndInit(
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

    await pumpAndInit(
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
        "Couldn't open the camera. Check camera permissions and try again.",
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
      error: Exception('Camera unavailable'),
    );

    await pumpAndInit(
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
        "Couldn't open the camera. Check camera permissions and try again.",
      ),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows mic button outside menu when audio is supported', (
    tester,
  ) async {
    await pumpAndInit(
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

  testWidgets('shows file and hides photo attachment on macOS', (tester) async {
    overridePlatform(.macOS);

    await pumpAndInit(
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

    await pumpAndInit(
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

    await pumpAndInit(
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
    await pumpAndInit(
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

    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
  });

  testWidgets('does not expose stop button when isBusy is false', (
    tester,
  ) async {
    await pumpAndInit(
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
    await pumpAndInit(
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
    expect(find.byIcon(Icons.stop_rounded).hitTestable(), findsNothing);
  });

  testWidgets('hides stop button when onStop is null', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        isBusy: true,
      ),
    );

    expect(find.byIcon(Icons.stop_rounded), findsNothing);
  });

  testWidgets('tabs from input to more button and opens with enter', (
    tester,
  ) async {
    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(await tester.sendKeyEvent(.tab), isTrue);
    await tester.pump();
    expect(find.byIcon(Icons.build_circle_outlined), findsNothing);

    expect(await tester.sendKeyEvent(.enter), isTrue);
    await tester.pump();

    expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
  });

  testWidgets('compact controls use menu model agent layout', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpAndInit(
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

  testWidgets('desktop uses menu model agent layout', (tester) async {
    await pumpAndInit(
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

    await pumpAndInit(
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

  testWidgets('agent control opens sheet with a non-interactive tile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        agentCompactControl: const AuraTile(child: Text('compact agent')),
        agentSheetControl: const Text('sheet agent'),
      ),
    );

    await tester.tapAt(tester.getCenter(find.text('compact agent')));
    final pumpCount = await tester.pumpAndSettle();
    expect(pumpCount, greaterThanOrEqualTo(0));

    expect(find.text('sheet agent'), findsOneWidget);
  });
}

void _noop() {
  final _ = Object();
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
