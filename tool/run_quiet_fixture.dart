import 'dart:async';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.firstOrNull == 'large-failure') {
    for (var i = 0; i < 40; i++) {
      stdout.write('o' * 7000);
      stderr.write('e' * 8193);
    }
    stdout.write('stdout end\n');
    stderr.write('stderr end\n');
    exitCode = 7;

    return;
  }
  if (args.firstOrNull == 'stream') {
    stdout.writeln('stdout ready');
    stderr.writeln('stderr ready');
    final _ = await stdout.flush();
    final _ = await stderr.flush();
    while (!File(args[1]).existsSync()) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    stdout.writeln('stdout end');
    stderr.writeln('stderr end');
    exitCode = 7;

    return;
  }
  if (args.firstOrNull == 'interrupt') {
    final signal = args[1] == 'SIGINT'
        ? ProcessSignal.sigint
        : ProcessSignal.sigterm;
    final received = Completer<void>();
    final subscription = signal.watch().listen((_) {
      if (!received.isCompleted) received.complete();
    });
    final _ = await File(args[2]).writeAsString('$pid');
    await received.future;
    stdout.writeln('received ${signal.name}');
    stderr.writeln('child cleanup');
    await subscription.cancel();
    exitCode = 23;

    return;
  }
  if (args.firstOrNull == 'stdin-eof') {
    await stdin.drain<void>();

    return;
  }
  stdout.writeln('fixture stdout');
  stderr.writeln('fixture stderr');
  if (args.length != 2 || args[1] != 'argument with spaces') {
    exitCode = 9;

    return;
  }
  exitCode = args.firstOrNull == 'failure' ? 7 : 0;
}
