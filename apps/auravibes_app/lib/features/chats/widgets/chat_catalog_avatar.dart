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

  void _load() {
    final url = widget.url;
    _image = url == null || url.isEmpty ? null : _loader.load(url);
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();

    return FutureBuilder<Uint8List>(
      key: ValueKey(widget.url),
      future: _image,
      builder: (_, snapshot) => AuraAvatar(
        child: Text(initials),
        imageProvider: snapshot.data == null
            ? null
            : MemoryImage(snapshot.requireData),
        semanticLabel: widget.name,
        size: widget.size,
      ),
    );
  }
}
