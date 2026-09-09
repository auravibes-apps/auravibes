import 'dart:math' as math;
import 'dart:typed_data';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/url/safe_image_loader.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

/// Image properties shared by the response and form catalogs.
final chatCatalogImageProperties = <String, Object?>{
  for (final entry
      in (a2uiChatComponentSchemas['Image']!['properties']!
              as Map<String, Object?>)
          .entries)
    if (const [
      'fit',
      'variant',
      'label',
      'width',
      'height',
      'fallbackText',
      'fallbackIcon',
    ].contains(entry.key))
      entry.key: entry.value,
};

/// A literal image example valid in both catalogs.
String chatCatalogImageExample() => '''
[{"id":"root","component":"Image","url":"https://picsum.photos/320/200",
"variant":"normal","label":"Landscape","width":320,"height":200}]
''';

/// Binds image content while keeping presentation separate from its label.
abstract final class ChatCatalogImageAdapter {
  static Widget build(
    CatalogItemContext context, {
    required IconData Function(String?) resolveIcon,
  }) {
    final data = context.data as Map<Object?, Object?>;

    return BoundString(
      dataContext: context.dataContext,
      value: data['url'],
      builder: (_, url) => BoundString(
        dataContext: context.dataContext,
        value: data['label'],
        builder: (_, label) => BoundString(
          dataContext: context.dataContext,
          value: data['fallbackText'],
          builder: (_, fallbackText) => ChatCatalogImage(
            url: url ?? '',
            label: label,
            variant: switch (data['variant']) {
              'circle' => .circle,
              'avatar' => .avatar,
              _ => .normal,
            },
            fit: BoxFit.values.asNameMap()[data['fit']] ?? .cover,
            width: (data['width'] as num?)?.toDouble(),
            height: (data['height'] as num?)?.toDouble(),
            fallbackText: fallbackText,
            fallbackIcon: switch (data['fallbackIcon']) {
              final String icon => resolveIcon(icon),
              _ => null,
            },
          ),
        ),
      ),
    );
  }
}

/// Supported image shapes. Avatars default to a compact circle.
enum ChatCatalogImageVariant { normal, circle, avatar }

/// Validates a public HTTPS image once per URL and reserves bounded space.
class ChatCatalogImage extends StatefulWidget {
  /// Creates a catalog image.
  const new({
    required this.url,
    this.label,
    this.variant = .normal,
    this.fit = .cover,
    this.width,
    this.height,
    this.fallbackText,
    this.fallbackIcon,
    super.key,
  });

  final String url;
  final String? label;
  final ChatCatalogImageVariant variant;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? fallbackText;
  final IconData? fallbackIcon;

  @override
  State<ChatCatalogImage> createState() => _ChatCatalogImageState();
}

class _ChatCatalogImageState extends State<ChatCatalogImage> {
  final _loader = SafeImageLoader();
  Future<Uint8List>? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _loader.load(widget.url);
  }

  @override
  void didUpdateWidget(covariant ChatCatalogImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = _loader.load(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final circular = widget.variant != ChatCatalogImageVariant.normal;
    final defaultWidth = widget.variant == ChatCatalogImageVariant.avatar
        ? 48.0
        : 240.0;
    final width = _dimension(widget.width, defaultWidth);
    final height = _dimension(widget.height, circular ? width : 160);

    return LayoutBuilder(
      builder: (_, constraints) {
        final boundedWidth = math.min(width, constraints.maxWidth);
        final boundedHeight = math.min(height, constraints.maxHeight);
        final side = math.min(boundedWidth, boundedHeight);
        final image = FutureBuilder<Uint8List>(
          key: ValueKey(widget.url),
          future: _bytes,
          builder: (_, snapshot) {
            if (snapshot.hasError) {
              return _ImageStatus(
                error: true,
                fallbackText: widget.fallbackText,
                fallbackIcon: widget.fallbackIcon,
              );
            }
            final bytes = snapshot.data;
            if (bytes == null) return const _ImageStatus();

            return AuraImage(
              url: widget.url,
              key: ValueKey(widget.url),
              fit: widget.fit,
              semanticLabel: widget.label,
              imageProvider: MemoryImage(bytes),
              loadingChild: const _ImageStatus(),
              errorChild: _ImageStatus(
                error: true,
                fallbackText: widget.fallbackText,
                fallbackIcon: widget.fallbackIcon,
              ),
            );
          },
        );

        return Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          heightFactor: 1,
          child: SizedBox(
            width: circular ? side : boundedWidth,
            height: circular ? side : boundedHeight,
            child: circular ? ClipOval(child: image) : ClipRect(child: image),
          ),
        );
      },
    );
  }
}

double _dimension(double? value, double fallback) =>
    value == null || !value.isFinite ? fallback : value.clamp(1, 1024);

class _ImageStatus extends StatelessWidget {
  const new({this.error = false, this.fallbackText, this.fallbackIcon});

  final bool error;
  final String? fallbackText;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final defaultText =
        (error
                ? LocaleKeys.chats_screens_chat_conversation_a2ui_image_error
                : LocaleKeys.chats_screens_chat_conversation_a2ui_image_loading)
            .tr(context: context);
    final fallback = fallbackText;
    final text = error && fallback?.trim().isNotEmpty == true
        ? fallback ?? defaultText
        : defaultText;
    final icon =
        fallbackIcon ??
        (error ? Icons.broken_image_outlined : Icons.hourglass_empty);

    return Semantics(
      child: ColoredBox(
        color: context.auraColors.surfaceVariant,
        child: LayoutBuilder(
          builder: (_, constraints) => Center(
            child: constraints.maxWidth < 96 || constraints.maxHeight < 48
                ? FittedBox(child: AuraIcon(icon))
                : Text(
                    text,
                    textAlign: .center,
                    overflow: .ellipsis,
                    maxLines: 2,
                  ),
          ),
        ),
      ),
      container: true,
      excludeSemantics: true,
      liveRegion: true,
      label: text,
    );
  }
}
