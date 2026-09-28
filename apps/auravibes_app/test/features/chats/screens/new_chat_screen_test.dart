import 'dart:async';
import 'dart:io';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/workspaces/models/switch_status.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_switcher.dart';
import 'package:auravibes_app/features/workspaces/providers/last_workspace_selection_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

Future<void> _pumpNewChatWithinPausedBranch(
  WidgetTester tester, {
  required List<Object> overrides,
  String workspaceId = 'test-ws',
  bool tickerEnabled = false,
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      TestableApp(
        child: TickerMode(
          enabled: tickerEnabled,
          child: AuraThemeScope(
            theme: .light,
            child: Theme(
              data: .new(),
              child: Portal(child: NewChatScreen(workspaceId: workspaceId)),
            ),
          ),
        ),
        overrides: overrides,
        workspaceId: workspaceId,
      ),
    );
    await Future<void>.delayed(.zero);
  });
  await tester.pump();
  final _ = await tester.pumpAndSettle();
}

WorkspaceEntity _workspace(String id) => WorkspaceEntity(
  id: id,
  name: 'Personal',
  type: .local,
  createdAt: .new(2026),
  updatedAt: .new(2026),
);

WorkspaceModelSelectionWithConnectionEntity _mediaModelSelection() =>
    WorkspaceModelSelectionWithConnectionEntity(
      workspaceModelSelection: .new(
        id: 'model',
        modelId: 'test-model',
        modelConnectionId: 'connection',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        modalitiesInput: const ['text', 'file', 'audio'],
      ),
      modelConnection: .new(
        id: 'connection',
        name: 'Test',
        modelId: 'test-model',
        workspaceId: 'test-ws',
        hasKey: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      modelsProvider: const .new(id: 'provider', name: 'Test', type: null),
    );

class _FailOnceWorkspaceSelectionRepository
    implements WorkspaceSelectionRepository {
  final firstSave = Completer<void>();
  final savedWorkspaceIds = <String>[];

  @override
  Future<void> clearIfMatches(String workspaceId) => Future<void>.value();

  @override
  Future<String?> read() async => null;

  @override
  Future<void> save(String workspaceId) {
    savedWorkspaceIds.add(workspaceId);
    if (savedWorkspaceIds.length == 1) return firstSave.future;

    return Future<void>.value();
  }
}

class _FakeGoRouter implements GoRouter {
  String? lastLocation;

  @override
  void go(String location, {Object? extra}) => lastLocation = location;

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _MediaDraftAttachmentService(
  final File draftFile,
  final File recordingFile,
) implements LocalChatAttachmentService {
  final String storageNamespace = 'test';
  bool recordingActive = false;
  int recordingCancels = 0;

  @override
  Future<MessageAttachmentToCreate> copyIntoAppStorage(
    String sourcePath, {
    String? displayName,
  }) {
    final copied = File(sourcePath).copySync(draftFile.path);

    return Future.value(
      MessageAttachmentToCreate(
        localPath: copied.path,
        fileName: 'source.pdf',
        displayName: displayName ?? 'source.pdf',
        mimeType: 'application/pdf',
        modality: .file,
        sizeBytes: copied.lengthSync(),
      ),
    );
  }

  @override
  Future<void> deleteAttachment(String localPath) {
    final file = File(localPath);
    if (file.existsSync()) {
      file.deleteSync();
    }

    return Future.value();
  }

  @override
  Future<void> startVoiceRecording() {
    recordingActive = true;
    final _ = recordingFile.writeAsStringSync('recording');

    return Future.value();
  }

  @override
  Future<MessageAttachmentToCreate?> stopVoiceRecording() => Future.value();

  @override
  Future<void> cancelVoiceRecording() {
    recordingActive = false;
    recordingCancels++;
    if (recordingFile.existsSync()) {
      recordingFile.deleteSync();
    }

    return Future.value();
  }

  @override
  Future<MessageAttachmentToCreate> createArchiveAttachment(
    ConversationArchiveAttachment _,
  ) => throw UnimplementedError();

  @override
  Future<Uint8List> readAttachmentBytes(String _) => throw UnimplementedError();
}

class _MediaFilePicker(final String path) extends fp.FilePickerPlatform {
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
  }) async => [_MediaPlatformFile(path)];
}

base class _MediaPlatformFile(@override final String path)
    extends fp.PlatformFile {
  @override
  final String name = 'source.pdf';

  @override
  Uri get uri => .file(path);

  @override
  Never get xFile => throw UnimplementedError();

  @override
  int lengthSync() => File(path).lengthSync();

  @override
  Future<int> length() async => lengthSync();

  @override
  Never readAsBytes() => throw UnimplementedError();

  @override
  Never readAsByteStream() => throw UnimplementedError();
}

