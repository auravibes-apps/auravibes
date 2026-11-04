import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:path/path.dart' as p;

/// Groups analyzed files by their nearest analysis options file.
Future<List<List<String>>> analyzedPathGroups(
  Directory root,
  List<String> paths,
) async {
  if (paths.isEmpty) return const [];
  final rootPath = p.normalize(root.absolute.path);
  final collection = AnalysisContextCollection(includedPaths: [rootPath]);
  try {
    final groups = <String, List<String>>{};
    for (final path in paths) {
      final absolutePath = p.normalize(p.join(rootPath, path));
      if (!p.isWithin(rootPath, absolutePath)) {
        throw FormatException('Path is outside the repository: $path');
      }
      if (!collection.contexts.any(
        (context) => context.contextRoot.isAnalyzed(absolutePath),
      )) {
        continue;
      }
      var directory = p.dirname(absolutePath);
      while (directory != rootPath &&
          !File(p.join(directory, 'analysis_options.yaml')).existsSync()) {
        directory = p.dirname(directory);
      }
      groups.putIfAbsent(directory, () => []).add(path);
    }

    return groups.values.toList();
  } finally {
    await collection.dispose();
  }
}
