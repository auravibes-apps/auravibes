@Tags(['marketing-screenshots'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/widgets/chat_tool_approval_card.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/recent_model_selections_notifier.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/settings/notifiers/accent_hue.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/mcp_form_state.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_with_responsive_drawer.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_app/widgets/responsive_shell_layout.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:device_preview/device_preview.dart' show SystemUiBar;
import 'package:device_preview/presets.dart';
import 'package:device_preview/svg.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../helpers/test_provider_scope.dart';

const _workspaceId = 'marketing-workspace';
const _chatId = 'notion-approval';
const _agentId = 'project-planner';
const _modelId = 'demo-model';
const _toolName = 'mcp_demo_notion_update-page';
const _capture = bool.fromEnvironment('MARKETING_SCREENSHOT_CAPTURE');
const _output = String.fromEnvironment('MARKETING_SCREENSHOT_OUTPUT');
const _dark = bool.fromEnvironment('MARKETING_SCREENSHOT_DARK');
final _marketingColors = AuraComputedColorScheme(
  primaryHue: AccentHue.defaultValue,
  brightness: _dark ? .dark : .light,
);
const ValueKey<String> _appKey = .new('marketing-app-capture');
const ValueKey<String> _storeKey = .new('marketing-store-capture');
const ValueKey<String> _frameKey = .new('marketing-device-frame-capture');
const ({String name, double width, double height, DevicePreset preset})
_iphoneTarget = (
  name: 'iphone',
  width: 1320.0,
  height: 2868.0,
  preset: DevicePresets.iPhone16ProMax,
);

const List<({String name, double width, double height, DevicePreset preset})>
_targets = [
  _iphoneTarget,
  (
    name: 'ipad',
    width: 2048.0,
    height: 2732.0,
    preset: DevicePresets.iPadPro13M4,
  ),
  (
    name: 'android-phone',
    width: 1080.0,
    height: 1920.0,
    preset: DevicePresets.galaxyS25,
  ),
  (
    name: 'android-tablet',
    width: 1920.0,
    height: 2560.0,
    preset: DevicePresets.galaxyTabS11,
  ),
];

const _storeScenes = ['result', 'approval', 'workspaces', 'agent', 'model'];
final Map<String, String> _spanishCopy = (jsonDecode(
  File('test/marketing_screenshots/fixture_es.json').readAsStringSync(),
) as Map<String, dynamic>).cast<String, String>();

String _es(String key) =>
    _spanishCopy[key] ?? (throw StateError('Missing Spanish fixture: $key'));

const _webScenes = [
  'ask',
  'done',
  'setup-workspace',
  'setup-ai',
  'setup-notion',
  'setup-connected',
];

void main() {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  tearDownAll(database.close);

  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader('JetBrains Mono')..addFont(
          rootBundle.load(
            'packages/gpt_markdown/lib/fonts/JetBrainsMono-Regular.ttf',
          ),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final id in const ['openai', 'anthropic']) {
      final loader = SvgNetworkLoader('https://models.dev/logos/$id.svg');
      final bytes = await SvgStringLoader(
        File('test/marketing_screenshots/logos/$id.svg').readAsStringSync(),
      ).loadBytes(null);
      final _ = await svg.cache.putIfAbsent(
        loader.cacheKey(null),
        () async => bytes,
      );
    }
  });

  for (final locale in const ['en', 'es']) {
    for (final scene in [..._storeScenes, ..._webScenes]) {
      for (final target
          in _storeScenes.contains(scene) ? _targets : [_iphoneTarget]) {
        testWidgets('$locale ${target.name} $scene', (tester) async {
          final density = target.preset.devicePixelRatio;
          final screen = target.preset.portraitSize;
          tester.view.physicalSize = screen * density;
          tester.view.devicePixelRatio = density;
          final padding = target.preset.portraitPadding;
          tester.view.padding = .new(
            left: padding.left * density,
            top: padding.top * density,
            right: padding.right * density,
            bottom: padding.bottom * density,
          );
          addTearDown(tester.view.resetPadding);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final fixture = _NotionFixture(locale, scene);
          final colors = _marketingColors;
          final auraTheme = (_dark ? AuraTheme.dark : AuraTheme.light).copyWith(
            colors: colors,
          );
          final router = GoRouter(
            routes: $appRoutes,
            initialLocation: _location(scene),
            overridePlatformDefaultLocation: true,
          );
          addTearDown(router.dispose);

          await tester.runAsync(() async {
            await tester.pumpWidget(
              EasyLocalization(
                child: Builder(
                  builder: (context) => TestProviderScope(
                    overrides: _overrides(fixture, database),
                    child: RepaintBoundary(
                      key: _appKey,
                      child: ColoredBox(
                        color: const Color(0xFFF0F5FA),
                        child: Portal(
                          child: MaterialApp.router(
                            routerConfig: router,
                            builder: (context, child) => AuraThemeScope(
                              theme: auraTheme,
                              child: AuraLegacyMaterialBridge(
                                child: AuraSnackBarHost(
                                  child: AuraText(
                                    child: child ?? const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                            theme: .new(
                              colorScheme: ColorScheme(
                                brightness: _dark ? .dark : .light,
                                primary: colors.primary,
                                onPrimary: colors.onPrimary,
                                secondary: colors.secondary,
                                onSecondary: colors.onSecondary,
                                error: colors.error,
                                onError: colors.onError,
                                surface: colors.surface,
                                onSurface: colors.onSurface,
                              ),
                              scaffoldBackgroundColor: colors.background,
                              platform: target.name.startsWith('android')
                                  ? .android
                                  : .iOS,
                              useMaterial3: true,
                              brightness: _dark ? .dark : .light,
                              fontFamily:
                                  AuraTheme.light.typography.bodyFontFamily,
                            ),
                            locale: context.locale,
                            localizationsDelegates: [
                              ...GlobalMaterialLocalizations.delegates,
                              ...context.localizationDelegates,
                            ],
                            supportedLocales: context.supportedLocales,
                            debugShowCheckedModeBanner: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                supportedLocales: const [Locale('en'), Locale('es')],
                path: 'assets/i18n',
                fallbackLocale: const Locale('en'),
                startLocale: .new(locale),
                useOnlyLangCode: true,
                useFallbackTranslations: true,
                saveLocale: false,
              ),
            );
          });
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
          await tester.pump(const Duration(milliseconds: 300));
          if (scene == 'model') {
            expect(find.text('GPT 5.5'), findsWidgets);
            await tester.tap(find.text('GPT 5.5').last);
            await tester.pump(const Duration(seconds: 1));
            final _ = await tester.pumpAndSettle();
            expect(find.byType(BottomSheet), findsOneWidget);
          }
          if (scene == 'workspaces') {
            if (!ResponsiveShellLayout.isDesktop(screen.width)) {
              await tester.tap(find.byKey(const ValueKey('app_drawer_menu')));
              final _ = await tester.pumpAndSettle();
            }
            await tester.tap(find.byKey(const ValueKey('workspace_actions')));
            final _ = await tester.pumpAndSettle();
            await tester.tap(
              find.text(
                locale == 'es'
                    ? 'Gestionar Espacios de Trabajo'
                    : 'Manage Workspaces',
              ),
            );
            final _ = await tester.pumpAndSettle();
          }
          if (scene == 'approval') {
            const details = ValueKey('activity_tool_details_notion-update-1');
            if (find.byKey(details).evaluate().isNotEmpty) {
              await tester.tap(
                find.byKey(const ValueKey('activity_tool_notion-update-1')),
              );
              final _ = await tester.pumpAndSettle();
            }
            expect(find.byKey(details), findsNothing);
          }
          if (scene == 'setup-notion') {
            await tester.tap(find.byIcon(Icons.extension).first);
            await tester.pump(const Duration(milliseconds: 300));
            final _ = await tester.pumpAndSettle();
          }
          if (scene == 'setup-workspace') {
            await tester.enterText(
              find.byType(AuraInput).first,
              locale == 'es' ? 'Planes del fin de semana' : 'Weekend plans',
            );
            await tester.pump(const Duration(milliseconds: 300));
          }
          if (scene == 'model') {
            expect(find.text('OpenAI - OpenAI'), findsWidgets);
          } else if (scene == 'workspaces') {
            for (final name in fixture.workspaceNames) {
              expect(find.text(name), findsWidgets);
            }
          } else if (scene == 'setup-workspace') {
            expect(
              find.text(
                locale == 'es'
                    ? 'Crear Nuevo Espacio de Trabajo'
                    : 'Create New Workspace',
              ),
              findsWidgets,
            );
          } else if (scene == 'setup-ai') {
            final _ = await tester.pumpAndSettle();
            expect(
              find.text(locale == 'es' ? 'Conectar IA' : 'Connect AI'),
              findsWidgets,
            );
            expect(find.text('OpenAI'), findsWidgets);
            expect(find.text('Anthropic'), findsWidgets);
          } else if (scene == 'setup-notion') {
            expect(
              find.text(
                locale == 'es' ? 'Agregar Servidor MCP' : 'Add MCP Server',
              ),
              findsWidgets,
            );
            expect(find.text('OAuth'), findsWidgets);
          } else if (scene == 'setup-connected') {
            expect(find.text('Notion'), findsWidgets);
          } else {
            expect(find.text(fixture.request), findsOneWidget);
            expect(
              find.text(fixture.isSpanish ? 'Ahora mismo' : 'Just now'),
              findsWidgets,
            );
            if (scene == 'agent') {
              expect(
                find.text(locale == 'es' ? 'Planificador' : 'Project Planner'),
                findsWidgets,
              );
            }
            if (scene == 'result' || scene == 'done') {
              expect(
                find.textContaining(
                  locale == 'es' ? _es('updatedPrefix') : 'I updated',
                ),
                findsWidgets,
              );
            }
          }
          final viewport = Offset.zero & .new(screen.width, screen.height);
          if (scene == 'approval') {
            expect(find.textContaining('Notion'), findsWidgets);
            expect(
              viewport.contains(
                tester.getRect(find.text(fixture.request)).topLeft,
              ),
              isTrue,
            );
            for (final action in const [
              'tool_approval_allow_once',
              'tool_approval_allow_conversation',
              'tool_approval_skip',
              'tool_approval_stop_all',
            ]) {
              expect(find.byKey(ValueKey(action)), findsOneWidget);
              final bounds = tester.getRect(find.byKey(ValueKey(action)));
              expect(viewport.contains(bounds.topLeft), isTrue);
              expect(viewport.contains(bounds.bottomRight), isTrue);
            }
          }
          expect(find.byType(AppWithResponsiveDrawer), findsOneWidget);
          expect(
            Theme.of(tester.element(find.byType(AppWithResponsiveDrawer)))
                .colorScheme
                .primary,
            colors.primary,
          );
          expect(
            MediaQuery.paddingOf(
              tester.element(find.byType(AppWithResponsiveDrawer)),
            ),
            padding,
          );
          expect(
            ResponsiveShellLayout.isDesktop(screen.width),
            screen.width >= ResponsiveShellLayout.desktopBreakpoint,
          );
          expect(tester.takeException(), isNull);

          if (!_capture) {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(milliseconds: 50));

            return;
          }
          if (_output.isEmpty) {
            throw StateError('Missing screenshot output path');
          }

          final detailBounds = switch (scene) {
            'approval' => tester.getRect(find.byType(ChatToolApprovalCard)),
            'model' => _modelDetailBounds(tester, locale),
            _ => null,
          };
          final raw = await _png(tester, _appKey, density);
          _write('$locale/raw/$scene/${target.name}.png', raw);
          Uint8List? detail;
          if (detailBounds != null) {
            detail = await tester.runAsync(
              () => _crop(raw, detailBounds, screen, density),
            );
            if (detail == null) throw StateError('Could not crop detail');
            _write('$locale/detail/$scene/${target.name}.png', detail);
          }
          final frame =
              target.preset.frame ??
              (throw StateError('${target.name} preset has no frame'));
          tester.view.physicalSize = frame.size * density;
          await tester.pumpWidget(
            Directionality(
              textDirection: .ltr,
              child: RepaintBoundary(
                key: _frameKey,
                child: _DeviceFrameShot(image: raw, preset: target.preset),
              ),
            ),
          );
          await tester.runAsync(
            () => precacheImage(
              MemoryImage(raw),
              tester.element(find.byKey(_frameKey)),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          final framed = await _png(tester, _frameKey, density, opaque: false);
          _write('$locale/framed/$scene/${target.name}.png', framed);
          if (!_storeScenes.contains(scene)) {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(milliseconds: 50));

            return;
          }
          tester.view.physicalSize = .new(target.width, target.height);
          await tester.pumpWidget(
            MaterialApp(
              home: RepaintBoundary(
                key: _storeKey,
                child: _StoreCanvas(
                  image: framed,
                  detail: detail,
                  frameSize: frame.size,
                  title: fixture.headline,
                  scene: scene,
                ),
              ),
              theme: .new(fontFamily: 'Inter'),
              debugShowCheckedModeBanner: false,
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
          await tester.runAsync(
            () => precacheImage(
              MemoryImage(framed),
              tester.element(find.byKey(_storeKey)),
            ),
          );
          final detailImage = detail;
          if (detailImage != null) {
            await tester.runAsync(
              () => precacheImage(
                MemoryImage(detailImage),
                tester.element(find.byKey(_storeKey)),
              ),
            );
          }
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          final canvas =
              Offset.zero &
              .new(target.width / density, target.height / density);
          final device = tester.getRect(
            find.byKey(const ValueKey('store_device_frame')),
          );
          expect(canvas.contains(device.topLeft), isTrue);
          expect(device.right <= canvas.right, isTrue);
          expect(device.bottom <= canvas.bottom, isTrue);
          expect(
            device.width / device.height,
            closeTo(frame.size.aspectRatio, 0.001),
          );
          if (detail != null) {
            final callout = tester.getRect(
              find.byKey(const ValueKey('store_detail_crop')),
            );
            expect(callout.overlaps(device), isFalse);
            expect(callout.right <= canvas.right, isTrue);
            expect(callout.bottom <= canvas.bottom, isTrue);
          }
          final store = await _png(tester, _storeKey, density);
          _write('$locale/store/$scene/${target.name}.png', store);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
      }
    }
  }
}

String _location(String scene) => switch (scene) {
  'workspaces' => '/workspaces/$_workspaceId/chat/new',
  'model' => '/workspaces/$_workspaceId/chat/new',
  'setup-ai' =>
    '/workspaces/$_workspaceId/more/service-connections/new?type=modelProvider',
  'setup-workspace' =>
    '/workspaces/$_workspaceId/more/manage-workspaces/create',
  'setup-notion' => '/workspaces/$_workspaceId/more/tools',
  'setup-connected' => '/workspaces/$_workspaceId/more/tools',
  _ => '/workspaces/$_workspaceId/chats/$_chatId',
};

Rect _modelDetailBounds(WidgetTester tester, String locale) {
  final sheet = tester.getRect(find.byType(BottomSheet));
  final title = tester.getRect(
    find.text(locale == 'es' ? 'Modelo' : 'Model').last,
  );
  final lastOption = tester.getRect(
    find
        .ancestor(
          of: find.text('Claude Sonnet 4').last,
          matching: find.byType(AuraTile),
        )
        .first,
  );

  return .fromLTRB(sheet.left, title.top, sheet.right, lastOption.bottom);
}

Future<Uint8List> _png(
  WidgetTester tester,
  Key key,
  double density, {
  bool opaque = true,
}) async {
  final bytes = await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final image = await boundary.toImage(pixelRatio: density);
    final pixels = await image.toByteData();
    if (pixels == null) throw StateError('Could not inspect screenshot pixels');
    final rgba = pixels.buffer.asUint8List();
    for (var i = 3; opaque && i < rgba.length; i += 4) {
      if (rgba[i] != 255) {
        throw StateError('Screenshot contains transparent pixels');
      }
    }
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return data?.buffer.asUint8List();
  });
  if (bytes == null) throw StateError('Could not encode screenshot');

  return bytes;
}

Future<Uint8List> _crop(
  Uint8List png,
  Rect widgetBounds,
  Size screen,
  double density,
) async {
  final bounds = widgetBounds.inflate(16).intersect(Offset.zero & screen);
  if (bounds.isEmpty) {
    throw StateError('Detail crop is outside the app capture');
  }
  final codec = await ui.instantiateImageCodec(png);
  final decoded = await codec.getNextFrame();
  final image = decoded.image;
  final width = (bounds.width * density).round();
  final height = (bounds.height * density).round();
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    .fromLTWH(
      bounds.left * density,
      bounds.top * density,
      width.toDouble(),
      height.toDouble(),
    ),
    .fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    .new(),
  );
  final cropped = await recorder.endRecording().toImage(width, height);
  final bytes = await cropped.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  cropped.dispose();
  codec.dispose();
  if (bytes == null) throw StateError('Could not encode detail crop');

  return bytes.buffer.asUint8List();
}

class _DeviceFrameShot extends StatelessWidget {
  const new({required this.image, required this.preset});

  final Uint8List image;
  final DevicePreset preset;

  @override
  Widget build(BuildContext context) {
    final frame =
        preset.frame ??
        (throw StateError('${preset.name} preset has no frame'));
    final screen = preset.portraitSize;

    return SizedBox.fromSize(
      child: Stack(
        children: [
          CustomPaint(painter: _FrameBodyPainter(frame.body), size: frame.size),
          Positioned(
            left: frame.screenOffset.dx,
            top: frame.screenOffset.dy,
            width: screen.width,
            height: screen.height,
            child: ClipPath(
              clipper: _ScreenClipper(frame.screenPath),
              child: Image.memory(image, fit: .fill),
            ),
          ),
          Positioned(
            left: frame.screenOffset.dx,
            top: frame.screenOffset.dy,
            width: screen.width,
            height: screen.height,
            child: CustomPaint(painter: _SystemBarsPainter(preset)),
          ),
        ],
      ),
      size: frame.size,
    );
  }
}

class _FrameBodyPainter extends CustomPainter {
  new(String body) : drawing = SvgDrawing.parse(body);

  final SvgDrawing drawing;

  @override
  void paint(Canvas canvas, Size size) =>
      drawing.paintInto(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(_FrameBodyPainter oldDelegate) => false;
}

class _ScreenClipper extends CustomClipper<Path> {
  new(String path) : outline = parseSvgPathData(path)..fillType = .evenOdd;

  final Path outline;

  @override
  Path getClip(Size size) => outline;

  @override
  bool shouldReclip(_ScreenClipper oldClipper) => false;
}

class _SystemBarsPainter extends CustomPainter {
  new(this.preset);

  final DevicePreset preset;

  @override
  void paint(Canvas canvas, Size size) {
    final padding = preset.portraitPadding;
    final status = preset.systemUi?.statusBar;
    final navigation = preset.systemUi?.navigationBar;
    if (status != null) {
      _paint(canvas, status.leading, status, 0, padding.top);
      _paint(canvas, status.trailing, status, size.width, padding.top);
    }
    if (navigation != null && navigation.center.isNotEmpty) {
      final drawing = SvgDrawing.parse(navigation.center);
      drawing.paintInto(
        canvas,
        .fromLTWH(
          (size.width - drawing.size.width) / 2,
          size.height - (navigation.bottomInset ?? 0) - drawing.size.height,
          drawing.size.width,
          drawing.size.height,
        ),
        currentColor: _marketingColors.onBackground,
      );
    }
  }

  @override
  bool shouldRepaint(_SystemBarsPainter oldDelegate) => false;

  void _paint(
    Canvas canvas,
    String source,
    SystemUiBar bar,
    double edge,
    double height,
  ) {
    if (source.isEmpty) return;
    final drawing = SvgDrawing.parse(source);
    drawing.paintInto(
      canvas,
      .fromLTWH(
        edge == 0 ? bar.inset : edge - bar.inset - drawing.size.width,
        (height - drawing.size.height) / 2,
        drawing.size.width,
        drawing.size.height,
      ),
      currentColor: _marketingColors.onBackground,
    );
  }
}

void _write(String name, Uint8List bytes) {
  final file = File('$_output/$name');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes, flush: true);
}

class _StoreCanvas extends StatelessWidget {
  const new({
    required this.image,
    required this.detail,
    required this.frameSize,
    required this.title,
    required this.scene,
  });

  final Uint8List image;
  final Uint8List? detail;
  final Size frameSize;
  final String title;
  final String scene;

  List<Color> get _palette => switch (scene) {
    'approval' => [_marketingColors.primaryVariant, _marketingColors.primary],
    'workspaces' => [DesignColors.neutral800, _marketingColors.primaryVariant],
    'agent' => [DesignColors.neutral900, _marketingColors.primary],
    'model' => [_marketingColors.primaryVariant, DesignColors.neutral800],
    _ => [DesignColors.neutral900, _marketingColors.primaryVariant],
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final width = size.maxWidth;
      final height = size.maxHeight;
      final isTablet = width > 700;
      final hasDetail = detail != null;
      final inset = width * 0.075;
      final headlineTop = height * (isTablet ? 0.085 : 0.09);
      final layout = switch ((isTablet: isTablet, hasDetail: hasDetail)) {
        (isTablet: true, hasDetail: true) => (top: 0.21, bottom: 0.73),
        (isTablet: true, hasDetail: false) => (top: 0.205, bottom: 0.96),
        (isTablet: false, hasDetail: true) => (top: 0.25, bottom: 0.72),
        _ => (top: 0.245, bottom: 0.965),
      };
      final deviceTop = height * layout.top;
      final deviceBottom = height * layout.bottom;
      final detailTop = height * (isTablet ? 0.77 : 0.755);
      final detailHeight = height * (isTablet ? 0.185 : 0.205);
      final scale = math.min(
        width * (isTablet ? 0.8 : 0.82) / frameSize.width,
        (deviceBottom - deviceTop) / frameSize.height,
      );
      final deviceWidth = frameSize.width * scale;
      final deviceHeight = frameSize.height * scale;
      final center =
          width *
          switch (scene) {
            'agent' => 0.53,
            'workspaces' => 0.47,
            _ => 0.5,
          };
      final deviceLeft = center - deviceWidth / 2;
      final deviceY = deviceTop + (deviceBottom - deviceTop - deviceHeight) / 2;
      if (deviceLeft < width * 0.04 ||
          deviceLeft + deviceWidth > width * 0.96 ||
          deviceY + deviceHeight > height * 0.965) {
        throw StateError('Device frame exceeds store canvas');
      }

      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: .topLeft,
            end: .bottomRight,
            colors: _palette,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: height * 0.11,
              right: -width * 0.25,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: .circle,
                ),
                width: width * 0.8,
                height: width * 0.8,
              ),
            ),
            Positioned(
              left: -width * 0.35,
              bottom: height * 0.1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: .circle,
                ),
                width: width * 0.9,
                height: width * 0.9,
              ),
            ),
            Positioned(
              left: inset,
              top: height * (isTablet ? 0.045 : 0.04),
              child: Text(
                'AuraVibes',
                style: .new(
                  inherit: false,
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: isTablet ? 22 : 15,
                  fontWeight: .w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            Positioned(
              left: inset,
              top: headlineTop,
              right: inset,
              child: Text(
                title,
                style: .new(
                  inherit: false,
                  color: Colors.white,
                  fontSize: isTablet ? 48 : 31,
                  fontWeight: .w700,
                  height: 1.08,
                  fontFamily: 'Inter',
                ),
                maxLines: 4,
              ),
            ),
            Positioned(
              left: deviceLeft,
              top: deviceY,
              width: deviceWidth,
              height: deviceHeight,
              child: Image.memory(
                image,
                key: const ValueKey('store_device_frame'),
                fit: .fill,
                filterQuality: .high,
              ),
            ),
            if (detail case final bytes?)
              Positioned(
                left: width * 0.075,
                top: detailTop,
                width: width * 0.85,
                height: detailHeight,
                child: DecoratedBox(
                  key: const ValueKey('store_detail_crop'),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5FA),
                    borderRadius: BorderRadius.circular(isTablet ? 24 : 18),
                    boxShadow: const [
                      BoxShadow(
                        color: .new(0x660A1022),
                        offset: .new(0, 12),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 12 : 7),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isTablet ? 18 : 12),
                      child: Image.memory(
                        bytes,
                        fit: .contain,
                        filterQuality: .high,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _NotionFixture {
  new(this.locale, this.scene);

  final String locale;
  final String scene;
  final DateTime _capturedAt = .now();
  bool get isSpanish => locale == 'es';
  List<String> get workspaceNames => isSpanish
      ? ['Equipo de lanzamiento', 'Casa', 'Viajes']
      : ['Launch team', 'Home', 'Travel'];
  List<ConversationEntity> get otherConversations => [
    for (final title
        in isSpanish
            ? [_es('campaignIdeas'), 'Lista de tareas']
            : ['Campaign ideas', 'Weekly checklist'])
      ConversationEntity(
        id: title.toLowerCase().replaceAll(' ', '-'),
        title: title,
        workspaceId: _workspaceId,
        isPinned: false,
        createdAt: .utc(2026, 9, 26),
        updatedAt: .utc(2026, 9, 26),
      ),
  ];
  String get request => switch (scene) {
    'agent' =>
      isSpanish ? _es('agentRequest') : 'Help me plan my project launch.',
    _ =>
      isSpanish
          ? 'Actualiza el contenido de Plan de lanzamiento en Notion '
                'con una lista de tareas.'
          : 'Update my Launch Plan page in Notion with a task checklist.',
  };
  String get reply => isSpanish
      ? _es('reply')
      : 'I updated the Launch Plan page in Notion with a task checklist: '
            'review the copy, prepare the images, and publish the page.';
  String get headline => switch (scene) {
    'approval' =>
      isSpanish
          ? 'Aprueba las acciones antes de ejecutarlas'
          : 'Approve actions before they run',
    'workspaces' =>
      isSpanish
          ? 'Cada proyecto en su espacio'
          : 'Keep projects in their own space',
    'agent' =>
      isSpanish
          ? 'Un agente para tu forma de trabajar'
          : 'An agent for your workflow',
    'model' =>
      isSpanish ? 'Elige la IA para cada chat' : 'Choose the AI for each chat',
    _ => isSpanish ? 'Haz tareas en tus apps' : 'Get things done in your apps',
  };

  ConversationEntity get conversation => ConversationEntity(
    id: _chatId,
    title: isSpanish ? 'Plan de lanzamiento' : 'Launch Plan',
    workspaceId: _workspaceId,
    isPinned: false,
    createdAt: .utc(2026, 9, 26, 9, 41),
    updatedAt: .utc(2026, 9, 26, 9, 41),
    modelId: _modelId,
    agentId: scene == 'agent' ? _agentId : null,
  );

  MessageToolCallEntity get toolCall => MessageToolCallEntity(
    id: 'notion-update-1',
    name: _toolName,
    argumentsRaw: isSpanish
        ? '{"page":"Plan de lanzamiento", '
              '"change":"Agregar una lista de tareas"}'
        : '{"page":"Launch Plan","change":"Add a task checklist"}',
    responseRaw: scene == 'approval' ? null : '{"updated":true}',
    resultStatus: scene == 'approval' ? null : .success,
  );

  List<MessageEntity> get messages {
    final time = _capturedAt;

    return [
      if (['result', 'approval', 'agent'].contains(scene)) ...[
        MessageEntity(
          id: 'context-request-1',
          conversationId: _chatId,
          content: isSpanish
              ? _es('contextRequest1')
              : 'What should we prepare for launch?',
          messageType: .text,
          isUser: true,
          status: .sent,
          createdAt: time.subtract(const Duration(minutes: 4)),
          updatedAt: time.subtract(const Duration(minutes: 4)),
        ),
        MessageEntity(
          id: 'context-reply-1',
          conversationId: _chatId,
          content: isSpanish
              ? _es('contextReply1')
              : 'We need a page, a checklist, and a review before publishing.',
          messageType: .text,
          isUser: false,
          status: .sent,
          createdAt: time.subtract(const Duration(minutes: 3)),
          updatedAt: time.subtract(const Duration(minutes: 3)),
        ),
        MessageEntity(
          id: 'context-request-2',
          conversationId: _chatId,
          content: isSpanish
              ? _es('contextRequest2')
              : 'Keep the tasks in Launch Plan.',
          messageType: .text,
          isUser: true,
          status: .sent,
          createdAt: time.subtract(const Duration(minutes: 2)),
          updatedAt: time.subtract(const Duration(minutes: 2)),
        ),
        MessageEntity(
          id: 'context-reply-2',
          conversationId: _chatId,
          content: isSpanish
              ? _es('contextReply2')
              : 'I can organize the steps there.',
          messageType: .text,
          isUser: false,
          status: .sent,
          createdAt: time.subtract(const Duration(minutes: 1)),
          updatedAt: time.subtract(const Duration(minutes: 1)),
        ),
      ],
      MessageEntity(
        id: 'request-1',
        conversationId: _chatId,
        content: request,
        messageType: .text,
        isUser: true,
        status: .sent,
        createdAt: time,
        updatedAt: time,
      ),
      if (scene != 'ask')
        MessageEntity(
          id: 'response-1',
          conversationId: _chatId,
          content: switch (scene) {
            'agent' =>
              isSpanish
                  ? _es('agentReply')
                  : 'Here is a simple plan: review the copy today, gather '
                        'the images tomorrow, and publish when everything '
                        'is ready.',
            _ => '',
          },
          messageType: .text,
          isUser: false,
          status: scene == 'approval' ? .unfinished : .sent,
          createdAt: time.add(const Duration(minutes: 1)),
          updatedAt: time.add(const Duration(minutes: 1)),
          metadata: .new(toolCalls: scene == 'agent' ? [] : [toolCall]),
        ),
      if (scene == 'result' || scene == 'done')
        MessageEntity(
          id: 'response-2',
          conversationId: _chatId,
          content: reply,
          messageType: .text,
          isUser: false,
          status: .sent,
          createdAt: time.add(const Duration(minutes: 2)),
          updatedAt: time.add(const Duration(minutes: 2)),
        ),
    ];
  }
}

List<Override> _overrides(_NotionFixture fixture, AppDatabase database) {
  final conversation = fixture.conversation;
  final messages = fixture.messages;
  final repository = _ScreenshotConversationRepository(
    conversation,
    fixture.otherConversations,
  );

  return [
    appDatabaseProvider.overrideWithValue(database),
    cloudAccountsProvider.overrideWith((ref) async => const []),
    workspaceSessionForRouteProvider(_workspaceId).overrideWithValue(
      const AsyncData(
        WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: _workspaceId)),
      ),
    ),
    allWorkspacesProvider.overrideWith(
      (ref) => Stream.value([
        for (final entry in fixture.workspaceNames.asMap().entries)
          WorkspaceEntity(
            id: entry.key == 0 ? _workspaceId : 'demo-workspace-${entry.key}',
            name: entry.value,
            type: .local,
            createdAt: .utc(2026, 9, 26),
            updatedAt: .utc(2026, 9, 26),
          ),
      ]),
    ),
    conversationSelectedProvider.overrideWithValue(_chatId),
    conversationRepositoryProvider.overrideWithValue(repository),
    conversationChatProvider(_workspaceId, _chatId).overrideWith(
      () => _ScreenshotChatNotifier(ConversationFound(conversation)),
    ),
    conversationBusyStateProvider.overrideWith(
      (ref, _) async => ConversationBusyState(
        isStreaming: false,
        hasPendingTools: fixture.scene == 'approval',
      ),
    ),
    chatMessagesProvider.overrideWith((ref, _) => Stream.value(messages)),
    chatMessageIdsProvider.overrideWith(
      (ref, _) => messages.map((message) => message.id).toList(),
    ),
    contextUsageProvider.overrideWith(
      (ref, _) =>
          ContextUsageData.compute(usedTokens: 1240, limitTokens: 128000),
    ),
    pendingToolCallsProvider.overrideWith(
      (ref, _) async => fixture.scene == 'approval'
          ? [
              PendingToolCall(
                toolCall: fixture.toolCall,
                messageId: 'response-1',
              ),
            ]
          : [],
    ),
    toolDisplayNameProvider(_workspaceId, _toolName).overrideWith(
      (ref) async =>
          fixture.isSpanish ? _es('toolName') : 'Notion: Update Page',
    ),
    listModelsGroupedByProviderProvider(workspaceId: _workspaceId)
        .overrideWith((ref) => Stream.value(_demoModels())),
    apiModelProvidersProvider(workspaceId: _workspaceId).overrideWith(
      (ref) async => const <ApiModelProviderEntity>[
        .new(id: 'openai', name: 'OpenAI', type: .openai),
        .new(id: 'anthropic', name: 'Anthropic', type: .anthropic),
      ],
    ),
    workspaceModelSelectionByIdProvider(
      _workspaceId,
      _modelId,
    ).overrideWith((ref) async => _demoModels()['openai']!.first),
    recentModelSelectionsProvider(_workspaceId)
        .overrideWith(_ScreenshotRecentModelsNotifier.new),
    agentsProvider(_workspaceId).overrideWith(
      (ref) => Stream.value([
        AgentEntity(
          id: _agentId,
          workspaceId: _workspaceId,
          name: fixture.isSpanish ? 'Planificador' : 'Project Planner',
          content: 'Help plan and organize projects.',
          skills: const [],
          createdAt: .utc(2026),
          updatedAt: .utc(2026),
        ),
      ]),
    ),
    newChatProvider(_workspaceId).overrideWith(_ScreenshotNewChatNotifier.new),
    workspaceToolsProvider(_workspaceId)
        .overrideWith(_ScreenshotWorkspaceToolsNotifier.new),
    groupedToolsProvider(_workspaceId)
        .overrideWith(_ScreenshotGroupedToolsNotifier.new),
    mcpFormProvider(_workspaceId).overrideWith(_ScreenshotMcpFormNotifier.new),
  ];
}

class _ScreenshotMcpFormNotifier extends McpFormNotifier {
  @override
  McpFormState build(String workspaceId) => const McpFormState(
    name: 'Notion',
    url: 'https://mcp.notion.com/mcp',
    authenticationType: .oauth,
  );
}

WorkspaceToolEntity get _notionTool => WorkspaceToolEntity(
  id: 'notion-tool',
  workspaceId: _workspaceId,
  toolId: _toolName,
  isEnabled: true,
  permissionMode: .alwaysAsk,
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
  description: 'Update a page in Notion',
  workspaceToolsGroupId: 'notion-group',
);

class _ScreenshotWorkspaceToolsNotifier extends WorkspaceToolsNotifier {
  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async => [
    _notionTool,
  ];
}

class _ScreenshotGroupedToolsNotifier extends GroupedToolsNotifier {
  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async => [
    ToolsGroupWithTools(
      group: .new(
        id: 'notion-group',
        workspaceId: _workspaceId,
        name: 'Notion',
        isEnabled: true,
        permissions: .ask,
        createdAt: .utc(2026),
        updatedAt: .utc(2026),
      ),
      tools: [_notionTool],
    ),
  ];
}

Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> _demoModels() =>
    {
      'openai': [
        WorkspaceModelSelectionWithConnectionEntity(
          workspaceModelSelection: .new(
            id: _modelId,
            modelId: 'gpt-5.5',
            modelName: 'GPT 5.5',
            createdAt: .utc(2026),
            updatedAt: .utc(2026),
            modelConnectionId: 'demo-connection',
          ),
          modelConnection: .new(
            id: 'demo-connection',
            name: 'OpenAI',
            modelId: 'openai',
            createdAt: .utc(2026),
            updatedAt: .utc(2026),
            workspaceId: _workspaceId,
            hasKey: true,
          ),
          modelsProvider: const .new(id: 'openai', name: 'OpenAI', type: null),
        ),
      ],
      'anthropic': [
        WorkspaceModelSelectionWithConnectionEntity(
          workspaceModelSelection: .new(
            id: 'demo-claude',
            modelId: 'claude-sonnet-4',
            modelName: 'Claude Sonnet 4',
            createdAt: .utc(2026),
            updatedAt: .utc(2026),
            modelConnectionId: 'demo-anthropic',
          ),
          modelConnection: .new(
            id: 'demo-anthropic',
            name: 'Anthropic',
            modelId: 'anthropic',
            createdAt: .utc(2026),
            updatedAt: .utc(2026),
            workspaceId: _workspaceId,
            hasKey: true,
          ),
          modelsProvider: const .new(
            id: 'anthropic',
            name: 'Anthropic',
            type: .anthropic,
          ),
        ),
      ],
    };

class _ScreenshotNewChatNotifier extends NewChatNotifier {
  @override
  NewChatState build(String workspaceId) =>
      const NewChatState(modelId: _modelId);
}

class _ScreenshotRecentModelsNotifier extends RecentModelSelectionsNotifier {
  @override
  Future<List<String>> build(String workspaceId) async => [];
}

class _ScreenshotChatNotifier(final ConversationResult result)
    extends ConversationChatNotifier {
  @override
  Future<ConversationResult> build(
    String workspaceId,
    String conversationId,
  ) async => result;
}

class _ScreenshotConversationRepository(
  final ConversationEntity conversation,
  final List<ConversationEntity> others,
) implements ConversationRepository {
  @override
  Stream<ConversationEntity?> watchConversationById(String id) =>
      Stream.value(conversation);

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    String? search,
    int? limit,
    int offset = 0,
  }) => Stream.value([conversation, ...others]);

  @override
  Stream<List<ConversationEntity>> watchChildConversations(
    String parentConversationId,
  ) => const Stream.empty();

  @override
  Future<List<ConversationEntity>> getChildConversations(
    String parentConversationId,
  ) async => const [];

  @override
  Future<ConversationEntity?> getConversationById(String id) async =>
      conversation;

  @override
  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) => throw UnimplementedError();

  @override
  Future<bool> deleteConversation(String id) => throw UnimplementedError();

  @override
  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch conversation,
  ) => throw UnimplementedError();

  @override
  Future<ConversationEntity> forkConversation(
    String sourceConversationId, {
    String? throughMessageId,
  }) => throw UnimplementedError();
}