List<Object> _newChatOverrides({
  NewChatState state = const NewChatState(),
  List<WorkspaceEntity>? workspaces,
  WorkspaceModelSelectionWithConnectionEntity? modelSelection,
}) => [
  newChatProvider('test-ws').overrideWithValue(state),
  workspaceModelSelectionByIdProvider(
    'test-ws',
    'model',
  ).overrideWithValue(AsyncData(modelSelection)),
  listModelsGroupedByProviderProvider.overrideWith(
    (ref, workspaceId) => Stream.value({}),
  ),
  agentsProvider('test-ws').overrideWith((ref) => Stream.value(const [])),
  allWorkspacesProvider.overrideWithValue(
    AsyncData(workspaces ?? [_workspace('test-ws')]),
  ),
];

void main() {
  test('constructor sets workspaceId', () {
    const screen = NewChatScreen(workspaceId: 'test-ws');
    expect(screen.workspaceId, 'test-ws');
  });

  test('constructor accepts different workspaceIds', () {
    const screen = NewChatScreen(workspaceId: 'other-id');
    expect(screen.workspaceId, 'other-id');
  });

  group('NewChatState', () {
    test('default values', () {
      const state = NewChatState();
      expect(state.modelId, isNull);
      expect(state.providerId, isNull);
      expect(state.isLoading, isFalse);
    });

    test('copyWith preserves values', () {
      const state = NewChatState(modelId: 'm1', providerId: 'p1');
      final copied = state.copyWith(isLoading: true);
      expect(copied.modelId, 'm1');
      expect(copied.providerId, 'p1');
      expect(copied.isLoading, isTrue);
    });

    test('copyWith allows nulling modelId', () {
      const state = NewChatState(modelId: 'm1');
      final copied = state.copyWith(modelId: null);
      expect(copied.modelId, isNull);
      expect(copied.providerId, isNull);
    });

    test('equality works', () {
      const a = NewChatState(modelId: 'm1');
      const b = NewChatState(modelId: 'm1');
      expect(a, equals(b));
    });

    test('inequality works', () {
      const a = NewChatState(modelId: 'm1');
      const b = NewChatState(modelId: 'm2');
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistent with equality', () {
      const a = NewChatState(modelId: 'm1');
      const b = NewChatState(modelId: 'm1');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes fields', () {
      const state = NewChatState(modelId: 'm1', isLoading: true);
      final str = state.toString();
      expect(str, contains('m1'));
      expect(str, contains('true'));
    });
  });

  group('render', () {
    testWidgets('canceling workspace switch preserves unsent text', (
      tester,
    ) async {
      await _pumpNewChatWithinPausedBranch(
        tester,
        overrides: _newChatOverrides(
          state: const NewChatState(modelId: 'model'),
          workspaces: [_workspace('test-ws'), _workspace('target-ws')],
        ),
        tickerEnabled: true,
      );

      final textField = find.byType(EditableText).first;
      await tester.enterText(textField, 'unsent draft');
      await tester.pump();
      await tester.pump();
      final selector = tester.widget<AuraDropdownSelector<String>>(
        find.byKey(const Key('new_chat_workspace_selector')),
      );
      selector.onChanged?.call('target-ws');
      final _ = await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();

      expect(selector.focusNode?.hasFocus, isTrue);
      expect(
        tester.widget<EditableText>(textField).controller.text,
        'unsent draft',
      );
      expect(find.byType(NewChatScreen), findsOneWidget);
    });

    testWidgets('failed switch keeps draft and retry completes switch', (
      tester,
    ) async {
      final selectionRepository = _FailOnceWorkspaceSelectionRepository();
      final router = _FakeGoRouter();
      final overrides = [
        ..._newChatOverrides(
          state: const NewChatState(modelId: 'model'),
          workspaces: [_workspace('test-ws'), _workspace('target-ws')],
        ),
        newChatProvider('target-ws')
            .overrideWithValue(const NewChatState(modelId: 'model')),
        workspaceModelSelectionByIdProvider(
          'target-ws',
          'model',
        ).overrideWithValue(const AsyncData(null)),
        agentsProvider('target-ws')
            .overrideWith((ref) => Stream.value(const [])),
        lastWorkspaceSelectionRepositoryProvider.overrideWithValue(
          selectionRepository,
        ),
        routerProvider.overrideWithValue(router),
      ];
      await _pumpNewChatWithinPausedBranch(
        tester,
        overrides: overrides,
        tickerEnabled: true,
      );

      final textField = find.byType(EditableText).first;
      await tester.enterText(textField, 'unsent draft');
      await tester.pump();
      await tester.pump();
      final selector = tester.widget<AuraDropdownSelector<String>>(
        find.byKey(const Key('new_chat_workspace_selector')),
      );
      selector.onChanged?.call('target-ws');
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pump();
      expect(find.text('Switching workspace...'), findsOneWidget);
      final semantics = tester.ensureSemantics();
      final progress = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.role == .status,
      );
      expect(progress, findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Switching workspace...')),
        isSemantics(label: 'Switching workspace...', role: .status),
      );
      expect(
        find.ancestor(
          of: find.byType(ChatInputWidget),
          matching: find.byWidgetPredicate(
            (widget) => widget is IgnorePointer && widget.ignoring,
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<EditableText>(textField).focusNode.hasFocus,
        isFalse,
      );
      await tester.pump(const Duration(milliseconds: 350));
      final switchStateUnderTest = ProviderScope.containerOf(
        tester.element(find.byType(NewChatScreen)),
        listen: false,
      ).read(workspaceSwitcherProvider);
      expect(switchStateUnderTest.status, SwitchStatus.loading);
      await tester.pump();
      expect(find.text('Switching workspace...'), findsOneWidget);
      selectionRepository.firstSave.completeError(
        StateError('Unable to save selected workspace.'),
      );
      await tester.pump();
      final _ = await tester.pumpAndSettle();

      expect(
        find.text('Failed to switch workspace. Please try again.'),
        findsOneWidget,
      );
      expect(selector.focusNode?.hasFocus, isTrue);
      final retry = find.byKey(
        const ValueKey<String>('workspace_switch_retry'),
      );
      expect(retry, findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Retry')),
        isSemantics(label: 'Retry', isButton: true, hasTapAction: true),
      );
      expect(
        tester.widget<EditableText>(textField).controller.text,
        'unsent draft',
      );
      expect(find.byType(NewChatScreen), findsOneWidget);

      await tester.enterText(textField, 'updated draft after failure');
      await tester.pump();
      expect(
        find.ancestor(
          of: find.byType(ChatInputWidget),
          matching: find.byWidgetPredicate(
            (widget) => widget is IgnorePointer && widget.ignoring,
          ),
        ),
        findsNothing,
      );
      bool retryFocused() =>
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<AuraIconButton>()
              ?.key ==
          const ValueKey<String>('workspace_switch_retry');
      for (var attempt = 0; attempt < 20 && !retryFocused(); attempt++) {
        final _ = await tester.sendKeyEvent(.tab);
        await tester.pump();
      }
      expect(retryFocused(), isTrue);
      final _ = await tester.sendKeyEvent(.enter);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      expect(
        tester.widget<EditableText>(textField).controller.text,
        'updated draft after failure',
      );
      await tester.tap(find.text('Discard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(router.lastLocation, '/workspaces/target-ws/chat/new');
      expect(selectionRepository.savedWorkspaceIds, ['target-ws', 'target-ws']);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NewChatScreen)),
        listen: false,
      );
      expect(
        container.read(workspaceSwitcherProvider).status,
        SwitchStatus.idle,
      );
      await _pumpNewChatWithinPausedBranch(
        tester,
        overrides: overrides,
        workspaceId: 'target-ws',
        tickerEnabled: true,
      );
      final switchedTextField = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(switchedTextField.controller.text, isEmpty);
      expect(switchedTextField.focusNode.hasFocus, isTrue);
      semantics.dispose();
    });

    testWidgets(
      'media drafts survive cancel and failure until switch succeeds',
      (tester) async {
        if (kIsWeb) return;

        final directory = Directory.systemTemp.createTempSync(
          'new-chat-media-',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final sourceFile = File('${directory.path}/source.pdf')
          ..writeAsStringSync('draft attachment');
        final draftFile = File('${directory.path}/draft.pdf');
        final recordingFile = File('${directory.path}/recording.m4a');
        final attachmentService = _MediaDraftAttachmentService(
          draftFile,
          recordingFile,
        );
        final previousPicker = fp.FilePickerPlatform.instance;
        addTearDown(() => fp.FilePickerPlatform.instance = previousPicker);
        fp.FilePickerPlatform.instance = _MediaFilePicker(sourceFile.path);
        final selectionRepository = _FailOnceWorkspaceSelectionRepository();
        final router = _FakeGoRouter();

        await _pumpNewChatWithinPausedBranch(
          tester,
          overrides: [
            ..._newChatOverrides(
              state: const NewChatState(modelId: 'model'),
              workspaces: [_workspace('test-ws'), _workspace('target-ws')],
              modelSelection: _mediaModelSelection(),
            ),
            localChatAttachmentServiceProvider.overrideWithValue(
              attachmentService,
            ),
            lastWorkspaceSelectionRepositoryProvider.overrideWithValue(
              selectionRepository,
            ),
            routerProvider.overrideWithValue(router),
          ],
          tickerEnabled: true,
        );

        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.attach_file));
        final _ = await tester.pumpAndSettle();
        expect(draftFile.existsSync(), isTrue);
        expect(find.text('source.pdf'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('chat_voice_button')),
        );
        await tester.pump();
        expect(attachmentService.recordingActive, isTrue);
        expect(recordingFile.existsSync(), isTrue);

        final selector = tester.widget<AuraDropdownSelector<String>>(
          find.byKey(const Key('new_chat_workspace_selector')),
        );
        selector.onChanged?.call('target-ws');
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Keep editing'));
        final _ = await tester.pumpAndSettle();
        expect(router.lastLocation, isNull);
        expect(draftFile.existsSync(), isTrue);
        expect(recordingFile.existsSync(), isTrue);
        expect(attachmentService.recordingActive, isTrue);
        expect(attachmentService.recordingCancels, 0);

        selector.onChanged?.call('target-ws');
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Discard'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(selectionRepository.savedWorkspaceIds, ['target-ws']);
        expect(draftFile.existsSync(), isTrue);
        expect(recordingFile.existsSync(), isTrue);
        selectionRepository.firstSave.completeError(StateError('save failed'));
        final _ = await tester.pumpAndSettle();
        expect(router.lastLocation, isNull);
        expect(draftFile.existsSync(), isTrue);
        expect(recordingFile.existsSync(), isTrue);
        expect(attachmentService.recordingActive, isTrue);
        expect(attachmentService.recordingCancels, 0);

        await tester.tap(
          find.byKey(const ValueKey<String>('workspace_switch_retry')),
        );
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Discard'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        final _ = await tester.pumpAndSettle();
        expect(router.lastLocation, '/workspaces/target-ws/chat/new');
        expect(draftFile.existsSync(), isTrue);
        expect(recordingFile.existsSync(), isTrue);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(draftFile.existsSync(), isFalse);
        expect(recordingFile.existsSync(), isFalse);
        expect(attachmentService.recordingCancels, 1);
        expect(sourceFile.existsSync(), isTrue);
      },
    );
    testWidgets('keeps New Chat listeners active in a paused branch', (
      tester,
    ) async {
      await _pumpNewChatWithinPausedBranch(
        tester,
        overrides: _newChatOverrides(),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TickerMode &&
              widget.enabled &&
              widget.child is ConsumerWidget,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders unavailable New Chat for an unauthenticated workspace',
      (tester) async {
        await _pumpNewChatWithinPausedBranch(
          tester,
          overrides: [
            ..._newChatOverrides(),
            workspaceAvailabilityProvider('test-ws').overrideWith(
              (ref) async => const WorkspaceAuthenticationRequired(
                .new(
                  CloudWorkspaceRef(
                    localWorkspaceId: 'test-ws',
                    serverUrl: 'https://example.com',
                    accountId: 'account-1',
                    cloudWorkspaceId: 1,
                  ),
                ),
              ),
            ),
          ],
          tickerEnabled: true,
        );
        expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
        expect(
          tester.widget<ChatInputWidget>(find.byType(ChatInputWidget)).disabled,
          isTrue,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is TickerMode &&
                widget.enabled &&
                widget.child is ConsumerWidget,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders NewChatScreen', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: AuraThemeScope(
              theme: .light,
              child: Theme(
                data: .new(),
                child: const Portal(
                  child: NewChatScreen(workspaceId: 'test-ws'),
                ),
              ),
            ),
            overrides: _newChatOverrides(),
            workspaceId: 'test-ws',
          ),
        );
        await Future<void>.delayed(.zero);
      });
      final _ = await tester.pumpAndSettle();
      expect(find.byType(NewChatScreen), findsOneWidget);
      expect(find.byType(AuraScreen), findsOneWidget);
      expect(find.byType(ChatInputWidget), findsOneWidget);
      expect(find.text('Select a model to enable messaging.'), findsOneWidget);
      expect(
        find.byKey(const Key('new_chat_workspace_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('workspace_selector')),
        findsOneWidget,
      );
      expect(find.text('Personal'), findsOneWidget);
    });

    testWidgets('shows loading overlay while conversation starts', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: AuraThemeScope(
              theme: .light,
              child: Theme(
                data: .new(),
                child: const Portal(
                  child: NewChatScreen(workspaceId: 'test-ws'),
                ),
              ),
            ),
            overrides: _newChatOverrides(
              state: const NewChatState(isLoading: true),
            ),
            workspaceId: 'test-ws',
          ),
        );
        await Future<void>.delayed(.zero);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester
            .widget<AuraLoadingOverlay>(find.byType(AuraLoadingOverlay))
            .isLoading,
        isTrue,
      );
    });
  });
}
