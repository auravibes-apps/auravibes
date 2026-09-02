import 'package:flutter/material.dart';

class const ChatAttachmentImageWeb({required final String localPath, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 180, height: 140);
  }
}

typedef ChatAttachmentImage = ChatAttachmentImageWeb;
