import 'package:flutter/material.dart';

// ignore: unused-code, conditional export implementation used on IO platforms.
class const ChatAttachmentImageIo({
  required final String localPath,
  final double width = 180,
  final double height = 140,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return Image.file(
      .new(localPath),
      errorBuilder: _buildErrorPlaceholder,
      width: width,
      height: height,
      fit: .cover,
      cacheWidth: (pixelRatio * width).round(),
      cacheHeight: (pixelRatio * height).round(),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext _, Object _, StackTrace? _) {
    return SizedBox(
      width: width,
      height: height,
      child: const Icon(Icons.broken_image_outlined),
    );
  }
}

// ignore: unused-code, conditional export implementation used on IO platforms.
typedef ChatAttachmentImage = ChatAttachmentImageIo;
