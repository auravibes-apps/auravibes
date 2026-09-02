import 'dart:convert';
import 'dart:io';

extension on String {
  String _slice(int start, [int? end]) =>
      String.fromCharCodes(codeUnits.getRange(start, end ?? length));
}

/// Merges package LCOV artifacts into one repository-relative report.
Future<void> mergeLcovReports({
  required String inputRoot,
  required String outputPath,
  required String repositoryRoot,
  required int expectedReports,
}) async {
  if (expectedReports < 1) {
    throw const FormatException('Expected report count must be positive');
  }

  final reports = await _reports(Directory(inputRoot));
  if (reports.length != expectedReports) {
    throw FormatException(
      'Expected $expectedReports LCOV reports but found ${reports.length}',
    );
  }

  final records = <String, _Record>{};
  for (final report in reports) {
    final packageRoot = await File('${report.parent.path}/package-root')
        .readAsString();
    final normalizedPackageRoot = _packageRoot(packageRoot.trim());
    for (final record in _parse(await report.readAsString())) {
      final source = _sourcePath(
        record.source,
        packageRoot: normalizedPackageRoot,
        repositoryRoot: repositoryRoot,
      );
      if (_excluded(source)) continue;
      records.putIfAbsent(source, () => _Record(source)).add(record);
    }
  }

  final output = File(outputPath);
  final _ = await output.parent.create(recursive: true);
  final sortedRecords = records.values.toList()
    ..sort((left, right) => left.source.compareTo(right.source));
  final _ = await output.writeAsString(
    sortedRecords.map((record) => record.format()).join(),
  );
}

Future<List<File>> _reports(Directory inputRoot) async {
  if (!inputRoot.existsSync()) {
    throw FormatException(
      'Coverage input directory is missing: ${inputRoot.path}',
    );
  }

  final reports = <File>[];
  await for (final entity in inputRoot.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File && entity.uri.pathSegments.lastOrNull == 'lcov.info') {
      final metadata = File('${entity.parent.path}/package-root');
      if (!metadata.existsSync()) {
        throw FormatException(
          'Coverage report lacks package root: ${entity.path}',
        );
      }
      reports.add(entity);
    }
  }

  return reports..sort((left, right) => left.path.compareTo(right.path));
}

List<_Record> _parse(String report) {
  final records = <_Record>[];
  _Record? current;
  for (final line in const LineSplitter().convert(report)) {
    if (line.isEmpty || line.startsWith('TN:')) {
      continue;
    }
    if (line.startsWith('SF:')) {
      if (current != null) {
        throw const FormatException('Nested LCOV source file');
      }
      final source = line._slice(3);
      if (source.isEmpty) {
        throw const FormatException('Empty LCOV source file');
      }
      current = _Record(source);
      continue;
    }
    if (line == 'end_of_record') {
      if (current == null) {
        throw const FormatException('LCOV record has no source');
      }
      records.add(current);
      current = null;
      continue;
    }
    if (current == null) {
      continue;
    }
    current.parse(line);
  }
  if (current != null) {
    throw const FormatException('Unterminated LCOV record');
  }

  return records;
}

