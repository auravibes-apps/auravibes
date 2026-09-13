import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/providers/app_providers.dart';
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
const _wavFormatChunkOffset = 16;

class LocalChatAttachmentServiceIo({
  AudioRecorder? recorder,
  final String storageNamespace = 'auravibes_app',
}) {
  final AudioRecorder _recorder = recorder ?? AudioRecorder();
  String? _recordingPath;
  BytesBuilder? _recordingBytes;
  Completer<void>? _recordingStreamDone;
  StreamSubscription<Uint8List>? _recordingStreamSubscription;

  Future<MessageAttachmentToCreate> copyIntoAppStorage(
    String sourcePath, {
    String? displayName,
  }) => _copyIntoAppStorage(this, sourcePath, displayName);

  Future<void> startVoiceRecording() => _startVoiceRecording(this);

  Future<MessageAttachmentToCreate?> stopVoiceRecording() =>
      _stopVoiceRecording(this);

  Future<void> cancelVoiceRecording() => _cancelVoiceRecording(this);

  Future<void> deleteAttachment(String localPath) async {
    final draftDirectory = (await _draftDirectory()).path;
    if (!p.isWithin(draftDirectory, p.normalize(localPath))) return;

    final file = File(localPath);
    if (file.existsSync()) {
      final _ = await file.delete();
    }
  }
}

typedef _AttachmentSource = ({
  File file,
  String fileName,
  int sizeBytes,
  String mimeType,
});

Future<MessageAttachmentToCreate> _copyIntoAppStorage(
  LocalChatAttachmentServiceIo service,
  String sourcePath,
  String? displayName,
) async {
  final source = await _readAttachmentSource(sourcePath);
  _ensureAttachmentSize(source.sizeBytes);
  final localPath = await _newAttachmentPath(service, source.fileName);
  final copied = await source.file.copy(localPath);

  return _newAttachment(copied, source, displayName);
}

void _ensureAttachmentSize(int sizeBytes) {
  if (sizeBytes > ChatAttachmentModality.maxChatAttachmentBytes) {
    throw const ChatAttachmentTooLargeException();
  }
}

Future<String> _newAttachmentPath(
  LocalChatAttachmentServiceIo service,
  String fileName,
) async {
  final attachmentDirectory = await service._draftDirectory();
  final createdDirectory = await attachmentDirectory.create(recursive: true);

  return p.join(
    createdDirectory.path,
    '${const UuidV7().generate()}-$fileName',
  );
}

MessageAttachmentToCreate _newAttachment(
  File copied,
  _AttachmentSource source,
  String? displayName,
) => MessageAttachmentToCreate(
  localPath: copied.path,
  fileName: source.fileName,
  displayName: displayName ?? source.fileName,
  mimeType: source.mimeType,
  modality: ChatAttachmentModality.forMimeType(source.mimeType),
  sizeBytes: source.sizeBytes,
);

Future<_AttachmentSource> _readAttachmentSource(String sourcePath) async {
  final file = File(sourcePath);
  final sizeBytes = await file.length();
  final headerBytes = await file
      .openRead(0, 12)
      .expand((bytes) => bytes)
      .toList();

  return (
    file: file,
    fileName: p.basename(sourcePath),
    sizeBytes: sizeBytes,
    mimeType:
        lookupMimeType(sourcePath, headerBytes: headerBytes) ??
        'application/octet-stream',
  );
}

Future<void> _startVoiceRecording(LocalChatAttachmentServiceIo service) async {
  if (await service._recorder.isRecording()) return;

  await _ensureRecordingPermission(service._recorder);
  final device = await _recordingInputDevice(service._recorder);
  final path = await _newRecordingPath(service);
  service._recordingPath = path;
  if (Platform.isMacOS) {
    await service._startMacVoiceRecording(device);

    return;
  }

  await _startStandardVoiceRecording(service._recorder, device, path);
}

Future<InputDevice?> _recordingInputDevice(AudioRecorder recorder) async {
  final devices = await recorder.listInputDevices();
  _logger.fine('Voice recording input devices detected: ${devices.length}');

  return _preferredInputDevice(devices);
}

