import 'dart:io';

void main(List<String> args) {
  stdout.writeln('fixture stdout');
  stderr.writeln('fixture stderr');
  if (args.length != 2 || args[1] != 'argument with spaces') {
    exitCode = 9;

    return;
  }
  exitCode = args.firstOrNull == 'failure' ? 7 : 0;
}
