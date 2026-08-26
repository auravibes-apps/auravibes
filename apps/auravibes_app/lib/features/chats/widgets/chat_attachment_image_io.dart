import 'dart:io';

import 'package:flutter/material.dart';

// ignore: unused-code, conditional export implementation used on IO platforms.
class ChatAttachmentImageIo extends StatelessWidget {
  const ChatAttachmentImageIo({required this.localPath, super.key});

  final String localPath;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    const imageWidth = 180.0;
    const imageHeight = 140.0;

    return Image.file(
      File(localPath),
      width: imageWidth,
      height: imageHeight,
      fit: BoxFit.cover,
      cacheWidth: (pixelRatio * imageWidth).round(),
      cacheHeight: (pixelRatio * imageHeight).round(),
    );
  }
}

// ignore: unused-code, conditional export implementation used on IO platforms.
typedef ChatAttachmentImage = ChatAttachmentImageIo;