Future<void> _startStandardVoiceRecording(
  AudioRecorder recorder,
  InputDevice? device,
  String path,
) async {
  await recorder.start(
    .new(encoder: AudioEncoder.wav, device: device),
    path: path,
  );
  _logger.fine('Started voice recording');
}

Future<void> _ensureRecordingPermission(AudioRecorder recorder) async {
  if (await recorder.hasPermission()) return;

  _logger.warning('Microphone permission was denied');
  throw StateError('Microphone permission was denied.');
}

InputDevice? _preferredInputDevice(List<InputDevice> devices) {
  if (!Platform.isMacOS) return null;

  for (final device in devices) {
    if (device.type == InputDeviceType.builtIn) return device;
  }

  return null;
}

Future<String> _newRecordingPath(LocalChatAttachmentServiceIo service) async {
  final directory = await service._temporaryRoot();
  final createdDirectory = await directory.create(recursive: true);

  return p.join(createdDirectory.path, '${const UuidV7().generate()}.wav');
}

Future<MessageAttachmentToCreate?> _stopVoiceRecording(
  LocalChatAttachmentServiceIo service,
) async {
  final path = service._recordingStreamSubscription == null
      ? await service._recorder.stop() ?? service._recordingPath
      : await service._stopMacVoiceRecording();
  service._recordingPath = null;
  if (path == null) {
    _logger.warning('Voice recording stop returned no path');

    return null;
  }

  return await _createStoppedVoiceAttachment(service, path);
}

Future<MessageAttachmentToCreate?> _createStoppedVoiceAttachment(
  LocalChatAttachmentServiceIo service,
  String path,
) async {
  final file = File(path);
  if (!await LocalChatAttachmentRecording.waitForRecordedFile(file)) {
    _logger.warning('Voice recording file was not ready');

    return null;
  }

  try {
    final attachment = await service.copyIntoAppStorage(path);
    _logger.fine('Created voice attachment');

    return attachment;
  } finally {
    if (file.existsSync()) file.deleteSync();
  }
}

Future<void> _cancelVoiceRecording(LocalChatAttachmentServiceIo service) async {
  final path = service._recordingStreamSubscription == null
      ? await service._recorder.stop() ?? service._recordingPath
      : await service._cancelMacVoiceRecording();
  service._recordingPath = null;
  if (path == null) return;

  final file = File(path);
  if (file.existsSync()) file.deleteSync();
}

extension on LocalChatAttachmentServiceIo {
  Future<Directory> _temporaryRoot() async {
    final directory = await getTemporaryDirectory();
    if (storageNamespace == 'auravibes_app') return directory;

    return Directory(p.join(directory.path, storageNamespace));
  }

  Future<Directory> _draftDirectory() async {
    final root = await _temporaryRoot();

    return Directory(p.join(root.path, 'chat_attachments_draft'));
  }

  Future<void> _startMacVoiceRecording(InputDevice? device) async {
    final stream = await _recorder.startStream(
      .new(
        encoder: AudioEncoder.pcm16bits,
        numChannels: _macRecordingChannels,
        device: device,
      ),
    );
    _attachRecordingStream(stream);
    _logger.fine('Started voice stream recording');
  }

  void _attachRecordingStream(Stream<Uint8List> stream) {
    final bytes = BytesBuilder(copy: false);
    final done = Completer<void>();
    _recordingBytes = bytes;
    _recordingStreamDone = done;
    _recordingStreamSubscription = _listenToRecordingStream(
      stream,
      bytes,
      done,
    );
  }

  StreamSubscription<Uint8List> _listenToRecordingStream(
    Stream<Uint8List> stream,
    BytesBuilder bytes,
    Completer<void> done,
  ) => stream.listen(
    bytes.add,
    onError: done.completeError,
    onDone: done.complete,
    cancelOnError: true,
  );

  Future<String?> _stopMacVoiceRecording() async {
    final path = _recordingPath;
    final pcmBytes = await _stopMacVoiceStream();
    if (path == null || pcmBytes == null || pcmBytes.isEmpty) {
      _logger.warning('Voice stream stopped without audio bytes');

      return null;
    }

    _logger.fine('Voice stream captured ${pcmBytes.length} PCM bytes');
    await _writeMacRecording(path, pcmBytes);

    return path;
  }

