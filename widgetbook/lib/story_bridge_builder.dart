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
    await _StoryBridgeOutput(buildStep.inputId, source).write(buildStep);
  }

  static Iterable<String> _findNames(RegExp expression, String source) =>
      expression
          .allMatches(source)
          .map((match) => match.group(1))
          .whereType<String>();

  static String _buildBridgeContent(
    String storyFile,
    Iterable<String> storyNames,
    Iterable<String> metaNames,
  ) {
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

    return '${lines.join('\n')}\n';
  }
}

class _StoryBridgeOutput {
  new(this.inputId, String source)
    : _content = StoryBridgeBuilder._buildBridgeContent(
        inputId.path.split('/').last,
        StoryBridgeBuilder._findNames(
          StoryBridgeBuilder._storyDeclaration,
          source,
        ),
        StoryBridgeBuilder._findNames(
          StoryBridgeBuilder._metaDeclaration,
          source,
        ),
      );

  final AssetId inputId;
  final String _content;

  Future<void> write(BuildStep buildStep) => buildStep.writeAsString(
    inputId.changeExtension('.bridge.g.dart'),
    _content,
  );
}
