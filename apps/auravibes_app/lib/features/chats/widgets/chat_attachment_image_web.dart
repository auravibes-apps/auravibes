import 'package:flutter/material.dart';

class const ChatAttachmentImageWeb({
  required final String localPath,
  final double width = 180,
  final double height = 140,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height);
  }
}

typedef ChatAttachmentImage = ChatAttachmentImageWeb;
