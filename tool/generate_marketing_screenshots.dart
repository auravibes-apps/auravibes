import 'dart:io';

const _locales = ['en', 'es'];
const _storeScenes = ['result', 'approval', 'workspaces', 'agent', 'model'];
const _webOnlyScenes = [
  'ask',
  'done',
  'setup-workspace',
  'setup-ai',
  'setup-notion',
  'setup-connected',
];
const _websiteShots = {
  'hero': 'result',
  'ask': 'ask',
  'approve': 'approval',
  'done': 'done',
  'workspaces': 'workspaces',
  'agent': 'agent',
  'model': 'model',
  'setup-workspace': 'setup-workspace',
  'setup-ai': 'setup-ai',
  'setup-notion': 'setup-notion',
  'setup-connected': 'setup-connected',
};
const Map<String, ({int width, int height})> _sizes = {
  'iphone': (width: 1320, height: 2868),
  'ipad': (width: 2048, height: 2732),
  'android-phone': (width: 1080, height: 1920),
  'android-tablet': (width: 1920, height: 2560),
};
const Map<String, ({int width, int height})> _rawSizes = {
  'iphone': (width: 1320, height: 2868),
  'ipad': (width: 2064, height: 2752),
  'android-phone': (width: 1080, height: 2340),
  'android-tablet': (width: 1600, height: 2560),
};
const Map<String, ({int width, int height})> _framedSizes = {
  'iphone': (width: 1422, height: 2970),
  'ipad': (width: 2248, height: 2936),
  'android-phone': (width: 1152, height: 2388),
  'android-tablet': (width: 1688, height: 2648),
};

Future<void> main(List<String> arguments) async {
  final root = Directory.current.absolute.path;
  final app = Directory('$root/apps/auravibes_app');
  if (!File('${app.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run this command from the AuraVibes repository root.');
    exitCode = 2;

    return;
  }

  final webRoot = _argument(arguments, '--web-root');
  final flutter = _argument(arguments, '--flutter') ?? 'fvm';
  if (flutter != 'fvm' && flutter != 'flutter') {
    stderr.writeln('--flutter must be fvm or flutter.');
    exitCode = 2;

    return;
  }
  if (webRoot != null &&
      !File('${Directory(webRoot).absolute.path}/src/lib/shots.ts')
          .existsSync()) {
    stderr.writeln('Invalid website root: $webRoot');
    exitCode = 2;

    return;
  }

  final output = Directory('$root/build/marketing_screenshots');
  if (output.existsSync()) output.deleteSync(recursive: true);
  output.createSync(recursive: true);

  final command = flutter == 'fvm' ? ['flutter', 'test'] : ['test'];
  for (final scene in [..._storeScenes, ..._webOnlyScenes]) {
    stdout.writeln('Capturing $scene');
    final arguments = [
      ...command,
      'test/marketing_screenshots/notion_approval_screenshot_test.dart',
      '--no-pub',
      '--plain-name=$scene',
      '--dart-define=MARKETING_SCREENSHOT_CAPTURE=true',
      '--dart-define=MARKETING_SCREENSHOT_OUTPUT=${output.path}',
    ];
    final result = await Process.run(
      flutter,
      arguments,
      workingDirectory: app.path,
    );
    if (result.exitCode != 0) {
      stderr
        ..write(result.stdout)
        ..write(result.stderr);
      exitCode = result.exitCode;

      return;
    }
  }

  for (final locale in _locales) {
    for (final scene in [..._storeScenes, ..._webOnlyScenes]) {
      final targets = _storeScenes.contains(scene)
          ? _sizes.entries
          : [_sizes.entries.first];
      for (final entry in targets) {
        final raw = File('${output.path}/$locale/raw/$scene/${entry.key}.png');
        _checkPng(raw, _rawSizes[entry.key]);
        _checkPng(
          .new('${output.path}/$locale/framed/$scene/${entry.key}.png'),
          _framedSizes[entry.key],
        );
        if (!_storeScenes.contains(scene)) continue;
        if (scene == 'approval' || scene == 'model') {
          _checkPng(
            .new('${output.path}/$locale/detail/$scene/${entry.key}.png'),
            null,
          );
        }
        final storePng = File(
          '${output.path}/$locale/store/$scene/${entry.key}.png',
        );
        final storeJpeg = File(
          '${output.path}/$locale/store/$scene/${entry.key}.jpg',
        );
        _checkPng(storePng, entry.value);
        await _run('sips', [
          '-s',
          'format',
          'jpeg',
          '-s',
          'formatOptions',
          '90',
          storePng.path,
          '--out',
          storeJpeg.path,
        ]);
        storePng.deleteSync();
        await _checkJpeg(storeJpeg, entry.value);
      }
    }
  }

  final imageCount = output.listSync(recursive: true).whereType<File>().length;
  if (imageCount != 160) {
    throw StateError('Expected 160 images, found $imageCount');
  }

  if (webRoot != null) {
    final site = Directory(webRoot).absolute;
    for (final locale in _locales) {
      final shots = Directory('${site.path}/public/shots/$locale')
        ..createSync(recursive: true);
      for (final entry in _websiteShots.entries) {
        for (final ext in ['webp', 'jpg']) {
          if (File('${shots.path}/${entry.key}.$ext').existsSync()) {
            throw StateError(
              'Remove existing ${entry.key}.$ext before writing '
              '${entry.key}.png.',
            );
          }
        }
        final _ = File(
          '${output.path}/$locale/framed/${entry.value}/iphone.png',
        ).copySync('${shots.path}/${entry.key}.png');
      }
    }
    stdout.writeln(
      'Updated ${_websiteShots.length * _locales.length} '
      'website images in $webRoot',
    );
  }

  stdout.writeln(
    'Generated 52 raw PNGs, 52 framed PNGs, 16 detail PNGs, and '
    '40 store JPEGs '
    'in ${output.path}',
  );
}

