import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/molecules/aura_message_bubble.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/ui.dart' show AuraCornerRadiusScope;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  group('AuraMessageBubble', () {
    testWidgets('renders text message correctly', (tester) async {
      const messageContent = 'Hello, this is a test message';
      final expectedColor = AuraTheme.light.colors.surface;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageBubble(content: messageContent, isUser: true),
          ),
        ),
      );

      expect(find.text(messageContent), findsOneWidget);
      expect(find.byType(GptMarkdown), findsOneWidget);

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, AlignmentDirectional.centerEnd);

      // Find the message container with decoration.
      final containers = tester.widgetList<Container>(find.byType(Container));
      final messageContainer = containers.firstWhere(
        (container) =>
            container.decoration != null &&
            container.decoration is BoxDecoration &&
            ((container.decoration ??
                            fail(
                              'Expected container.decoration to be non-null',
                            ))
                        as BoxDecoration)
                    .color ==
                expectedColor,
      );

      final decoration =
          (messageContainer.decoration ??
                  fail('Expected messageContainer.decoration to be non-null'))
              as BoxDecoration;
      expect(decoration.color, expectedColor);
    });

    testWidgets('uses the neutral surface for assistant messages', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageBubble(
              content: 'Assistant message',
              isUser: false,
            ),
          ),
        ),
      );

      final expectedColor = AuraTheme.light.colors.surfaceVariant;
      final containers = tester.widgetList<Container>(find.byType(Container));
      final messageContainer = containers.firstWhere(
        (container) =>
            container.decoration is BoxDecoration &&
            (container.decoration as BoxDecoration?)?.color == expectedColor,
      );

      expect(
        (messageContainer.decoration as BoxDecoration?)?.color,
        expectedColor,
      );
    });

    testWidgets('provides existing per-content padding defaults', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AuraMessageBubble(content: 'Text', isUser: true),
                AuraMessageBubble(
                  content: 'Image',
                  isUser: true,
                  contentType: .image,
                ),
                AuraMessageBubble(
                  content: 'File',
                  isUser: true,
                  contentType: .file,
                ),
              ],
            ),
          ),
        ),
      );

      const paddings = [
        AuraEdgeInsetsGeometry.symmetric(horizontal: .md, vertical: .sm),
        AuraEdgeInsetsGeometry.all(.xs),
        AuraEdgeInsetsGeometry.small,
      ];
      expect(
        tester.widgetList<AuraCornerRadiusScope>(
          find.byType(AuraCornerRadiusScope),
        ),
        hasLength(6),
      );

      for (var index = 0; index < paddings.length; index++) {
        final bubble = find.byType(AuraMessageBubble).at(index);
        final insets = paddings[index].toEdgeInsets(tester.element(bubble));
        expect(
          find.descendant(
            of: bubble,
            matching: find.byWidgetPredicate(
              (widget) => widget is Padding && widget.padding == insets,
            ),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('derives inner radius from caller padding and theme', (
      tester,
    ) async {
      const contentPadding = AuraEdgeInsetsGeometry.all(.xs);
      final theme = AuraTheme.light.copyWith(globalBorderRadiusLevel: .lg);

      await tester.pumpWidget(
        AuraThemeScope(
          theme: theme,
          child: const MaterialApp(
            home: Scaffold(
              body: AuraMessageBubble(
                content: 'Image',
                isUser: true,
                contentType: .image,
                contentPadding: contentPadding,
              ),
            ),
          ),
        ),
      );

      final scopes = tester.widgetList<AuraCornerRadiusScope>(
        find.byType(AuraCornerRadiusScope),
      );
      expect(scopes, hasLength(2));
      final outerScope = scopes.firstOrNull;
      final innerScope = scopes.skip(1).firstOrNull;
      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(AuraCornerRadiusScope),
          matching: find.byType(Padding),
        ),
      );
      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));

      expect(outerScope?.radius, theme.borderRadius.resolve(.xl));
      expect(
        innerScope?.radius,
        theme.borderRadius.resolve(.xl) - theme.fromSpacing(.xs),
      );
      expect(
        padding.padding,
        contentPadding.toEdgeInsets(
          tester.element(find.byType(AuraMessageBubble)),
        ),
      );
      expect(
        clip.borderRadius,
        BorderRadius.all(
          .circular(theme.borderRadius.resolve(.xl) - theme.fromSpacing(.xs)),
        ),
      );
    });

    testWidgets('corner scope is readable by descendants only', (tester) async {
      double? insideScope;
      double? outsideScope;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Builder(
                builder: (context) {
                  outsideScope = AuraCornerRadiusScope.maybeOf(context);

                  return const SizedBox.shrink();
                },
              ),
              AuraCornerRadiusScope.select(
                level: .xl,
                child: Builder(
                  builder: (context) {
                    insideScope = AuraCornerRadiusScope.maybeOf(context);

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      );
      expect(outsideScope, isNull);
      expect(insideScope, AuraTheme.light.borderRadius.resolve(.xl));
    });

    testWidgets('keeps Markdown links clickable and text selectable', (
      tester,
    ) async {
      String? selectedText;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionArea(
              onSelectionChanged: (content) {
                selectedText = content?.plainText;
              },
              child: const Column(
                children: [
                  AuraMessageBubble(
                    content: '[Open docs](https://example.com)',
                    isUser: true,
                  ),
                  AuraMessageBubble(content: 'selectable', isUser: true),
                ],
              ),
            ),
          ),
        ),
      );

      final linkGesture = await tester.startGesture(
        tester.getCenter(find.text('Open docs')),
        kind: .mouse,
      );
      await tester.pump();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );
      await linkGesture.up();

      final textGesture = await tester.startGesture(
        tester.getCenter(find.text('selectable')),
        kind: .mouse,
      );
      await tester.pump();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.text,
      );
      await textGesture.up();

      await tester.longPress(find.text('selectable'));
      await tester.pump();
      expect(selectedText, 'selectable');
    });

    testWidgets('maps user bubble placement directionally in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: .rtl,
            child: Scaffold(
              body: AuraMessageBubble(content: 'RTL message', isUser: true),
            ),
          ),
        ),
      );

      final message = tester.getRect(find.text('RTL message'));
      expect(message.center.dx, lessThan(400));
    });

    testWidgets('shows status indicators for user messages', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AuraMessageBubble(
                  content: 'Delivered message',
                  isUser: true,
                  status: .delivered,
                ),
                AuraMessageBubble(
                  content: 'Error message',
                  isUser: true,
                  status: .error,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.done_all), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('handles image and file content types', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AuraMessageBubble(
                  content: 'https://example.com/image.jpg',
                  isUser: true,
                  contentType: .image,
                ),
                AuraMessageBubble(
                  content: 'document.pdf',
                  isUser: true,
                  contentType: .file,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
      expect(find.text('document.pdf'), findsOneWidget);
    });

    testWidgets('has GestureDetector for tap and long-press callbacks', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AuraMessageBubble(
                  content: 'Tappable message',
                  isUser: true,
                  onTap: () {
                    final _ = Object();
                  },
                ),
                AuraMessageBubble(
                  content: 'Long pressable message',
                  isUser: true,
                  onLongPress: () {
                    final _ = Object();
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNWidgets(2));
    });

    testWidgets('respects maxWidth constraint', (tester) async {
      const customMaxWidth = 200.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraMessageBubble(
              content: 'Message with custom max width',
              isUser: true,
              maxWidth: customMaxWidth,
            ),
          ),
        ),
      );

      // Find the container with constraints.
      final containers = tester.widgetList<Container>(find.byType(Container));
      final constrainedContainer = containers.firstWhere(
        (container) =>
            container.constraints != null &&
            (container.constraints ??
                        fail('Expected container.constraints to be non-null'))
                    .maxWidth ==
                customMaxWidth,
      );

      final constraints =
          constrainedContainer.constraints ??
          fail('Expected constrained container constraints');
      expect(constraints.maxWidth, customMaxWidth);
    });

    group('AuraMessageContentType enum', () {
      test('has all expected values', () {
        expect(AuraMessageContentType.values, hasLength(3));
        expect(
          AuraMessageContentType.values,
          contains(AuraMessageContentType.text),
        );
        expect(
          AuraMessageContentType.values,
          contains(AuraMessageContentType.image),
        );
        expect(
          AuraMessageContentType.values,
          contains(AuraMessageContentType.file),
        );
      });
    });

    testWidgets('formats relative and supplied timestamps', (tester) async {
      final now = DateTime(2026, 8, 28, 12);
      final clock = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AuraMessageBubble(
                  content: 'Message with timestamp',
                  isUser: true,
                  timestamp: clock.subtract(const Duration(minutes: 5)),
                ),
                AuraMessageBubble(
                  content: 'Mensaje',
                  isUser: true,
                  timestamp: .new(2026, 9, 26),
                  timestampLabel: 'Ahora mismo',
                ),
                AuraMessageBubble(
                  content: 'Fixed timestamp',
                  isUser: true,
                  timestamp: .new(2026, 8, 28, 11, 55),
                  now: () => now,
                ),
                AuraMessageBubble(
                  content: 'Recent message',
                  isUser: true,
                  timestamp: clock.subtract(const Duration(seconds: 30)),
                ),
                AuraMessageBubble(
                  content: 'Half hour old message',
                  isUser: true,
                  timestamp: clock.subtract(const Duration(minutes: 30)),
                ),
                AuraMessageBubble(
                  content: 'Three hours old message',
                  isUser: true,
                  timestamp: clock.subtract(const Duration(hours: 3)),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('5m ago'), findsNWidgets(2));
      expect(find.text('Ahora mismo'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
      expect(find.text('30m ago'), findsOneWidget);
      expect(find.text('3h ago'), findsOneWidget);
    });
  });
}
