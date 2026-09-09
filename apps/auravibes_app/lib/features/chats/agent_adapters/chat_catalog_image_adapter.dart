import 'dart:math' as math;
import 'dart:typed_data';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/url/safe_image_loader.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

const _compactImageStatusWidth = 96.0;
const _compactImageStatusHeight = 48.0;
const _avatarImageWidth = 48.0;
const _defaultImageWidthValue = 240.0;
const _defaultImageHeight = 160.0;
const _minimumImageDimension = 1.0;
const _maximumImageDimension = 1024.0;
const _fullFactor = 1.0;
const _statusTextMaxLines = 2;

/// Binds image content while keeping presentation separate from its label.
abstract final class ChatCatalogImageAdapter {
  /// Image properties shared by the response and form catalogs.
  static final properties = <String, Object?>{
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
  static String example() => '''
[{"id":"root","component":"Image","url":"https://picsum.photos/320/200",
"variant":"normal","label":"Landscape","width":320,"height":200}]
''';

  static Widget build(
    CatalogItemContext context, {
    required IconData Function(String?) resolveIcon,
  }) {
    final data = context.data as Map<Object?, Object?>;

    return _BoundChatCatalogImage(
      data: data,
      dataContext: context.dataContext,
      resolveIcon: resolveIcon,
    );
  }
}

class _BoundChatCatalogImage extends StatelessWidget {
  const new({
    required this.data,
    required this.dataContext,
    required this.resolveIcon,
  });

  final Map<Object?, Object?> data;
  final DataContext dataContext;
  final IconData Function(String?) resolveIcon;

  @override
  Widget build(BuildContext context) => BoundString(
    dataContext: dataContext,
    value: data['url'],
    builder: (_, url) => _BoundChatCatalogImageLabel(
      data: data,
      dataContext: dataContext,
      resolveIcon: resolveIcon,
      url: url ?? '',
    ),
  );
}

class _BoundChatCatalogImageLabel extends StatelessWidget {
  const new({
    required this.data,
    required this.dataContext,
    required this.resolveIcon,
    required this.url,
  });

  final Map<Object?, Object?> data;
  final DataContext dataContext;
  final IconData Function(String?) resolveIcon;
  final String url;

  @override
  Widget build(BuildContext context) => BoundString(
    dataContext: dataContext,
    value: data['label'],
    builder: (_, label) => _BoundChatCatalogImageFallback(
      data: data,
      dataContext: dataContext,
      resolveIcon: resolveIcon,
      url: url,
      label: label,
    ),
  );
}

class _BoundChatCatalogImageFallback extends StatelessWidget {
  const new({
    required this.data,
    required this.dataContext,
    required this.resolveIcon,
    required this.url,
    required this.label,
  });

  final Map<Object?, Object?> data;
  final DataContext dataContext;
  final IconData Function(String?) resolveIcon;
  final String url;
  final String? label;

  @override
  Widget build(BuildContext context) => BoundString(
    dataContext: dataContext,
    value: data['fallbackText'],
    builder: (_, fallbackText) => _ResolvedChatCatalogImage(
      data: data,
      resolveIcon: resolveIcon,
      url: url,
      label: label,
      fallbackText: fallbackText,
    ),
  );
}

class _ResolvedChatCatalogImage extends StatelessWidget {
  const new({
    required this.data,
    required this.resolveIcon,
    required this.url,
    required this.label,
    required this.fallbackText,
  });

  final Map<Object?, Object?> data;
  final IconData Function(String?) resolveIcon;
  final String url;
  final String? label;
  final String? fallbackText;

  ChatCatalogImageVariant get variant => _imageVariant(data['variant']);

  BoxFit get fit => _imageFit(data['fit']);

  double? get width => (data['width'] as num?)?.toDouble();

  double? get height => (data['height'] as num?)?.toDouble();

  IconData? get fallbackIcon =>
      _imageFallbackIcon(data['fallbackIcon'], resolveIcon);

  @override
  Widget build(BuildContext context) => ChatCatalogImage(
    url: url,
    label: label,
    variant: variant,
    fit: fit,
    width: width,
    height: height,
    fallbackText: fallbackText,
    fallbackIcon: fallbackIcon,
  );
}

ChatCatalogImageVariant _imageVariant(Object? value) => switch (value) {
  'circle' => .circle,
  'avatar' => .avatar,
  _ => .normal,
};

BoxFit _imageFit(Object? value) => BoxFit.values.asNameMap()[value] ?? .cover;

IconData? _imageFallbackIcon(
  Object? value,
  IconData Function(String?) resolveIcon,
) => switch (value) {
  final String icon => resolveIcon(icon),
  _ => null,
};

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
  Widget build(BuildContext context) =>
      _ChatCatalogImageLayout(image: widget, future: _bytes);
}

double _defaultImageWidth(ChatCatalogImageVariant variant) =>
    variant == ChatCatalogImageVariant.avatar
    ? _avatarImageWidth
    : _defaultImageWidthValue;

class _ChatCatalogImageLayout extends StatelessWidget {
  const new({required this.image, required this.future});

  final ChatCatalogImage image;
  final Future<Uint8List>? future;

  @override
  Widget build(BuildContext context) =>
      _ChatCatalogImageSizing(image: image, future: future);
}

class _ChatCatalogImageSizing extends StatelessWidget {
  const new({required this.image, required this.future});

  final ChatCatalogImage image;
  final Future<Uint8List>? future;

  bool get circular => image.variant != ChatCatalogImageVariant.normal;

  double get width =>
      _dimension(image.width, _defaultImageWidth(image.variant));

