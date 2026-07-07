import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/services/attachment_modality.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:riverpod/riverpod.dart';
import 'package:uuid/v7.dart';

final _logger = Logger('local_chat_attachment_service');
const _macRecordingSampleRate = 44100;
const _macRecordingChannels = 1;

class LocalChatAttachmentService {
  LocalChatAttachmentService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String? _recordingPath;
  BytesBuilder? _recordingBytes;
  Completer<void>? _recordingStreamDone;
  StreamSubscription<Uint8List>? _recordingStreamSubscription;

  Future<MessageAttachmentToCreate> copyIntoAppStorage(
    String sourcePath, {
    String? displayName,
  }) async {
    final source = File(sourcePath);
    final fileSize = await source.length();
    if (fileSize > maxChatAttachmentBytes) {
      throw StateError('Attachment is too large.');
    }
    final fileName = p.basename(sourcePath);
    final headerBytes = await source
        .openRead(0, 12)
        .expand((bytes) => bytes)
        .toList();
    final mimeType =
        lookupMimeType(sourcePath, headerBytes: headerBytes) ??
        'application/octet-stream';
    final directory = await getTemporaryDirectory();

    final attachmentDirectory = Directory(
      p.join(directory.path, 'chat_attachments_draft'),
    );
    final _ = await attachmentDirectory.create(recursive: true);

    final localPath = p.join(
      attachmentDirectory.path,
      '${const UuidV7().generate()}-$fileName',
    );
    final _ = await source.copy(localPath);

    return MessageAttachmentToCreate(
      localPath: localPath,
      fileName: fileName,
      displayName: displayName ?? fileName,
      mimeType: mimeType,
      modality: attachmentModalityForMimeType(mimeType),
      sizeBytes: fileSize,
    );
  }

  Future<void> startVoiceRecording() async {
    if (await _recorder.isRecording()) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _logger.warning('Microphone permission was denied');
      throw StateError('Microphone permission was denied.');
    }

    final devices = await _recorder.listInputDevices();

    InputDevice? device;
    if (Platform.isMacOS) {
      for (final inputDevice in devices) {
        if (inputDevice.type == InputDeviceType.builtIn) {
          device = inputDevice;
          break;
        }
      }
    }
    _logger.fine('Voice recording input devices: $devices');

    final directory = await getTemporaryDirectory();
    final path = p.join(directory.path, '${const UuidV7().generate()}.wav');
    _recordingPath = path;
    if (Platform.isMacOS) {
      await _startMacVoiceRecording(path, device);

      return;
    }

    await _recorder.start(
      RecordConfig(encoder: AudioEncoder.wav, device: device),
      path: path,
    );
    _logger.fine('Started voice recording at $path');
  }

  Future<MessageAttachmentToCreate?> stopVoiceRecording() async {
    final path = _recordingStreamSubscription == null
        ? await _recorder.stop() ?? _recordingPath
        : await _stopMacVoiceRecording();
    _recordingPath = null;
    if (path == null) {
      _logger.warning('Voice recording stop returned no path');

      return null;
    }

    final file = File(path);
    if (!await waitForRecordedFile(file)) {
      _logger.warning('Voice recording file was not ready: $path');

      return null;
    }

    try {
      final attachment = await copyIntoAppStorage(path);
      _logger.fine('Created voice attachment ${attachment.localPath}');

      return attachment;
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  }

  Future<void> cancelVoiceRecording() async {
    final path = _recordingStreamSubscription == null
        ? await _recorder.stop() ?? _recordingPath
        : await _cancelMacVoiceRecording();
    _recordingPath = null;
    if (path == null) return;

    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  Future<void> deleteAttachment(String localPath) async {
    final tempDirectory = await getTemporaryDirectory();
    final draftDirectory = p.join(
      tempDirectory.path,
      'chat_attachments_draft',
    );
    if (!p.isWithin(draftDirectory, p.normalize(localPath))) return;

    final file = File(localPath);
    if (file.existsSync()) {
      final _ = await file.delete();
    }
  }

  Future<void> _startMacVoiceRecording(String path, InputDevice? device) async {
    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        numChannels: _macRecordingChannels,
        device: device,
      ),
    );
    final bytes = BytesBuilder(copy: false);
    final done = Completer<void>();
    _recordingBytes = bytes;
    _recordingStreamDone = done;
    _recordingStreamSubscription = stream.listen(
      bytes.add,
      onError: done.completeError,
      onDone: done.complete,
      cancelOnError: true,
    );
    _logger.fine('Started voice stream recording at $path');
  }

  Future<String?> _stopMacVoiceRecording() async {
    final path = _recordingPath;
    final pcmBytes = await _stopMacVoiceStream();
    if (path == null || pcmBytes == null || pcmBytes.isEmpty) {
      _logger.warning('Voice stream stopped without audio bytes');

      return null;
    }
    _logger.fine('Voice stream captured ${pcmBytes.length} PCM bytes');

    final file = File(path);
    final _ = await file.parent.create(recursive: true);
    final _ = await file.writeAsBytes(
      pcm16ToWav(
        pcmBytes,
        sampleRate: _macRecordingSampleRate,
        channels: _macRecordingChannels,
      ),
    );

    return path;
  }

  Future<String?> _cancelMacVoiceRecording() async {
    final _ = await _stopMacVoiceStream();

    return null;
  }

  Future<Uint8List?> _stopMacVoiceStream() async {
    final _ = await _recorder.stop();
    await _recordingStreamDone?.future.timeout(
      const Duration(milliseconds: 500),
      onTimeout: () => _logger.warning('Voice stream stop timed out'),
    );
    await _recordingStreamSubscription?.cancel();
    _recordingStreamSubscription = null;
    _recordingStreamDone = null;

    final pcmBytes = _recordingBytes?.takeBytes();
    _recordingBytes = null;

    return pcmBytes;
  }
}

// ignore: unused-code, conditional export implementation used on IO platforms.
final localChatAttachmentServiceProvider = Provider<LocalChatAttachmentService>(
  (_) => LocalChatAttachmentService(),
);

@visibleForTesting
Future<bool> waitForRecordedFile(
  File file, {
  Duration timeout = const Duration(seconds: 1),
  Duration pollInterval = const Duration(milliseconds: 50),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (file.existsSync() && file.lengthSync() > 0) return true;
    await Future<void>.delayed(pollInterval);
  }

  return file.existsSync() && file.lengthSync() > 0;
}

@visibleForTesting
Uint8List pcm16ToWav(
  Uint8List pcmBytes, {
  required int sampleRate,
  required int channels,
}) {
  const bitsPerSample = 16;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final byteRate = sampleRate * blockAlign;
  final dataLength = pcmBytes.length;
  final bytes = Uint8List(dataLength + 44);
  final data = ByteData.sublistView(bytes);

  bytes
    ..setAll(0, 'RIFF'.codeUnits)
    ..setAll(8, 'WAVE'.codeUnits)
    ..setAll(12, 'fmt '.codeUnits)
    ..setAll(36, 'data'.codeUnits)
    ..setAll(44, pcmBytes);
  data
    ..setUint32(4, dataLength + 36, Endian.little)
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, channels, Endian.little)
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, byteRate, Endian.little)
    ..setUint16(32, blockAlign, Endian.little)
    ..setUint16(34, bitsPerSample, Endian.little)
    ..setUint32(40, dataLength, Endian.little);

  return bytes;
}
