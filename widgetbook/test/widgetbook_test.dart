import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/test.dart';
import 'package:widgetbook_workspace/components.g.dart';
import 'package:widgetbook_workspace/main.dart';

Future<void> main() async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  assert(
    identical(binding, TestWidgetsFlutterBinding.instance),
    'Flutter test binding must be initialized.',
  );

  final outputDirectory = Directory('build/.widgetbook');
  if (outputDirectory.existsSync()) {
    await outputDirectory.delete(recursive: true);
  }

  final widgetbookTests = testWidgetbook(createWidgetbookConfig());
  await widgetbookTests;

  test('registers the complete Aura catalog', () {
    expect(components, hasLength(47));
    expect(components.expand((component) => component.stories), hasLength(53));
  });

  test('documents every Aura component', () {
    expect(
      components.every(
        (component) => component.docComment?.trim().isNotEmpty ?? false,
      ),
      isTrue,
    );
  });

  test('generates accessibility metadata without violations', () async {
    final metadataFiles = Directory('build/.widgetbook')
        .list(recursive: true)
        .where((entity) => entity is File && entity.path.endsWith('.json'));
    final violations = <String>[];

    await for (final entity in metadataFiles) {
      final metadata = jsonDecode(await (entity as File).readAsString());
      final entries = metadata is Map<String, dynamic>
          ? metadata['violations']
          : null;
      if (entries is List && entries.isNotEmpty) {
        violations.add('${entity.path}: ${entries.join(', ')}');
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
