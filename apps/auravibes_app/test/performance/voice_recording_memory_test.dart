import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate' as isolates;
import 'dart:math' as math;

import 'package:auravibes_app/features/chats/services/local_chat_attachment_service_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

const _enabled = bool.fromEnvironment('VOICE_MEMORY_PROBE');
const _seconds = int.fromEnvironment('VOICE_MEMORY_SECONDS', defaultValue: 5);
const _irregular = bool.fromEnvironment('VOICE_MEMORY_IRREGULAR');
const int _bytesPerSecond = 44100 * 2;
const _channel = MethodChannel('plugins.flutter.io/path_provider');
const _decoderScript =
    'import json,sys,wave; '
    'w=wave.open(sys.argv[1],"rb"); '
    'print(json.dumps(dict(frames=w.getnframes(),rate=w.getframerate(),'
    'channels=w.getnchannels(),width=w.getsampwidth())))';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'measures the actual macOS voice attachment service',
    _measureRecording,
    timeout: const Timeout(.new(minutes: 4)),
    skip: !_enabled || !Platform.isMacOS,
  );
}

Future<void> _measureRecording() async {
  expect([5, 30, 120], contains(_seconds));
  final output = Platform.environment['VOICE_MEMORY_OUTPUT'];
  if (output == null) throw StateError('VOICE_MEMORY_OUTPUT is required');
  final samples = File('$output.samples.jsonl').openSync(mode: .write);
  addTearDown(samples.closeSync);
  final temporary = await Directory.systemTemp.createTemp('voice_memory_');
  addTearDown(() => temporary.delete(recursive: true));
  final originalPlatform = RecordPlatform.instance;
  final recorder = _MemoryRecordPlatform();
  RecordPlatform.instance = recorder;
  addTearDown(() => RecordPlatform.instance = originalPlatform);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(_channel, (call) async {
          if (call.method == 'getTemporaryDirectory') return temporary.path;

          return null;
        });
  addTearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  final server = await developer.Service.controlWebServer(
    enable: true,
    silenceOutput: true,
  );
  final uri = server.serverUri;
  if (uri == null) throw StateError('The VM service is unavailable');
  final vm = await vmServiceConnectUri(
    uri.replace(scheme: 'ws', path: '${uri.path}ws').toString(),
  );
  addTearDown(vm.dispose);
  final isolateId = developer.Service.getIsolateId(isolates.Isolate.current);
  if (isolateId == null) throw StateError('The worker isolate is unavailable');
  final meter = _MemoryMeter(vm, isolateId, samples);
  addTearDown(meter.stop);

  final audioRecorder = AudioRecorder();
  addTearDown(audioRecorder.dispose);
  final service = LocalChatAttachmentServiceIo(
    recorder: audioRecorder,
    storageNamespace: 'voice_memory_probe',
  );
  await service.startVoiceRecording();
  await recorder.feed(8820, irregular: false);
  final warmup = await service.stopVoiceRecording();
  if (warmup == null) throw StateError('Warmup produced no attachment');
  await service.deleteAttachment(warmup.localPath);
  await meter.mark('idle');
  meter.start();

  const expectedBytes = _seconds * _bytesPerSecond;
  await service.startVoiceRecording();
  await meter.mark('recording-started');
  expect(recorder.config?.sampleRate, 44100);
  expect(recorder.config?.numChannels, 1);
  expect(recorder.config?.encoder, AudioEncoder.pcm16bits);
  await recorder.feed(expectedBytes, irregular: _irregular);
  await meter.mark('pre-stop');
  meter.beginFinalization();
  final stopping = Stopwatch()..start();
  final attachment = await service.stopVoiceRecording();
  stopping.stop();
  await meter.mark('finalized');
  await meter.stop();
  final recordingPeak = ProcessInfo.maxRss;
  if (attachment == null) throw StateError('Recording produced no attachment');

  final file = File(attachment.localPath);
  final size = await file.length();
  expect(size, expectedBytes + 44);
  expect(attachment.sizeBytes, size);
  final header = await file
      .openRead(0, 44)
      .fold<List<int>>(<int>[], (result, part) => result..addAll(part));
  final data = ByteData.sublistView(Uint8List.fromList(header));
  expect(ascii.decode(header.sublist(0, 4)), 'RIFF');
  expect(ascii.decode(header.sublist(8, 12)), 'WAVE');
  expect(ascii.decode(header.sublist(36, 40)), 'data');
  expect(data.getUint32(4, .little), expectedBytes + 36);
  expect(data.getUint16(20, .little), 1);
  expect(data.getUint16(22, .little), 1);
  expect(data.getUint32(24, .little), 44100);
  expect(data.getUint32(28, .little), _bytesPerSecond);
  expect(data.getUint16(32, .little), 2);
  expect(data.getUint16(34, .little), 16);
  expect(data.getUint32(40, .little), expectedBytes);
  var offset = 0;
  await for (final part in file.openRead(44)) {
    for (final byte in part) {
      if (byte != (offset & 255)) {
        throw StateError('PCM differs at byte $offset');
      }
      offset++;
    }
  }
  expect(offset, expectedBytes);
  final digest = await sha256.bind(file.openRead()).first;
  final decoder = await Process.run('python3', [
    '-c',
    _decoderScript,
    file.path,
  ]);
  expect(decoder.exitCode, 0);
  final decoded = jsonDecode(decoder.stdout as String);
  expect(decoded, {
    'frames': _seconds * 44100,
    'rate': 44100,
    'channels': 1,
    'width': 2,
  });
  await service.deleteAttachment(file.path);
  final leftovers = await temporary
      .list(recursive: true)
      .where((entry) => entry is File)
      .length;
  expect(leftovers, 0);
  final result = <String, Object?>{
    'schema': 1,
    'pid': pid,
    'platform': Platform.operatingSystem,
    'dart': Platform.version,
    'seconds': _seconds,
    'irregular': _irregular,
    'sample_rate': recorder.config?.sampleRate,
    'channels': recorder.config?.numChannels,
    'pcm_bytes': expectedBytes,
    'packets': recorder.packets,
    'output_bytes': size,
    'output_sha256': digest.toString(),
    'decoded': decoded,
    'stop_microseconds': stopping.elapsedMicroseconds,
    'process_max_rss_bytes': recordingPeak,
    'sampled_peak_rss_bytes': meter.peakRss,
    'sampled_peak_heap_bytes': meter.peakHeap,
    'sampled_peak_external_bytes': meter.peakExternal,
    'sampled_peak_heap_plus_external_bytes': meter.peakManaged,
    'finalization_peak_rss_bytes': meter.finalizationPeakRss,
    'finalization_peak_heap_plus_external_bytes': meter.finalizationPeakManaged,
    'vm_samples': meter.vmSamples,
    'phases': meter.phases,
    'cleanup_files_remaining': leftovers,
    'source': 'synthetic PCM through unmodified macOS IO service',
  };
  final _ = await File('$output.result.json').writeAsString(jsonEncode(result));
}

