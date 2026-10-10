import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/widgets/chat_attachment_draft_preview.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final previousAudioPlatform = JustAudioPlatform.instance;
  final audioPlatform = _FakeJustAudioPlatform();

  setUpAll(() {
    JustAudioPlatform.instance = audioPlatform;
  });
  setUp(audioPlatform.reset);
  tearDownAll(() {
    JustAudioPlatform.instance = previousAudioPlatform;
  });

  const attachment = MessageAttachmentToCreate(
    localPath: '/tmp/report.pdf',
    fileName: 'report.pdf',
    displayName: 'Report',
    mimeType: 'application/pdf',
    modality: .file,
    sizeBytes: 2048,
  );

  Widget buildSubject({
    required MessageAttachmentToCreate attachment,
    required ValueChanged<MessageAttachmentToCreate> onRemove,
    List<MessageAttachmentToCreate>? attachments,
    bool enabled = true,
    Locale locale = const Locale('en'),
  }) {
    return EasyLocalization(
      child: Builder(
        builder: (context) => AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: Material(
              child: _PreviewComposer(
                attachments: attachments ?? [attachment],
                onRemove: onRemove,
                enabled: enabled,
              ),
            ),
            theme: .new(),
            locale: context.locale,
            localizationsDelegates: [
              ...context.localizationDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: context.supportedLocales,
          ),
        ),
      ),
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: locale,
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
  }

  void pressAudioButton(WidgetTester tester, {int index = 0}) {
    final buttons = find.byType(AuraIconButton);
    tester.widget<AuraIconButton>(buttons.at(index)).onPressed?.call();
  }

  testWidgets('renders filename, MIME type, and size', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(attachment: attachment, onRemove: _ignoreAttachment),
    );

    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('application/pdf - 2.0 KB'), findsOneWidget);
  });

  testWidgets('uses Spanish separators for attachment size', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: attachment.copyWith(sizeBytes: 1536),
        onRemove: _ignoreAttachment,
        locale: const Locale('es'),
      ),
    );

    expect(find.text('application/pdf - 1,5 KB'), findsOneWidget);
  });

  testWidgets('renders an image thumbnail when the platform supports files', (
    tester,
  ) async {
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: attachment.copyWith(
          fileName: 'photo.png',
          mimeType: 'image/png',
          modality: .image,
        ),
        onRemove: _ignoreAttachment,
      ),
    );

    expect(find.byType(Image), kIsWeb ? findsNothing : findsOneWidget);
  });

  testWidgets('provides a fallback when an image cannot load', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: attachment.copyWith(
          fileName: 'missing.png',
          mimeType: 'image/png',
          modality: .image,
        ),
        onRemove: _ignoreAttachment,
      ),
    );

    final errorBuilder = tester.widget<Image>(find.byType(Image)).errorBuilder;
    if (errorBuilder == null) fail('Expected an image error builder.');
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) =>
              errorBuilder(context, StateError('Image decode failed'), .empty),
        ),
      ),
    );

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });

  testWidgets('forwards the remove action', (tester) async {
    MessageAttachmentToCreate? removed;
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: attachment,
        onRemove: (value) => removed = value,
      ),
    );

    final onDeleted = tester
        .widget<InputChip>(find.byType(InputChip))
        .onDeleted;
    expect(onDeleted, isNotNull);
    onDeleted?.call();

    expect(removed, same(attachment));
  });

  testWidgets('disables the remove action when requested', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: attachment,
        onRemove: _ignoreAttachment,
        enabled: false,
      ),
    );

    expect(tester.widget<InputChip>(find.byType(InputChip)).onDeleted, isNull);
  });

  test('a new preview waits for the active preview to stop', () async {
    final coordinator = ChatAttachmentAudioPreviewCoordinator();
    final firstOwner = ChatAttachmentAudioPreviewOwner();
    final secondOwner = ChatAttachmentAudioPreviewOwner();
    final firstStop = Completer<void>();
    var firstStopCalled = false;

    expect(
      await coordinator.activate(firstOwner, () {
        firstStopCalled = true;

        return firstStop.future;
      }),
      isTrue,
    );

    final secondActivation = coordinator.activate(
      secondOwner,
      Future<void>.value,
    );
    var secondActivated = false;
    unawaited(() async {
      secondActivated = await secondActivation;
    }());
    await Future<void>.delayed(.zero);

    expect(firstStopCalled, isTrue);
    expect(secondActivated, isFalse);

    firstStop.complete();
    expect(await secondActivation, isTrue);
    expect(secondActivated, isTrue);
    coordinator.dispose();
  });

  testWidgets('plays and stops local voice attachments', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: attachment.copyWith(
          localPath: '/tmp/voice.wav',
          fileName: 'voice.wav',
          mimeType: 'audio/wav',
          modality: .audio,
        ),
        onRemove: _ignoreAttachment,
      ),
    );

    await tester.runAsync(() async {
      pressAudioButton(tester);
      await audioPlatform.loadStarted.future.timeout(
        const Duration(seconds: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();

    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    expect(audioPlatform.sources, ['/tmp/voice.wav']);

    await tester.runAsync(() async {
      pressAudioButton(tester);
      await audioPlatform.disposeStarted.future.timeout(
        const Duration(seconds: 1),
      );
    });
    await tester.pump();

    expect(audioPlatform.disposeCount, greaterThanOrEqualTo(1));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('resets playback after a voice attachment completes', (
    tester,
  ) async {
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: attachment.copyWith(
          localPath: '/tmp/voice.wav',
          fileName: 'voice.wav',
          mimeType: 'audio/wav',
          modality: .audio,
        ),
        onRemove: _ignoreAttachment,
      ),
    );
    await tester.runAsync(() async {
      pressAudioButton(tester);
      await audioPlatform.loadStarted.future.timeout(
        const Duration(seconds: 1),
      );
    });
    await tester.pump();
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

    await tester.runAsync(() async {
      audioPlatform.completePlayback();
      await Future<void>.delayed(.zero);
    });
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.runAsync(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await audioPlatform.disposeStarted.future.timeout(
        const Duration(seconds: 1),
      );
    });
  });

  testWidgets('stops playback when a voice attachment is removed', (
    tester,
  ) async {
    MessageAttachmentToCreate? removed;
    final voiceAttachment = attachment.copyWith(
      localPath: '/tmp/voice.wav',
      fileName: 'voice.wav',
      mimeType: 'audio/wav',
      modality: .audio,
    );
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: voiceAttachment,
        onRemove: (value) => removed = value,
      ),
    );
    await tester.runAsync(() async {
      pressAudioButton(tester);
      await audioPlatform.loadStarted.future.timeout(
        const Duration(seconds: 1),
      );
    });
    await tester.pump();

    await tester.runAsync(() async {
      tester.widget<InputChip>(find.byType(InputChip)).onDeleted?.call();
      await tester.pump();
      await audioPlatform.disposeStarted.future.timeout(
        const Duration(seconds: 1),
      );
    });
    await tester.pump();

    expect(removed, same(voiceAttachment));
    expect(find.byType(InputChip), findsNothing);
    expect(audioPlatform.disposeCount, greaterThanOrEqualTo(1));
  });

  testWidgets(
    'reports playback failure, retries, and keeps removal available',
    (tester) async {
      final voiceAttachment = attachment.copyWith(
        localPath: '/tmp/private/voice.wav',
        fileName: 'voice.wav',
        mimeType: 'audio/wav',
        modality: .audio,
      );
      MessageAttachmentToCreate? removed;
      await pumpAndInit(
        tester,
        buildSubject(
          attachment: voiceAttachment,
          onRemove: (value) => removed = value,
        ),
      );
      audioPlatform.failNextLoad = true;

      await tester.runAsync(() async {
        pressAudioButton(tester);
        await audioPlatform.loadStarted.future.timeout(
          const Duration(seconds: 1),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();

      expect(
        find.text('Audio preview failed. Retry or remove this attachment.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.textContaining('/tmp/private/voice.wav'), findsNothing);
      expect(find.textContaining('private platform error'), findsNothing);

      await tester.runAsync(() async {
        pressAudioButton(tester);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();

      expect(audioPlatform.sources, [
        '/tmp/private/voice.wav',
        '/tmp/private/voice.wav',
      ]);
      expect(
        find.text('Audio preview failed. Retry or remove this attachment.'),
        findsNothing,
      );
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

      tester.widget<InputChip>(find.byType(InputChip)).onDeleted?.call();
      await tester.pump();
      expect(removed, same(voiceAttachment));
      expect(find.byType(InputChip), findsNothing);
    },
  );

  testWidgets('does not carry a preview error to the next attachment', (
    tester,
  ) async {
    final first = attachment.copyWith(
      localPath: '/tmp/first.wav',
      fileName: 'first.wav',
      mimeType: 'audio/wav',
      modality: .audio,
    );
    final second = attachment.copyWith(
      localPath: '/tmp/second.wav',
      fileName: 'second.wav',
      mimeType: 'audio/wav',
      modality: .audio,
    );
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: first,
        attachments: [first, second],
        onRemove: _ignoreAttachment,
      ),
    );
    audioPlatform.failNextLoad = true;
    await tester.runAsync(() async {
      pressAudioButton(tester);
      await audioPlatform.loadStarted.future.timeout(
        const Duration(seconds: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();
    expect(
      find.text('Audio preview failed. Retry or remove this attachment.'),
      findsOneWidget,
    );

    tester.widget<InputChip>(find.byType(InputChip).first).onDeleted?.call();
    await tester.pump();

    expect(find.byType(InputChip), findsOneWidget);
    expect(
      find.text('Audio preview failed. Retry or remove this attachment.'),
      findsNothing,
    );
  });

  testWidgets('starting another preview stops the first and updates both', (
    tester,
  ) async {
    final first = attachment.copyWith(
      localPath: '/tmp/first.wav',
      fileName: 'first.wav',
      mimeType: 'audio/wav',
      modality: .audio,
    );
    final second = attachment.copyWith(
      localPath: '/tmp/second.wav',
      fileName: 'second.wav',
      mimeType: 'audio/wav',
      modality: .audio,
    );
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: first,
        attachments: [first, second],
        onRemove: _ignoreAttachment,
      ),
    );
    await tester.runAsync(() async {
      pressAudioButton(tester);
      await audioPlatform.loadStarted.future.timeout(
        const Duration(seconds: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    final firstPlayerId = audioPlatform.players.keys.single;

    await tester.runAsync(() async {
      pressAudioButton(tester, index: 1);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();

    expect(audioPlatform.sources, ['/tmp/first.wav', '/tmp/second.wav']);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    expect(audioPlatform.disposedPlayerIds, [firstPlayerId]);
  });

  testWidgets('restarting waits for an in-flight stop to finish', (
    tester,
  ) async {
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: attachment.copyWith(
          localPath: '/tmp/voice.wav',
          fileName: 'voice.wav',
          mimeType: 'audio/wav',
          modality: .audio,
        ),
        onRemove: _ignoreAttachment,
      ),
    );
    await tester.runAsync(() async {
      pressAudioButton(tester);
      await audioPlatform.loadStarted.future.timeout(
        const Duration(seconds: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();

    audioPlatform.stopGate = Completer<void>();
    await tester.runAsync(() async {
      pressAudioButton(tester);
      await audioPlatform.stopStarted.future.timeout(
        const Duration(seconds: 1),
      );
    });
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.runAsync(() async {
      pressAudioButton(tester);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    expect(audioPlatform.sources, ['/tmp/voice.wav']);

    await tester.runAsync(() async {
      audioPlatform.stopGate?.complete();
      await audioPlatform.secondLoadStarted.future.timeout(
        const Duration(seconds: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();

    expect(audioPlatform.sources, ['/tmp/voice.wav', '/tmp/voice.wav']);
    expect(audioPlatform.disposedPlayerIds, hasLength(1));
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
  });

  testWidgets('retry waits for failure cleanup to stop the player', (
    tester,
  ) async {
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: attachment.copyWith(
          localPath: '/tmp/voice.wav',
          fileName: 'voice.wav',
          mimeType: 'audio/wav',
          modality: .audio,
        ),
        onRemove: _ignoreAttachment,
      ),
    );
    audioPlatform
      ..failNextLoad = true
      ..stopGate = Completer<void>();

    await tester.runAsync(() async {
      pressAudioButton(tester);
      await audioPlatform.loadStarted.future.timeout(
        const Duration(seconds: 1),
      );
      await audioPlatform.stopStarted.future.timeout(
        const Duration(seconds: 1),
      );
    });
    await tester.pump();

    await tester.runAsync(() async {
      pressAudioButton(tester);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    expect(audioPlatform.sources, ['/tmp/voice.wav']);

    await tester.runAsync(() async {
      audioPlatform.stopGate?.complete();
      await audioPlatform.secondLoadStarted.future.timeout(
        const Duration(seconds: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();

    expect(audioPlatform.sources, ['/tmp/voice.wav', '/tmp/voice.wav']);
    expect(audioPlatform.disposedPlayerIds, hasLength(1));
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
  });

  testWidgets('disposing the composer stops its active audio preview', (
    tester,
  ) async {
    await pumpAndInit(
      tester,
      buildSubject(
        attachment: attachment.copyWith(
          localPath: '/tmp/voice.wav',
          fileName: 'voice.wav',
          mimeType: 'audio/wav',
          modality: .audio,
        ),
        onRemove: _ignoreAttachment,
      ),
    );
    await tester.runAsync(() async {
      pressAudioButton(tester);
      await audioPlatform.loadStarted.future.timeout(
        const Duration(seconds: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();

    await tester.runAsync(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await audioPlatform.disposeStarted.future.timeout(
        const Duration(seconds: 1),
      );
    });

    expect(audioPlatform.disposeCount, greaterThanOrEqualTo(1));
  });
}

class const _PreviewComposer({
  required final List<MessageAttachmentToCreate> attachments,
  required final ValueChanged<MessageAttachmentToCreate> onRemove,
  required final bool enabled,
}) extends StatefulWidget {
  @override
  State<_PreviewComposer> createState() => _PreviewComposerState();
}

class _PreviewComposerState extends State<_PreviewComposer> {
  final _audioPreviewCoordinator = ChatAttachmentAudioPreviewCoordinator();
  List<MessageAttachmentToCreate> _attachments = [];

  @override
  void initState() {
    super.initState();
    _attachments = [...widget.attachments];
  }

  @override
  void dispose() {
    _audioPreviewCoordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Wrap(
    children: [
      for (final attachment in _attachments)
        ChatAttachmentDraftPreview(
          attachment: attachment,
          onRemove: _remove,
          audioPreviewCoordinator: _audioPreviewCoordinator,
          enabled: widget.enabled,
          key: ObjectKey(attachment),
        ),
    ],
  );

  void _remove(MessageAttachmentToCreate attachment) {
    widget.onRemove(attachment);
    if (!_attachments.contains(attachment)) return;
    setState(() {
      _attachments.removeWhere((candidate) => candidate == attachment);
    });
  }
}

class _FakeJustAudioPlatform extends JustAudioPlatform {
  final sources = <String>[];
  final players = <String, _FakeAudioPlayerPlatform>{};
  final disposedPlayerIds = <String>[];
  Completer<void> loadStarted = Completer<void>();
  Completer<void> secondLoadStarted = Completer<void>();
  Completer<void> stopStarted = Completer<void>();
  Completer<void> disposeStarted = Completer<void>();
  Completer<void>? stopGate;
  int disposeCount = 0;
  bool failNextLoad = false;

  void reset() {
    sources.clear();
    players.clear();
    disposedPlayerIds.clear();
    disposeCount = 0;
    failNextLoad = false;
    loadStarted = Completer<void>();
    secondLoadStarted = Completer<void>();
    stopStarted = Completer<void>();
    disposeStarted = Completer<void>();
    stopGate = null;
  }

  void completePlayback() {
    for (final player in players.values) {
      player.events.add(_playbackEvent(.completed));
    }
  }

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    final player = _FakeAudioPlayerPlatform(
      request.id,
      sources,
      loadStarted,
      secondLoadStarted,
      () {
        if (!failNextLoad) return false;
        failNextLoad = false;

        return true;
      },
    );
    players[request.id] = player;

    return player;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    disposeCount++;
    if (!stopStarted.isCompleted) stopStarted.complete();
    final gate = stopGate;
    if (gate != null) await gate.future;
    disposedPlayerIds.add(request.id);
    if (!disposeStarted.isCompleted) disposeStarted.complete();
    final player = players.remove(request.id);
    await player?.close();

    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async {
    final _ = await Future.wait(players.values.map((player) => player.close()));
    players.clear();

    return DisposeAllPlayersResponse();
  }
}

class _FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  new(
    super.id,
    this.sources,
    this.loadStarted,
    this.secondLoadStarted,
    this.shouldFailNextLoad,
  );

  final List<String> sources;
  final Completer<void> loadStarted;
  final Completer<void> secondLoadStarted;
  final bool Function() shouldFailNextLoad;
  final events = StreamController<PlaybackEventMessage>.broadcast();
  final data = StreamController<PlayerDataMessage>.broadcast();

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => events.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream => data.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    final playlist =
        request.audioSourceMessage as ConcatenatingAudioSourceMessage;
    sources.add(
      Uri.parse((playlist.children.first as UriAudioSourceMessage).uri)
          .toFilePath(),
    );
    if (!loadStarted.isCompleted) loadStarted.complete();
    if (sources.length == 2 && !secondLoadStarted.isCompleted) {
      secondLoadStarted.complete();
    }
    if (shouldFailNextLoad()) {
      throw StateError('private platform error at /tmp/private/voice.wav');
    }
    events.add(_playbackEvent(.ready));

    return LoadResponse(duration: const Duration(seconds: 1));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    data.add(PlayerDataMessage(playing: true));

    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    data.add(PlayerDataMessage(playing: false));

    return PauseResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse();

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async =>
      SetPitchResponse();

  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
    SetSkipSilenceRequest request,
  ) async => SetSkipSilenceResponse();

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
    SetAndroidAudioAttributesRequest request,
  ) async => SetAndroidAudioAttributesResponse();

  Future<void> close() async {
    final _ = await events.close();
    final _ = await data.close();
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

PlaybackEventMessage _playbackEvent(ProcessingStateMessage state) =>
    PlaybackEventMessage(
      processingState: state,
      updateTime: .now(),
      updatePosition: .zero,
      bufferedPosition: const Duration(seconds: 1),
      duration: const Duration(seconds: 1),
      icyMetadata: null,
      currentIndex: 0,
      androidAudioSessionId: null,
    );

void _ignoreAttachment(MessageAttachmentToCreate _) {
  final _ = Object();
}