String? _argument(List<String> arguments, String name) {
  for (var i = 0; i < arguments.length; i++) {
    final argument = arguments[i];
    if (argument.startsWith('$name=')) {
      return argument.replaceFirst('$name=', '');
    }
    if (argument == name && i + 1 < arguments.length) return arguments[i + 1];
  }

  return null;
}

void _checkPng(File file, ({int width, int height})? size) {
  if (!file.existsSync()) throw StateError('Missing ${file.path}');
  final bytes = file.openSync()..setPositionSync(0);
  try {
    final header = bytes.readSync(24);
    if (header.length != 24 ||
        header.firstOrNull != 137 ||
        header[1] != 80 ||
        header[2] != 78 ||
        header[3] != 71) {
      throw StateError('Invalid PNG: ${file.path}');
    }
    final width = _uint32(header, 16);
    final height = _uint32(header, 20);
    if (width == 0 || height == 0) {
      throw StateError('Empty PNG: ${file.path}');
    }
    if (size != null && (width != size.width || height != size.height)) {
      throw StateError('${file.path}: expected $size, found ${width}x$height');
    }
  } finally {
    bytes.closeSync();
  }
}

int _uint32(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

Future<void> _checkJpeg(File file, ({int width, int height}) size) async {
  if (!file.existsSync()) throw StateError('Missing ${file.path}');
  final result = await Process.run('sips', [
    '-g',
    'pixelWidth',
    '-g',
    'pixelHeight',
    '-g',
    'hasAlpha',
    '-g',
    'format',
    file.path,
  ]);
  if (result.exitCode != 0) throw StateError('Cannot inspect ${file.path}');
  final info = result.stdout as String;
  if (!info.contains('pixelWidth: ${size.width}') ||
      !info.contains('pixelHeight: ${size.height}') ||
      !info.contains('hasAlpha: no') ||
      !info.contains('format: jpeg')) {
    throw StateError('Invalid store image ${file.path}: $info');
  }
  const playStoreLimit = 8 * 1024 * 1024;
  if (file.lengthSync() > playStoreLimit) {
    throw StateError('Store image exceeds 8 MB: ${file.path}');
  }
}

Future<void> _run(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    throw StateError('$executable failed: ${result.stderr}');
  }
}
