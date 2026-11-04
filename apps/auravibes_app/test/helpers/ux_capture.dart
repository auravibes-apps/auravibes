import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final uxCaptureFontMetadata = <Map<String, String>>[];
int _captureNumber = 0;

Future<void> loadUxCaptureFonts() async {
  for (final font in const {
    'Inter': 'assets/fonts/Inter.ttf',
    'JetBrains Mono':
        'packages/gpt_markdown/lib/fonts/JetBrainsMono-Regular.ttf',
    'packages/gpt_markdown/JetBrainsMono':
        'packages/gpt_markdown/lib/fonts/JetBrainsMono-Regular.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
  }.entries) {
    await _registerCaptureFont(
      font.key,
      font.value,
      await rootBundle.load(font.value),
    );
  }
  await _registerCaptureFont(
    'Roboto',
    'Flutter SDK artifacts/material_fonts/Roboto-Regular.ttf',
    await _sdkRoboto(),
  );
}

Future<void> _registerCaptureFont(
  String family,
  String source,
  ByteData data,
) async {
  await (FontLoader(family)..addFont(.value(data))).load();
  uxCaptureFontMetadata.add({
    'family': family,
    'source': source,
    'sha256': sha256
        .convert(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        )
        .toString(),
  });
}

Future<ByteData> _sdkRoboto() async {
  for (
    var directory = File(Platform.resolvedExecutable).parent;
    directory.path != directory.parent.path;
    directory = directory.parent
  ) {
    final font = File('${directory.path}/material_fonts/Roboto-Regular.ttf');
    if (font.existsSync()) {
      return (await font.readAsBytes()).buffer.asByteData();
    }
  }

  throw StateError('Flutter SDK Roboto font is unavailable for capture');
}

Future<void> captureUxWidget(
  WidgetTester tester,
  String name,
  String route, {
  required String locale,
  required Size size,
  required double scale,
  required bool dark,
  Map<String, Object>? controlMeasurements,
  String? fixture,
  String? outputDirectory,
}) async {
  const defaultOutput = String.fromEnvironment('UX_CAPTURE_DIR');
  final output = outputDirectory ?? defaultOutput;
  if (output.isEmpty) return;
  const fingerprint = String.fromEnvironment('UX_SOURCE_FINGERPRINT');
  const sourceProvenance = String.fromEnvironment('UX_CAPTURE_PROVENANCE');
  final view = tester.view;
  final viewMetrics = {
    'devicePixelRatio': view.devicePixelRatio,
    'paddingPhysicalPixels': _viewPadding(view.padding),
    'viewPaddingPhysicalPixels': _viewPadding(view.viewPadding),
    'viewInsetsPhysicalPixels': _viewPadding(view.viewInsets),
  };
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('ux-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final directory = Directory(output);
    final _ = await directory.create(recursive: true);
    final artifact = '${(++_captureNumber).toString().padLeft(3, '0')}-$name';
    final _ = await File('$output/$artifact.png').writeAsBytes(
      (bytes ?? (throw StateError('PNG encoding failed'))).buffer.asUint8List(),
    );
    final _ = await File('$output/$artifact.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'name': name,
        'controlMeasurements': ?controlMeasurements,
        'route': route,
        'fixture': fixture ?? _fixtureDescription(name),
        'sourceFingerprint': fingerprint,
        'sourceProvenance': sourceProvenance.isEmpty
            ? {'kind': 'unverified', 'declaredFingerprint': fingerprint}
            : jsonDecode(sourceProvenance),
        'renderer': 'Flutter widget-test Skia, ${Platform.operatingSystem}',
        'viewport': [size.width, size.height],
        'viewMetrics': viewMetrics,
        'locale': locale,
        'textScale': scale,
        'theme': dark ? 'dark' : 'light',
        'accentHue': 186.0,
        'flavor': 'prod view under controlled widget fixture',
        'disableAnimations': true,
        'fonts': uxCaptureFontMetadata,
        'fontLimitations':
            'Flutter widget-test text only; native system typography and '
            'assistive technology are not represented.',
      }),
    );
  });
}

