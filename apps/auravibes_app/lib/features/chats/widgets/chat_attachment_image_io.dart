import 'dart:io';

import 'package:flutter/material.dart';

// ignore: unused-code, conditional export implementation used on IO platforms.
class const ChatAttachmentImageIo({required final String localPath, super.key})
    extends StatelessWidget {
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
