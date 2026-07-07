import 'dart:io';

import 'package:auravibes_app/features/chats/services/attachment_modality.dart';

// ignore: unused-code, conditional export implementation used on IO platforms.
Future<List<int>?> readChatAttachmentBytes(String localPath) async {
  final file = File(localPath);
  if (!file.existsSync()) return null;
  if (await file.length() > maxChatAttachmentBytes) return null;

  return file.readAsBytes();
}
