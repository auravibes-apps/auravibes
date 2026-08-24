import 'dart:typed_data';

import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_chat_attachment_usecase.dart';
import 'package:auravibes_app/services/chatbot_service/chat_attachment_bytes.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:dio/dio.dart';

class CloudChatAttachmentAdapter {
  CloudChatAttachmentAdapter({
    required this._gateway,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final CloudChatGateway _gateway;
  final Dio _dio;

  CloudChatAttachmentUsecase createUsecase() => CloudChatAttachmentUsecase(
    beginUpload: _gateway.beginUpload,
    uploadBytes: _uploadBytes,
    completeUpload: _gateway.completeUpload,
    getDownload: _gateway.getDownload,
    deleteObject: _gateway.deleteObject,
    readBytes: _readBytes,
  );

  Future<Uint8List> _readBytes(String localPath) async {
    final bytes = await ChatAttachmentBytes.read(localPath);
    if (bytes == null) throw StateError('Attachment file is unavailable.');

    return Uint8List.fromList(bytes);
  }

  Future<void> _uploadBytes(BeginUploadResult upload, Uint8List bytes) async {
    final response = await _dio.put<void>(
      upload.uploadUrl,
      data: Stream<List<int>>.value(bytes),
      options: Options(
        headers: upload.headers,
      ),
    );
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw StateError('Attachment upload failed.');
    }
  }
}
