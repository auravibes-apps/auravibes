import 'dart:async';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/widgets/chat_attachment_draft_preview.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final previousAudioPlatform = AudioplayersPlatformInterface.instance;
  final previousGlobalAudioPlatform =
      GlobalAudioplayersPlatformInterface.instance;
  final audioPlatform = _FakeAudioPlayersPlatform();
  final globalAudioPlatform = _FakeGlobalAudioplayersPlatform();

  setUpAll(() {
    AudioplayersPlatformInterface.instance = audioPlatform;
    GlobalAudioplayersPlatformInterface.instance = globalAudioPlatform;
  });
  tearDownAll(() {
    AudioplayersPlatformInterface.instance = previousAudioPlatform;
    GlobalAudioplayersPlatformInterface.instance = previousGlobalAudioPlatform;
    unawaited(globalAudioPlatform.events.close());
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
    bool enabled = true,
    Locale locale = const Locale('en'),
  }) {
    return EasyLocalization(
      child: Builder(
        builder: (context) => AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: Material(
              child: ChatAttachmentDraftPreview(
                attachment: attachment,
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
    await tester.pump();
  }

  void pressAudioButton(WidgetTester tester) {
    tester
        .widget<AuraIconButton>(find.byType(AuraIconButton))
        .onPressed
        ?.call();
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

    pressAudioButton(tester);
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    expect(audioPlatform.sources, ['/tmp/voice.wav']);

    pressAudioButton(tester);
    await tester.pump();
    await tester.pump();

    expect(audioPlatform.stopCount, 1);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('stops playback when a voice attachment is removed', (
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
    pressAudioButton(tester);
    await tester.pump();
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(audioPlatform.stopCount, 2);
  });
}

class _FakeAudioPlayersPlatform extends AudioplayersPlatformInterface {
  final sources = <String>[];
  int stopCount = 0;
  final Map<String, StreamController<AudioEvent>> _eventStreams = {};

  @override
  Future<void> create(String playerId) async {
    _eventStreams[playerId] = StreamController<AudioEvent>.broadcast();
  }

  @override
  Future<void> dispose(String playerId) async {
    final eventStream = _eventStreams.remove(playerId);
    if (eventStream != null) {
      final _ = await eventStream.close();
    }
  }

  @override
  Stream<AudioEvent> getEventStream(String playerId) =>
      _eventStreams[playerId]!.stream;

  @override
  Future<int?> getCurrentPosition(String playerId) async => 0;

  @override
  Future<void> release(String playerId) => Future.value();

  @override
  Future<void> resume(String playerId) => Future.value();

  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) async {
    sources.add(url);
    _eventStreams[playerId]!.add(
      const AudioEvent(eventType: .prepared, isPrepared: true),
    );
  }

  @override
  Future<void> stop(String playerId) async {
    stopCount++;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeGlobalAudioplayersPlatform
    extends GlobalAudioplayersPlatformInterface {
  final events = StreamController<GlobalAudioEvent>.broadcast();

  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => events.stream;

  @override
  Future<void> init() => Future.value();

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void _ignoreAttachment(MessageAttachmentToCreate _) {
  final _ = Object();
}