  double get height =>
      _dimension(image.height, circular ? width : _defaultImageHeight);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) =>
        _ChatCatalogImageConstrained(source: this, constraints: constraints),
  );
}

class _ChatCatalogImageConstrained extends StatelessWidget {
  const new({required this.source, required this.constraints});

  final _ChatCatalogImageSizing source;
  final BoxConstraints constraints;

  double get width => math.min(source.width, constraints.maxWidth);

  double get height => math.min(source.height, constraints.maxHeight);

  @override
  Widget build(BuildContext context) => _ChatCatalogImageFrame(source: this);
}

class _ChatCatalogImageFrame extends StatelessWidget {
  const new({required this.source});

  final _ChatCatalogImageConstrained source;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: _fullFactor,
      heightFactor: _fullFactor,
      child: _ChatCatalogImageBox(source: source),
    );
  }
}

class _ChatCatalogImageBox extends StatelessWidget {
  const new({required this.source});

  final _ChatCatalogImageConstrained source;

  @override
  Widget build(BuildContext context) {
    final side = math.min(source.width, source.height);
    final circular = source.source.circular;

    return SizedBox(
      width: circular ? side : source.width,
      height: circular ? side : source.height,
      child: _ChatCatalogImageShape(source: source.source),
    );
  }
}

class _ChatCatalogImageShape extends StatelessWidget {
  const new({required this.source});

  final _ChatCatalogImageSizing source;

  @override
  Widget build(BuildContext context) {
    final image = _ChatCatalogImageFuture(source: source);

    return source.circular ? ClipOval(child: image) : ClipRect(child: image);
  }
}

class _ChatCatalogImageFuture extends StatelessWidget {
  const new({required this.source});

  final _ChatCatalogImageSizing source;

  String get url => source.image.url;

  BoxFit get fit => source.image.fit;

  String? get label => source.image.label;

  String? get fallbackText => source.image.fallbackText;

  IconData? get fallbackIcon => source.image.fallbackIcon;

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    key: ValueKey(source.image.url),
    future: source.future,
    builder: (_, snapshot) =>
        _ChatCatalogImageSnapshot(source: this, snapshot: snapshot),
  );
}

class _ChatCatalogImageSnapshot extends StatelessWidget {
  const new({required this.source, required this.snapshot});

  final AsyncSnapshot<Uint8List> snapshot;
  final _ChatCatalogImageFuture source;

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return _ImageStatus(
        error: true,
        fallbackText: source.fallbackText,
        fallbackIcon: source.fallbackIcon,
      );
    }
    final bytes = snapshot.data;

    if (bytes == null) return const _ImageStatus();

    return _LoadedChatCatalogImage(source: source, bytes: bytes);
  }
}

class _LoadedChatCatalogImage extends StatelessWidget {
  const new({required this.source, required this.bytes});

  final _ChatCatalogImageFuture source;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) =>
      _LoadedCatalogAuraImage(source: source, bytes: bytes);
}

class _LoadedCatalogAuraImage extends AuraImage {
  new({required this.source, required this.bytes})
    : super(
        url: source.url,
        key: ValueKey(source.url),
        fit: source.fit,
        semanticLabel: source.label,
        imageProvider: MemoryImage(bytes),
        loadingChild: const _ImageStatus(),
        errorChild: _ImageStatus(
          error: true,
          fallbackText: source.fallbackText,
          fallbackIcon: source.fallbackIcon,
        ),
      );

  final _ChatCatalogImageFuture source;
  final Uint8List bytes;
}

double _dimension(double? value, double fallback) =>
    value == null || !value.isFinite
    ? fallback
    : value.clamp(_minimumImageDimension, _maximumImageDimension);

class _ImageStatus extends StatelessWidget {
  const new({this.error = false, this.fallbackText, this.fallbackIcon});

  final bool error;
  final String? fallbackText;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) => _ImageStatusSurface(
    text: _imageStatusText(context, error, fallbackText),
    icon: _imageStatusIcon(error, fallbackIcon),
  );
}

String _imageStatusText(
  BuildContext context,
  bool error,
  String? fallbackText,
) {
  final defaultText =
      (error
              ? LocaleKeys.chats_screens_chat_conversation_a2ui_image_error
              : LocaleKeys.chats_screens_chat_conversation_a2ui_image_loading)
          .tr(context: context);

  return error && fallbackText?.trim().isNotEmpty == true
      ? fallbackText ?? defaultText
      : defaultText;
}

IconData _imageStatusIcon(bool error, IconData? fallbackIcon) =>
    fallbackIcon ??
    (error ? Icons.broken_image_outlined : Icons.hourglass_empty);

class _ImageStatusSurface extends StatelessWidget {
  const new({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    child: ColoredBox(
      color: context.auraColors.surfaceVariant,
      child: _ImageStatusContent(text: text, icon: icon),
    ),
    container: true,
    excludeSemantics: true,
    liveRegion: true,
    label: text,
  );
}

class _ImageStatusContent extends StatelessWidget {
  const new({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => _ImageStatusBody(
      compact: _isCompactImageStatus(constraints),
      icon: icon,
      text: text,
    ),
  );
}

bool _isCompactImageStatus(BoxConstraints constraints) =>
    constraints.maxWidth < _compactImageStatusWidth ||
    constraints.maxHeight < _compactImageStatusHeight;

class _ImageStatusBody extends StatelessWidget {
  const new({required this.compact, required this.icon, required this.text});

  final bool compact;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) =>
      compact ? FittedBox(child: AuraIcon(icon)) : _ImageStatusText(text: text);
}

class _ImageStatusText extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: .center,
    overflow: .ellipsis,
    maxLines: _statusTextMaxLines,
  );
}