class _MemoryMeter(
  final VmService vm,
  final String isolateId,
  final RandomAccessFile output,
) {
  final Stopwatch clock = Stopwatch()..start();
  final Map<String, Object?> phases = {};
  int peakRss = 0;
  int peakHeap = 0;
  int peakExternal = 0;
  int peakManaged = 0;
  int vmSamples = 0;
  int finalizationPeakRss = 0;
  int finalizationPeakManaged = 0;
  Timer? _timer;
  Future<void>? _pending;
  bool _finalizing = false;

  void beginFinalization() {
    _finalizing = true;
    finalizationPeakRss = ProcessInfo.currentRss;
  }

  void start() {
    _timer = .periodic(const .new(milliseconds: 10), (_) {
      final rss = ProcessInfo.currentRss;
      peakRss = math.max(peakRss, rss);
      if (_finalizing) {
        finalizationPeakRss = math.max(finalizationPeakRss, rss);
      }
      if (_pending != null) return;
      _pending = _sample('sample').whenComplete(() => _pending = null);
    });
  }

  Future<void> mark(String phase) async {
    await _pending;
    await _sample(phase);
  }

  Future<void> stop() async {
    _timer?.cancel();
    await _pending;
  }

  Future<void> _sample(String phase) async {
    final memory = await vm.getMemoryUsage(isolateId);
    final rss = ProcessInfo.currentRss;
    final heap = memory.heapUsage ?? 0;
    final external = memory.externalUsage ?? 0;
    peakRss = math.max(peakRss, rss);
    peakHeap = math.max(peakHeap, heap);
    peakExternal = math.max(peakExternal, external);
    peakManaged = math.max(peakManaged, heap + external);
    if (_finalizing) {
      finalizationPeakRss = math.max(finalizationPeakRss, rss);
      finalizationPeakManaged = math.max(
        finalizationPeakManaged,
        heap + external,
      );
    }
    vmSamples++;
    final sample = <String, Object?>{
      'phase': phase,
      'elapsed_us': clock.elapsedMicroseconds,
      'rss_bytes': rss,
      'max_rss_bytes': ProcessInfo.maxRss,
      'heap_bytes': heap,
      'external_bytes': external,
    };
    output.writeStringSync('${jsonEncode(sample)}\n');
    if (phase != 'sample') phases[phase] = sample;
  }
}

