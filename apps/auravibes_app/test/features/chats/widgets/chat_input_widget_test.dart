// Required: Tests repeat finders and fixture lookups for clarity.
import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    List<String> modalitiesInput = const [],
    LocalChatAttachmentService? attachmentService,
    Widget modelSheetControl = const SizedBox.shrink(),
    Widget agentSheetControl = const SizedBox.shrink(),
    Widget modelCompactControl = const SizedBox.shrink(),
    Widget agentCompactControl = const SizedBox.shrink(),
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
            return MaterialApp(
              home: Theme(
                data: .new(extensions: [AuraTheme.light]),
                child: AuraSnackBarHost(
                  child: Material(
                    child: Portal(
                      child: ChatInputWidget(
                        workspaceId: 'ws-1',
                        onSendMessage: onSendMessage,
                        onToolsPress: onToolsPress,
                        modelSheetControl: modelSheetControl,
                        agentSheetControl: agentSheetControl,
                        modelCompactControl: modelCompactControl,
                        agentCompactControl: agentCompactControl,
                        modalitiesInput: modalitiesInput,
                        disabled: disabled,
                        isBusy: isBusy,
                        showStopButton: showStopButton,
                        onStop: onStop,
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
    fp.FilePickerPlatform.instance = _FakeFilePickerPlatform(
      .new([
        .new(
          path: attachment.localPath,
          name: attachment.fileName,
          size: attachment.sizeBytes,
        ),
      ]),
    );

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
    fp.FilePickerPlatform.instance = _FakeFilePickerPlatform(
      .new([
        .new(
          path: attachment.localPath,
          name: attachment.fileName,
          size: attachment.sizeBytes,
        ),
      ]),
    );

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

  testWidgets('hides mic button when audio is unsupported', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    expect(find.byIcon(Icons.mic_none_outlined), findsNothing);
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

    await tester.tap(find.text('compact agent'));
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
}) implements LocalChatAttachmentService {
  final String storageNamespace = 'test';

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
  Future<void> deleteAttachment(String _) => Future.value();

  @override
  Future<void> startVoiceRecording() => Future.value();

  @override
  Future<MessageAttachmentToCreate?> stopVoiceRecording() async => null;

  @override
  Future<void> cancelVoiceRecording() => Future.value();
}

class _FakeFilePickerPlatform(final fp.FilePickerResult result)
    extends fp.FilePickerPlatform {
  @override
  Future<fp.FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    fp.FileType type = fp.FileType.any,
    List<String>? allowedExtensions,
    void Function(fp.FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
    fp.AndroidSAFOptions? androidSafOptions,
  }) async => result;
}
