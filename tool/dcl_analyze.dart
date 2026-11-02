import 'dart:io';

const dclTargetDirectories = [
  'apps/auravibes_app/lib',
  'packages/auravibes_engine/lib',
  'packages/auravibes_ui/lib',
  'widgetbook/lib',
];

const _exclude = '{**/*_test.dart,**/test/**}';

Future<void> main(List<String> directories) async {
  final targets = directories.isEmpty ? dclTargetDirectories : directories;
  final arguments = [
    'run',
    'tool/run_quiet.dart',
    '--',
    Platform.resolvedExecutable,
    'run',
    'dart_code_linter:metrics',
    'analyze',
    ...targets,
    '--exclude=$_exclude',
    '--no-congratulate',
    '--set-exit-on-violation-level=warning',
  ];
  final dart = Platform.resolvedExecutable;
  final process = await Process.start(dart, arguments, mode: .inheritStdio);

  exitCode = await process.exitCode;
}
