import 'dart:io';

import 'package:flutter/material.dart';

// ignore: unused-code, conditional export implementation used on IO platforms.
class ChatAttachmentImage extends StatelessWidget {
  const ChatAttachmentImage({required this.localPath, super.key});

  final String localPath;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return Image.file(
      File(localPath),
      width: 180,
      height: 140,
      fit: BoxFit.cover,
      cacheWidth: (pixelRatio * 180).round(),
      cacheHeight: (pixelRatio * 140).round(),
    );
  }
}