class _MemoryRecordPlatform extends RecordPlatform {
  RecordConfig? config;
  int packets = 0;
  void Function(RecordConfig config)? configChanged;
  StreamController<Uint8List>? _controller;
  bool _active = false;

  Future<void> feed(int bytes, {required bool irregular}) async {
    const sizes = [257, 1801, 4096, 913];
    final controller = _controller;
    if (controller == null) throw StateError('No active recording stream');
    final clock = Stopwatch()..start();
    var emitted = 0;
    packets = 0;
    while (emitted < bytes) {
      final size = math.min(
        irregular ? sizes[packets % sizes.length] : 1764,
        bytes - emitted,
      );
      final packet = Uint8List(size);
      for (var index = 0; index < size; index++) {
        packet[index] = (emitted + index) & 255;
      }
      controller.add(packet);
      emitted += size;
      packets++;
      final due = emitted * Duration.microsecondsPerSecond ~/ _bytesPerSecond;
      final remaining = due - clock.elapsedMicroseconds;
      if (remaining > 0) {
        await Future<void>.delayed(.new(microseconds: remaining));
      }
    }
  }

  @override
  Future<void> create(String recorderId) => .value();

  @override
  Future<void> start(
    String recorderId,
    RecordConfig config, {
    required String path,
  }) => throw UnsupportedError('The probe measures streaming capture only.');

  @override
  Future<Stream<Uint8List>> startStream(
    String recorderId,
    RecordConfig config,
  ) async {
    this.config = config;
    _active = true;
    final controller = StreamController<Uint8List>();
    _controller = controller;

    return controller.stream;
  }

  @override
  Future<String?> stop(String recorderId) async {
    final _ = await _controller?.close();
    _active = false;

    return null;
  }

  @override
  Future<void> pause(String recorderId) => .value();

  @override
  Future<void> resume(String recorderId) => .value();

  @override
  Future<void> cancel(String recorderId) => .value();

  @override
  Future<bool> isPaused(String recorderId) async => false;

  @override
  Future<Amplitude> getAmplitude(String recorderId) async =>
      .new(current: 0, max: 0);

  @override
  Future<bool> isEncoderSupported(
    String recorderId,
    AudioEncoder encoder,
  ) async => true;

  @override
  Future<bool> isRecording(String recorderId) async => _active;

  @override
  Future<bool> hasPermission(String recorderId, {bool request = true}) async =>
      true;

  @override
  Future<List<InputDevice>> listInputDevices(String recorderId) async => const [
    InputDevice(id: 'fixture', label: 'Fixture', type: .builtIn),
  ];

  @override
  Stream<RecordState> onStateChanged(String recorderId) => const Stream.empty();

  @override
  void setOnConfigChanged(
    String recorderId,
    void Function(RecordConfig config)? handler,
  ) {
    configChanged = handler;
  }

  @override
  Future<void> dispose(String recorderId) => .value();
}