String _fixtureDescription(String name) => switch (name) {
  'cloud-workspace-invite-dialog' =>
    'Controlled cloud workspace admin detail with invitation dialog open; '
        'no remote mutation',
  'cloud-workspace-populated-membership' =>
    'Controlled cloud workspace admin detail with one member and one '
        'pending invitation; no remote mutation',
  final capture when capture.startsWith('CloudWorkspaceDetailRoute-') =>
    'Controlled cloud workspace admin detail with one member and one '
        'pending invitation; no remote mutation',
  'queued-prompts-before' || 'queued-prompts-after' =>
    'Persisted local conversation with three fixed text-only queued drafts; '
        'no model requests, attachments, network access, or remote mutations',
  'agent-editor-skills-failure' || 'skills-list-failure' =>
    'Persisted local workspace with a controlled skills load failure',
  'agent-editor-tools-failure' =>
    'Persisted local workspace with a controlled tools load failure',
  'connected-editor-tools-failure' || 'connected-editor-connections-failure' =>
    'Connected data editor in a test dialog with a controlled load failure',
  'skill-detail-failure' || 'skill-resource-parent-failure' =>
    'Persisted local workspace with a controlled skill detail load failure',
  'skill-resource-failure' =>
    'Persisted local workspace with a controlled skill resource load failure',
  'skill-resources-list-failure' =>
    'Persisted local workspace with a controlled skill resources list failure',
  'agent-editor-skills-failure-es-large-dark' =>
    'Persisted local workspace with a controlled skills load failure',
  'conversation-archive-export-review' =>
    'Local conversation with one synthetic text attachment whose path points '
        'to no file; review dialog opened before attachment byte reads or save',
  'conversation-archive-before' =>
    'Persisted local workspace and seeded parent conversation; conversation '
        'options open before device-local archive, with no remote access',
  'conversation-archive-after' =>
    'Same persisted local workspace after archiving the conversation; '
        'archived conversation list visible, with no remote access',
  'workspace-erasure-confirmation-disclosure' =>
    'In-memory local workspace plus synthetic owner account and deleted cloud '
        'workspace state; confirmation open with no remote access or deletion',
  'service-connections-services-entry' =>
    'Persisted local workspace with three controlled service rows: '
        'Notion needs reconnect, Linear connected, Sentry failed; '
        'no remote access',
  'service-connections-search-empty' =>
    'Same Services route and rows after a query matching no service; '
        'no remote access',
  'service-connections-network-error' =>
    'Same Services route and rows after a controlled network test failure; '
        'no remote request',
  'IntroRoute' => 'Empty in-memory database; no workspace or account',
  'MixedConnections' =>
    'Four controlled connection rows: model provider, '
        'expired MCP, two saved credentials; no remote access '
        'claim',
  'MixedAccounts' =>
    'Two origins with stored accounts; controlled expired and unknown health',
  'CloudTools' =>
    'Matching cloud mirror and session; controlled available gate '
        'and empty tools; actual capability restriction',
  'LocalEmptyTools' =>
    'Persisted local workspace with controlled empty tool providers; '
        'actual local capability, add control and empty hint',
  'FailedWorkspace' =>
    'Controlled missing local workspace failure and actual '
        'route recovery screen',
  'CloudWorkspaceDetailRoute' =>
    'Controlled cloud workspace admin detail with '
        'authoritative capability values; no remote mutation',
  'ServiceConnectionEditRoute' =>
    'Controlled saved generic service editor state',
  _ =>
    'Persisted local in-memory workspace, two agents '
        'sharing a custom skill, disabled agent/skill, schema '
        'without credential, template resource/tool, parent and '
        'child chats; no models or cloud accounts',
};

Map<String, double> _viewPadding(ui.ViewPadding padding) => {
  'left': padding.left,
  'top': padding.top,
  'right': padding.right,
  'bottom': padding.bottom,
};
