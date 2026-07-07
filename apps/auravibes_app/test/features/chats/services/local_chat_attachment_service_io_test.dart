import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/features/chats/services/local_chat_attachment_service_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('waitForRecordedFile waits until recorder flushes file', () async {
    final dir = await Directory.systemTemp.createTemp('recording_test_');
    addTearDown(() => dir.delete(recursive: true));

    final file = File('${dir.path}/voice.wav');
    final wait = waitForRecordedFile(
      file,
      timeout: const Duration(milliseconds: 200),
      pollInterval: const Duration(milliseconds: 10),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final _ = await file.writeAsBytes([1, 2, 3]);

    expect(await wait, isTrue);
  });

  test('pcm16ToWav writes a playable wav header', () {
    final wav = pcm16ToWav(
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