String _packageRoot(String value) {
  final normalized = value.replaceAll(r'\', '/');
  if (normalized.isEmpty ||
      _isAbsolutePath(normalized) ||
      normalized.split('/').contains('..')) {
    throw const FormatException('Invalid coverage package root');
  }

  return normalized.replaceAll(RegExp(r'/+$'), '');
}

String _sourcePath(
  String value, {
  required String packageRoot,
  required String repositoryRoot,
}) {
  final normalizedRoot = Directory(repositoryRoot).absolute.path
      .replaceAll(r'\', '/')
      .replaceAll(RegExp(r'/+$'), '');
  var path = value.replaceAll(r'\', '/');
  if (path.startsWith('$normalizedRoot/')) {
    path = path._slice(normalizedRoot.length + 1);
  }
  if (path.startsWith('lib/')) {
    path = '$packageRoot/$path';
  }
  if (path.startsWith('file:') ||
      _isAbsolutePath(path) ||
      path.split('/').contains('..')) {
    throw FormatException('Non-repository coverage path: $value');
  }

  return path;
}

bool _isAbsolutePath(String path) =>
    path.startsWith('/') || RegExp('^[A-Za-z]:/').hasMatch(path);

bool _excluded(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.mocks.dart') ||
    path.endsWith('/drift_worker.js') ||
    path.startsWith('apps/auravibes_server/lib/src/generated/');

class _Record {
  new(this.source);

  final String source;
  final lineHits = <int, int>{};
  final functionLines = <String, int>{};
  final functionHits = <String, int>{};
  final branchHits = <({int line, int block, int branch}), int?>{};

  void add(_Record other) {
    for (final entry in other.lineHits.entries) {
      final _ = lineHits.update(
        entry.key,
        (value) => value + entry.value,
        ifAbsent: () => entry.value,
      );
    }
    for (final entry in other.functionLines.entries) {
      final existing = functionLines[entry.key];
      if (existing != null && existing != entry.value) {
        throw FormatException('Conflicting function line: ${entry.key}');
      }
      functionLines[entry.key] = entry.value;
    }
    for (final entry in other.functionHits.entries) {
      final _ = functionHits.update(
        entry.key,
        (value) => value + entry.value,
        ifAbsent: () => entry.value,
      );
    }
    for (final entry in other.branchHits.entries) {
      final existing = branchHits[entry.key];
      final incoming = entry.value;
      if (existing == null || incoming == null) {
        branchHits[entry.key] = existing == null && incoming == null
            ? null
            : (existing ?? incoming);
      } else {
        branchHits[entry.key] = existing + incoming;
      }
    }
  }

  void parse(String line) {
    if (line.startsWith('DA:')) {
      final values = _values(line._slice(3), 2, 'line data');
      final [lineText, hitsText] = values;
      final lineNumber = int.tryParse(lineText);
      final hits = int.tryParse(hitsText);
      if (lineNumber == null || hits == null || lineNumber < 1 || hits < 0) {
        throw const FormatException('Invalid LCOV line data');
      }
      final _ = lineHits.update(
        lineNumber,
        (value) => value + hits,
        ifAbsent: () => hits,
      );

      return;
    }
    if (line.startsWith('FN:')) {
      final values = _values(line._slice(3), 2, 'function data');
      final [lineText, name] = values;
      final lineNumber = int.tryParse(lineText);
      if (lineNumber == null || lineNumber < 0 || name.isEmpty) {
        throw const FormatException('Invalid LCOV function data');
      }
      functionLines[name] = lineNumber;

      return;
    }
    if (line.startsWith('FNDA:')) {
      final values = _values(line._slice(5), 2, 'function hit data');
      final [hitsText, name] = values;
      final hits = int.tryParse(hitsText);
      if (hits == null || hits < 0 || name.isEmpty) {
        throw const FormatException('Invalid LCOV function hit data');
      }
      final _ = functionHits.update(
        name,
        (value) => value + hits,
        ifAbsent: () => hits,
      );

      return;
    }
    if (line.startsWith('BRDA:')) {
      final values = _values(line._slice(5), 4, 'branch data');
      final [lineText, blockText, branchText, takenText] = values;
      final lineNumber = int.tryParse(lineText);
      final block = int.tryParse(blockText);
      final branch = int.tryParse(branchText);
      final taken = takenText == '-' ? null : int.tryParse(takenText);
      if (lineNumber == null ||
          block == null ||
          branch == null ||
          takenText != '-' && taken == null ||
          taken != null && taken < 0) {
        throw const FormatException('Invalid LCOV branch data');
      }
      final key = (line: lineNumber, block: block, branch: branch);
      final existing = branchHits[key];
      if (existing == null || taken == null) {
        branchHits[key] = existing == null && taken == null
            ? null
            : existing ?? taken;
      } else {
        branchHits[key] = existing + taken;
      }
    }
  }

  String format() {
    final output = StringBuffer('SF:$source\n');
    final functionNames = functionLines.keys.toSet()..addAll(functionHits.keys);
    final sortedFunctions = functionNames.toList()..sort();
    for (final name in sortedFunctions) {
      final line = functionLines[name];
      if (line != null) output.writeln('FN:$line,$name');
    }
    for (final name in sortedFunctions) {
      output.writeln('FNDA:${functionHits[name] ?? 0},$name');
    }
    if (sortedFunctions.isNotEmpty) {
      final coveredFunctions = sortedFunctions
          .where((name) => (functionHits[name] ?? 0) > 0)
          .length;
      output
        ..writeln('FNF:${sortedFunctions.length}')
        ..writeln('FNH:$coveredFunctions');
    }
    for (final line in lineHits.keys.toList()..sort()) {
      output.writeln('DA:$line,${lineHits[line]}');
    }
    if (lineHits.isNotEmpty) {
      final coveredLines = lineHits.values.where((hits) => hits > 0).length;
      output
        ..writeln('LF:${lineHits.length}')
        ..writeln('LH:$coveredLines');
    }
    final branches = branchHits.keys.toList()..sort(_compareBranches);
    for (final branch in branches) {
      final hits = branchHits[branch];
      output.writeln(
        'BRDA:${branch.line},${branch.block},${branch.branch},${hits ?? '-'}',
      );
    }
    if (branches.isNotEmpty) {
      final coveredBranches = branchHits.values
          .where((hits) => (hits ?? 0) > 0)
          .length;
      output
        ..writeln('BRF:${branches.length}')
        ..writeln('BRH:$coveredBranches');
    }
    output.writeln('end_of_record');

    return output.toString();
  }
}

List<String> _values(String value, int count, String field) {
  final values = value.split(',');
  if (values.length != count) {
    throw FormatException('Invalid LCOV $field');
  }

  return values;
}

int _compareBranches(
  ({int line, int block, int branch}) left,
  ({int line, int block, int branch}) right,
) {
  final lineResult = left.line.compareTo(right.line);
  if (lineResult != 0) return lineResult;
  final blockResult = left.block.compareTo(right.block);
  if (blockResult != 0) return blockResult;

  return left.branch.compareTo(right.branch);
}

Future<void> main(List<String> arguments) async {
  try {
    final options = _options(arguments);
    await mergeLcovReports(
      inputRoot: _requiredOption(options, 'input-root'),
      outputPath: _requiredOption(options, 'output'),
      repositoryRoot: Directory.current.path,
      expectedReports: _requiredInt(options, 'expected-reports'),
    );
  } on Object catch (error) {
    stderr.writeln('merge-lcov: $error');
    exitCode = 2;
  }
}

Map<String, String> _options(List<String> arguments) {
  final options = <String, String>{};
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (!argument.startsWith('--') || index + 1 >= arguments.length) {
      throw const FormatException('Expected option value');
    }
    final key = argument._slice(2);
    if (options.containsKey(key)) {
      throw FormatException('Duplicate option: $argument');
    }
    options[key] = arguments[++index];
  }

  const expected = {'input-root', 'output', 'expected-reports'};
  if (options.length != expected.length ||
      !options.keys.toSet().containsAll(expected)) {
    throw const FormatException('Invalid options');
  }

  return options;
}

String _requiredOption(Map<String, String> options, String key) {
  final value = options[key];
  if (value == null || value.isEmpty) {
    throw FormatException('Missing option: --$key');
  }

  return value;
}

int _requiredInt(Map<String, String> options, String key) {
  final value = int.tryParse(_requiredOption(options, key));
  if (value == null) throw FormatException('Invalid option: --$key');

  return value;
}
