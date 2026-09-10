import 'dart:typed_data';

import 'package:auravibes_app/services/url/safe_image_loader.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';

/// Loads an avatar only while mounted, retaining initials on failure.
class ChatCatalogAvatar extends StatefulWidget {
  const new({
    required this.name,
    super.key,
    this.url,
    this.size = AuraSpacing.xl2,
  });

  final String name;
  final String? url;
  final AuraSpacing size;

  @override
  State<ChatCatalogAvatar> createState() => _ChatCatalogAvatarState();
}

class _ChatCatalogAvatarState extends State<ChatCatalogAvatar> {
  final _loader = SafeImageLoader();
  Future<Uint8List>? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ChatCatalogAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _load();
  }

  @override
  Widget build(BuildContext context) {
    return _ChatCatalogAvatarImage(
      image: _image,
      initials: _initials(widget.name),
      name: widget.name,
      size: widget.size,
      url: widget.url,
    );
  }

  void _load() {
    final url = widget.url;
    _image = url == null || url.isEmpty ? null : _loader.load(url);
  }
}

String _initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .take(2)
    .map((word) => word.characters.first)
    .join()
    .toUpperCase();

class const _ChatCatalogAvatarImage({
  required final Future<Uint8List>? image,
  required final String initials,
  required final String name,
  required final AuraSpacing size,
  required final String? url,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    key: ValueKey(url),
    future: image,
    builder: (_, snapshot) => _ChatCatalogAvatarContent(
      image: snapshot.data,
      initials: initials,
      name: name,
      size: size,
    ),
  );
}

class const _ChatCatalogAvatarContent({
  required final Uint8List? image,
  required final String initials,
  required final String name,
  required final AuraSpacing size,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraAvatar(
    child: Text(initials),
    imageProvider: image == null ? null : MemoryImage(image),
    semanticLabel: name,
    size: size,
  );
}
