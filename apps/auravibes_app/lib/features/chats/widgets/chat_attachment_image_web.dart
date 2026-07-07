import 'package:flutter/material.dart';

class ChatAttachmentImage extends StatelessWidget {
  const ChatAttachmentImage({required this.localPath, super.key});

  final String localPath;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 180, height: 140);
  }
}