  Future<void> _writeMacRecording(String path, Uint8List pcmBytes) async {
    final file = File(path);
    final _ = await file.parent.create(recursive: true);
    final _ = await file.writeAsBytes(
      LocalChatAttachmentRecording.pcm16ToWav(
        pcmBytes,
        sampleRate: _macRecordingSampleRate,
        channels: _macRecordingChannels,
      ),
    );
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
typedef LocalChatAttachmentService = LocalChatAttachmentServiceIo;

// ignore: unused-code, conditional export implementation used on IO platforms.
final localChatAttachmentServiceProvider = Provider<LocalChatAttachmentService>(
  (ref) => LocalChatAttachmentServiceIo(
    storageNamespace: ref.watch(appStorageNamespaceProvider),
  ),
);

abstract final class LocalChatAttachmentRecording {
  @visibleForTesting
  static Future<bool> waitForRecordedFile(
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
  static Uint8List pcm16ToWav(
    Uint8List pcmBytes, {
    required int sampleRate,
    required int channels,
  }) {
    final format = (sampleRate: sampleRate, channels: channels);
    final bytes = _wavBytes(pcmBytes);
    _writeWavHeader(_wavHeaderRequest(bytes, pcmBytes.length, format));

    return bytes;
  }
}

typedef _WavFormat = ({int sampleRate, int channels});

const _wavDataChunkOffset = 36;
const _wavFormatChunkSize = 16;
const _pcmFormat = 1;
const _waveFormatOffset = 8;
const _waveFormatChunkOffset = 12;

Uint8List _wavBytes(Uint8List pcmBytes) {
  const wavHeaderSize = 44;

  return Uint8List(pcmBytes.length + wavHeaderSize)
    ..setAll(0, 'RIFF'.codeUnits)
    ..setAll(_waveFormatOffset, 'WAVE'.codeUnits)
    ..setAll(_waveFormatChunkOffset, 'fmt '.codeUnits)
    ..setAll(_wavDataChunkOffset, 'data'.codeUnits)
    ..setAll(wavHeaderSize, pcmBytes);
}

_WavHeaderRequest _wavHeaderRequest(
  Uint8List bytes,
  int dataLength,
  _WavFormat format,
) => _WavHeaderData(bytes, dataLength, format).value;

typedef _WavHeaderRequest = ({
  ByteData data,
  int dataLength,
  int blockAlign,
  int byteRate,
  int channels,
  int sampleRate,
  int dataChunkOffset,
  int fmtChunkSize,
  int pcmFormat,
  int bitsPerSample,
});

class _WavHeaderData {
  new(Uint8List bytes, int dataLength, _WavFormat format)
    : value = (
        data: ByteData.sublistView(bytes),
        dataLength: dataLength,
        blockAlign: format.channels * _bitsPerSample ~/ _bytesPerSample,
        byteRate:
            format.sampleRate *
            format.channels *
            _bitsPerSample ~/
            _bytesPerSample,
        channels: format.channels,
        sampleRate: format.sampleRate,
        dataChunkOffset: _wavDataChunkOffset,
        fmtChunkSize: _wavFormatChunkSize,
        pcmFormat: _pcmFormat,
        bitsPerSample: _bitsPerSample,
      );

  final _WavHeaderRequest value;
}

const _bitsPerSample = 16;
const _bytesPerSample = 8;

void _writeWavHeader(_WavHeaderRequest request) {
  _writeRiffHeader(request);
  _writeFormatHeader(request);
  _writeDataHeader(request);
}

void _writeRiffHeader(_WavHeaderRequest request) => request.data.setUint32(
  4,
  request.dataLength + request.dataChunkOffset,
  .little,
);

void _writeFormatHeader(_WavHeaderRequest request) {
  request.data
    ..setUint32(_wavFormatChunkOffset, request.fmtChunkSize, .little)
    ..setUint16(20, request.pcmFormat, .little)
    ..setUint16(22, request.channels, .little)
    ..setUint32(24, request.sampleRate, .little)
    ..setUint32(28, request.byteRate, .little)
    ..setUint16(32, request.blockAlign, .little)
    ..setUint16(34, request.bitsPerSample, .little);
}

void _writeDataHeader(_WavHeaderRequest request) =>
    request.data.setUint32(40, request.dataLength, .little);
