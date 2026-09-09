import 'package:build/build.dart';

class StoryBridgeBuilder implements Builder {
  static final _storyDeclaration = RegExp(
    r'^\s*static\s+final\s+(\$[A-Za-z0-9_]+)\s*=',
    multiLine: true,
  );
  static final _metaDeclaration = RegExp(
    r'^\s*(?:const|final)\s+(_[A-Za-z0-9_]+)\s*=\s*Meta\(',
    multiLine: true,
  );

  new();

  @override
  final buildExtensions = const {
    '.stories.dart': ['.stories.bridge.g.dart'],
  };

  static Builder create(BuilderOptions _) => StoryBridgeBuilder();

  @override
  Future<void> build(BuildStep buildStep) async {
    final source = await buildStep.readAsString(buildStep.inputId);
    final storyFile = buildStep.inputId.path.split('/').last;
    final storyNames = _storyDeclaration
        .allMatches(source)
        .map((match) => match.group(1))
        .whereType<String>();
    final metaNames = _metaDeclaration
        .allMatches(source)
        .map((match) => match.group(1))
        .whereType<String>();
    final lines = <String>[
      '// GENERATED CODE - DO NOT MODIFY BY HAND',
      '// dart format width=80',
      '',
      "part of '$storyFile';",
      '',
      'final _storyMetadata = <Object?>[${metaNames.join(', ')}];',
      '',
      for (final storyName in storyNames)
        'final $storyName = _StorybookDefinitions.$storyName;',
    ];

    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.bridge.g.dart'),
      '${lines.join('\n')}\n',
    );
  }
}
