import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.length < 2 || args.firstOrNull != '--') {
    stderr.writeln(
      'Usage: dart run tool/run_quiet.dart -- <executable> [arguments...]',
    );
    exitCode = 2;

    return;
  }

  try {
    final result = await Process.run(args[1], args.skip(2).toList());
    if (result.exitCode == 0) {
      stdout.writeln('Command succeeded.');
    } else {
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      exitCode = result.exitCode;
    }
  } on ProcessException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}
