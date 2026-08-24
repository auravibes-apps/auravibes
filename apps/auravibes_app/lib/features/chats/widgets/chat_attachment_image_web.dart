import 'package:flutter/material.dart';

class ChatAttachmentImageWeb extends StatelessWidget {
  const ChatAttachmentImageWeb({required this.localPath, super.key});

  final String localPath;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 180, height: 140);
  }
}

typedef ChatAttachmentImage = ChatAttachmentImageWeb;
