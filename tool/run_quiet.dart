import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _tailBytes = 64 * 1024;

Future<void> main(List<String> args) async {
  final streaming = args.firstOrNull == '--stream';
  if (streaming) args = args.skip(1).toList();
  if (args.length < 2 || args.firstOrNull != '--') {
    stderr.writeln(
      'Usage: dart run tool/run_quiet.dart [--stream] -- '
      '<executable> [arguments...]\n'
      'Quiet failures retain the last $_tailBytes bytes of each output stream.',
    );
    exitCode = 2;

    return;
  }

  try {
    final process = await Process.start(args[1], args.skip(2).toList());
    final signals = [
      ProcessSignal.sigint,
      if (!Platform.isWindows) ProcessSignal.sigterm,
    ].map((signal) => signal.watch().listen(process.kill)).toList();

    try {
      await process.stdin.close();
      final stdoutTail = _OutputTail();
      final stderrTail = _OutputTail();
      await Future.wait([
        if (streaming) ...[
          stdout.addStream(process.stdout),
          stderr.addStream(process.stderr),
        ] else ...[
          process.stdout.forEach(stdoutTail.add),
          process.stderr.forEach(stderrTail.add),
        ],
      ]);
      final code = await process.exitCode;
      // POSIX reports signal deaths as negative codes; shells use 128 + signal.
      exitCode = code < 0 && !Platform.isWindows ? 128 - code : code;
      if (streaming) return;

      if (code == 0) {
        stdout.writeln('Command succeeded.');
      } else {
        stdoutTail.writeTo(stdout);
        stderrTail.writeTo(stderr);
      }
    } finally {
      for (final signal in signals) {
        await signal.cancel();
      }
    }
  } on ProcessException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}

// Keep bytes rather than lines so newline-free output stays bounded too.
class _OutputTail {
  final _bytes = Uint8List(_tailBytes);
  var _length = 0;
  var _next = 0;

  void add(List<int> bytes) {
    var start = max(0, bytes.length - _tailBytes);
    while (start < bytes.length) {
      final count = min(bytes.length - start, _tailBytes - _next);
      _bytes.setRange(_next, _next + count, bytes, start);
      _next = (_next + count) % _tailBytes;
      start += count;
    }
    _length = min(_tailBytes, _length + bytes.length);
  }

  void writeTo(IOSink sink) {
    if (_length == 0) return;

    final start = (_next - _length + _tailBytes) % _tailBytes;
    final count = min(_length, _tailBytes - start);
    sink.add(Uint8List.sublistView(_bytes, start, start + count));
    if (count < _length) {
      sink.add(Uint8List.sublistView(_bytes, 0, _length - count));
    }
  }
}
