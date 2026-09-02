import 'dart:async';
import 'dart:io';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service_io.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  var tempDirectory = Directory.systemTemp;
  var originalRecordPlatform = RecordPlatform.instance;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('attachment_test_');
    originalRecordPlatform = RecordPlatform.instance;
    RecordPlatform.instance = _FakeRecordPlatform();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (methodCall) async {
            if (methodCall.method == 'getTemporaryDirectory') {
              return tempDirectory.path;
            }

            return null;
          },
        );
  });

  tearDown(() async {
    RecordPlatform.instance = originalRecordPlatform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (tempDirectory.existsSync()) {
      final _ = await tempDirectory.delete(recursive: true);
    }
  });

  test('copyIntoAppStorage copies file into draft storage', () async {
    final source = File('${tempDirectory.path}/image.png');
    final _ = await source.writeAsBytes([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);
    final service = LocalChatAttachmentService();

    final attachment = await service.copyIntoAppStorage(
      source.path,
      displayName: 'Screenshot',
    );

    expect(attachment.displayName, 'Screenshot');
    expect(attachment.fileName, 'image.png');
    expect(attachment.mimeType, 'image/png');
    expect(attachment.modality, MessageAttachmentModality.image);
    expect(File(attachment.localPath).existsSync(), isTrue);
    expect(attachment.localPath, contains('chat_attachments_draft'));
  });

  test('copies drafts into namespaced temporary storage', () async {
    const namespace = 'auravibes_app_0123456789abcdef';
    final source = await File('${tempDirectory.path}/image.png')
        .writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

    final attachment = await LocalChatAttachmentService(
      storageNamespace: namespace,
    ).copyIntoAppStorage(source.path);

    expect(attachment.localPath, contains('$namespace/chat_attachments_draft'));
  });

  test('does not delete legacy draft from namespaced storage', () async {
    final draftDirectory = await Directory(
      '${tempDirectory.path}/chat_attachments_draft',
    ).create(recursive: true);
    final legacyFile = await File('${draftDirectory.path}/legacy.png')
        .writeAsBytes([1]);

    await LocalChatAttachmentService(
      storageNamespace: 'auravibes_app_0123456789abcdef',
    ).deleteAttachment(legacyFile.path);

    expect(legacyFile.existsSync(), isTrue);
  });

  test('deleteAttachment removes only draft attachment files', () async {
    final service = LocalChatAttachmentService();
    final draftDirectory = Directory(
      '${tempDirectory.path}/chat_attachments_draft',
    );
    final _ = await draftDirectory.create(recursive: true);
    final draftFile = File('${draftDirectory.path}/draft.txt');
    final outsideFile = File('${tempDirectory.path}/outside.txt');
    final _ = await draftFile.writeAsString('draft');
    final _ = await outsideFile.writeAsString('outside');

    await service.deleteAttachment(draftFile.path);
    await service.deleteAttachment(outsideFile.path);

    expect(draftFile.existsSync(), isFalse);
    expect(outsideFile.existsSync(), isTrue);
  });

  test('provider records into namespaced temporary storage', () async {
    const namespace = 'auravibes_app_0123456789abcdef';
    final platform = _FakeRecordPlatform();
    RecordPlatform.instance = platform;
    final container = ProviderContainer(
      overrides: [appStorageNamespaceProvider.overrideWithValue(namespace)],
    );
    addTearDown(container.dispose);

    await container
        .read(localChatAttachmentServiceProvider)
        .startVoiceRecording();

    if (!Platform.isMacOS) {
      expect(
        platform.startPath,
        startsWith('${tempDirectory.path}/$namespace/'),
      );
    }
  });

  test('startVoiceRecording returns when recorder is already active', () async {
    final platform = _FakeRecordPlatform(isRecordingValue: true);
    RecordPlatform.instance = platform;
    final service = LocalChatAttachmentService();

    await service.startVoiceRecording();

    expect(platform.startPath, isNull);
    expect(platform.startStreamCalled, isFalse);
  });

  test(
    'startVoiceRecording fails when microphone permission is denied',
    () async {
      RecordPlatform.instance = _FakeRecordPlatform(hasPermissionValue: false);
      final service = LocalChatAttachmentService();

      await expectLater(service.startVoiceRecording(), throwsStateError);
    },
  );

  test('stopVoiceRecording returns attachment for recorded audio', () async {
    final platform = _FakeRecordPlatform();
    RecordPlatform.instance = platform;
    final service = LocalChatAttachmentService();

    await service.startVoiceRecording();

    if (Platform.isMacOS) {
      platform.addStreamBytes([1, 2, 3, 4]);
    } else {
      final outputPath = platform.outputPath;
      if (outputPath == null) fail('Expected recording path.');

      final _ = await File(outputPath).writeAsBytes([1, 2, 3, 4]);
    }

    final attachment = await service.stopVoiceRecording();

    expect(platform.startStreamCalled, Platform.isMacOS);
    if (attachment == null) fail('Expected voice attachment.');
    expect(attachment.displayName, endsWith('.wav'));
    expect(File(attachment.localPath).existsSync(), isTrue);
  });

  test('cancelVoiceRecording stops and cleans recording', () async {
    final platform = _FakeRecordPlatform();
    RecordPlatform.instance = platform;
    final service = LocalChatAttachmentService();

    await service.startVoiceRecording();

    final outputPath = platform.outputPath;
    if (!Platform.isMacOS && outputPath != null) {
      final _ = await File(outputPath).writeAsBytes([1, 2, 3, 4]);
    }

    await service.cancelVoiceRecording();

    expect(platform.startStreamCalled, Platform.isMacOS);
    expect(platform.stopCalled, isTrue);
    if (!Platform.isMacOS && outputPath != null) {
      expect(File(outputPath).existsSync(), isFalse);
    }
  });

  test('waitForRecordedFile waits until recorder flushes file', () async {
    final dir = await Directory.systemTemp.createTemp('recording_test_');
    addTearDown(() async {
      final _ = await dir.delete(recursive: true);
    });

    final file = File('${dir.path}/voice.wav');
    final wait = LocalChatAttachmentRecording.waitForRecordedFile(
      file,
      timeout: const Duration(milliseconds: 200),
      pollInterval: const Duration(milliseconds: 10),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final _ = await file.writeAsBytes([1, 2, 3]);

    expect(await wait, isTrue);
  });

  test('pcm16ToWav writes a playable wav header', () {
    final wav = LocalChatAttachmentRecording.pcm16ToWav(
      Uint8List.fromList([1, 2, 3, 4]),
      sampleRate: 44100,
      channels: 1,
    );

    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
    expect(wav.length, 48);
  });
}

class _FakeRecordPlatform({
  final bool isRecordingValue = false,
  final bool hasPermissionValue = true,
}) extends RecordPlatform {
  String? startPath;
  bool startStreamCalled = false;
  bool stopCalled = false;
  StreamController<Uint8List>? _streamController;
  void Function(RecordConfig config)? configChangedHandler;

  String? get outputPath => startPath;

  @override
  Future<void> create(String recorderId) => Future.value();

  @override
  Future<void> start(
    String recorderId,
    RecordConfig config, {
    required String path,
  }) async {
    startPath = path;
  }

  @override
  Future<Stream<Uint8List>> startStream(
    String recorderId,
    RecordConfig config,
  ) async {
    startStreamCalled = true;

    final streamController = StreamController<Uint8List>();
    _streamController = streamController;

    return streamController.stream;
  }

  void addStreamBytes(List<int> bytes) {
    _streamController?.add(Uint8List.fromList(bytes));
  }

  @override
  Future<String?> stop(String recorderId) async {
    stopCalled = true;
    final _ = await _streamController?.close();

    return startPath;
  }

  @override
  Future<void> pause(String recorderId) => Future.value();

  @override
  Future<void> resume(String recorderId) => Future.value();

  @override
  Future<bool> isRecording(String recorderId) async => isRecordingValue;

  @override
  Future<bool> isPaused(String recorderId) async => false;

  @override
  Future<bool> hasPermission(String recorderId, {bool request = true}) async =>
      hasPermissionValue;

  @override
  Future<void> dispose(String recorderId) => Future.value();

  @override
  Future<Amplitude> getAmplitude(String recorderId) async {
    return Amplitude(current: 0, max: 0);
  }

  @override
  Future<bool> isEncoderSupported(
    String recorderId,
    AudioEncoder encoder,
  ) async => true;

  @override
  Future<List<InputDevice>> listInputDevices(String recorderId) async {
    return const [
      InputDevice(
        id: 'built-in',
        label: 'Built In',
        type: InputDeviceType.builtIn,
      ),
    ];
  }

  @override
  Future<void> cancel(String recorderId) => Future.value();

  @override
  Stream<RecordState> onStateChanged(String recorderId) {
    return const Stream.empty();
  }

  @override
  void setOnConfigChanged(
    String recorderId,
    void Function(RecordConfig config)? handler,
  ) {
    configChangedHandler = handler;
  }
}
