import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/features/workspaces/models/workspace_search_index.dart';
import 'package:unorm_dart/unorm_dart.dart';

// The before path mirrors the former screen helpers. The after path builds one
// index per data snapshot and includes the same cache-validity check used by
// the screen before each warm search.
const _catalogSizes = [50, 1000, 10000];
const _sampleCount = 9;
const _query = 'workspace';
final _eAcute = String.fromCharCode(0xe9);

var _resultSink = 0;

void main() => const WorkspaceSearchBenchmark().run();

final class const WorkspaceSearchBenchmark({
  final List<int> catalogSizes = _catalogSizes,
  final int sampleCount = _sampleCount,
  final String query = _query,
}) {
  void run() {
    final results = [
      for (final size in catalogSizes)
        _measureCatalog(size, sampleCount: sampleCount, query: query),
    ];
    stdout.writeln(
      jsonEncode({
        'benchmark': 'synthetic_workspace_search',
        'dart': Platform.version.split(' ').first,
        'os': Platform.operatingSystem,
        'samples': sampleCount,
        'query': query,
        'resultSink': _resultSink,
        'results': results,
      }),
    );
  }
}

Map<String, Object?> _measureCatalog(
  int size, {
  required int sampleCount,
  required String query,
}) {
  final catalog = [
    for (var index = 0; index < size; index++)
      _CatalogItem(
        id: index.toString().padLeft(8, '0'),
        name: switch (index % 4) {
          0 => 'Caf$_eAcute Alpha Workspace $index',
          1 => 'R${_eAcute}sum$_eAcute Beta Workspace $index',
          2 => 'Workspace Gamma $index',
          _ => 'Workspace Delta $index',
        },
      ),
  ];
  final baselineMatches = _baselineFilter(catalog, query);
  final index = _newIndex(catalog);
  final indexedMatches = index.matching(query);

  final before = <String, int>{
    'normalizeAllUs': _measure(
      () => _baselineNormalizeAll(catalog),
      sampleCount: sampleCount,
    ),
    'filterUs': _measure(
      () => _baselineFilter(catalog, query).length,
      sampleCount: sampleCount,
    ),
    'sortUs': _measure(
      () => _baselineSort(baselineMatches).length,
      sampleCount: sampleCount,
    ),
    'searchUs': _measure(
      () => _baselineSort(_baselineFilter(catalog, query)).length,
      sampleCount: sampleCount,
    ),
  };

  var measuredIndex = _newIndex(catalog);
  final after = <String, int>{
    'normalizeAllUs': _measure(
      () => _indexedNormalizeAll(catalog),
      sampleCount: sampleCount,
    ),
    'indexBuildUs': _measure(() {
      measuredIndex = _newIndex(catalog);

      return catalog.length;
    }, sampleCount: sampleCount),
    'cacheCheckUs': _measure(
      () => measuredIndex.hasSameItems(catalog) ? 1 : 0,
      sampleCount: sampleCount,
    ),
    'filterUs': _measure(
      () => measuredIndex.matching(query).length,
      sampleCount: sampleCount,
    ),
    'sortUs': _measure(
      () => measuredIndex.sort(indexedMatches).length,
      sampleCount: sampleCount,
    ),
    'warmSearchUs': _measure(() {
      if (!measuredIndex.hasSameItems(catalog)) {
        measuredIndex = _newIndex(catalog);
      }

      return measuredIndex.search(query).length;
    }, sampleCount: sampleCount),
  };
  final perSearchSavings = before['searchUs']! - after['warmSearchUs']!;
  final rebuildCost = after['indexBuildUs']!;

  return {
    'catalogSize': size,
    'matchedCount': baselineMatches.length,
    'before': before,
    'after': after,
    'estimatedBreakEvenQueries': perSearchSavings <= 0
        ? null
        : (rebuildCost / perSearchSavings).ceil(),
  };
}

WorkspaceSearchIndex<_CatalogItem> _newIndex(List<_CatalogItem> catalog) =>
    WorkspaceSearchIndex(
      catalog,
      nameOf: (item) => item.name,
      idOf: (item) => item.id,
    );

int _measure(int Function() operation, {required int sampleCount}) {
  final samples = <int>[];
  _resultSink = operation();
  for (var sample = 0; sample < sampleCount; sample++) {
    final timer = Stopwatch()..start();
    _resultSink = operation();
    timer.stop();
    samples.add(timer.elapsedMicroseconds);
  }
  samples.sort();

  return samples[samples.length ~/ 2];
}

int _baselineNormalizeAll(List<_CatalogItem> catalog) {
  var normalizedLength = 0;
  for (final item in catalog) {
    normalizedLength += _normalizeBefore(item.name).length;
  }

  return normalizedLength;
}

int _indexedNormalizeAll(List<_CatalogItem> catalog) {
  var normalizedLength = 0;
  for (final item in catalog) {
    normalizedLength += normalizeWorkspaceSearch(item.name).length;
  }

  return normalizedLength;
}

String _normalizeBefore(String value) =>
    nfkd(value).replaceAll(RegExp(r'\p{M}', unicode: true), '').toLowerCase();

List<_CatalogItem> _baselineFilter(
  List<_CatalogItem> catalog,
  String normalizedQuery,
) => catalog
    .where((item) => _normalizeBefore(item.name).contains(normalizedQuery))
    .toList();

List<_CatalogItem> _baselineSort(List<_CatalogItem> items) =>
    List<_CatalogItem>.of(items)..sort((left, right) {
      final comparison = left.name.toLowerCase().compareTo(
        right.name.toLowerCase(),
      );

      return comparison != 0 ? comparison : left.id.compareTo(right.id);
    });

final class _CatalogItem({
  required final String id,
  required final String name,
});
