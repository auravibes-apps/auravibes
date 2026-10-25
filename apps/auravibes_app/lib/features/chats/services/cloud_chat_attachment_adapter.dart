import 'dart:typed_data';

import 'package:auravibes_app/features/chats/services/chatbot/chat_attachment_bytes.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_chat_attachment_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:dio/dio.dart';

class CloudChatAttachmentAdapter({
  required CloudChatGateway gateway,
  Dio? dio,
}) {
  final CloudChatGateway _gateway = gateway;
  final Dio _dio = dio ?? Dio();

  CloudChatAttachmentUsecase createUsecase() => CloudChatAttachmentUsecase(
    beginUpload: _gateway.beginUpload,
    uploadBytes: _uploadBytes,
    completeUpload: _gateway.completeUpload,
    getDownload: _gateway.getDownload,
    deleteObject: _gateway.deleteObject,
    readBytes: _readBytes,
    describeObject: _gateway.describeObject,
  );

  Future<Uint8List> downloadAssetBytes(Uri uri, int expectedBytes) =>
      _BoundedDownload(_dio).call(uri, expectedBytes);

  Future<Uint8List> _readBytes(String localPath) async {
    final bytes = await ChatAttachmentBytes.read(localPath);
    if (bytes == null) throw StateError('Attachment file is unavailable.');

    return Uint8List.fromList(bytes);
  }

  Future<void> _uploadBytes(BeginUploadResult upload, Uint8List bytes) async {
    final response = await _putBytes(upload, bytes);
    _ensureUploadSucceeded(response.statusCode);
  }

  Future<Response<void>> _putBytes(BeginUploadResult upload, Uint8List bytes) {
    return _dio.put<void>(
      upload.uploadUrl,
      data: Stream<List<int>>.value(bytes),
      options: .new(headers: upload.headers),
    );
  }

  void _ensureUploadSucceeded(int? statusCode) {
    final status = statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw StateError('Attachment upload failed.');
    }
  }
}

class const _BoundedDownload(final Dio dio) {
  Future<Uint8List> call(Uri uri, int size) async {
    require(uri, size);

    return await collect(await body(uri), size);
  }

  Future<ResponseBody> body(Uri uri) async {
    final response = await dio.get<ResponseBody>(
      uri.toString(),
      options: .new(
        responseType: .stream,
        followRedirects: false,
        headers: const {'Cache-Control': 'no-store'},
      ),
    );

    return response.data ??
        (throw StateError('Asset download is unavailable.'));
  }

  Future<Uint8List> collect(ResponseBody body, int size) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in body.stream) {
      append(bytes, chunk, size);
    }
    if (bytes.length != size) throw StateError('Asset download is incomplete.');

    return bytes.takeBytes();
  }

  static void append(BytesBuilder bytes, List<int> chunk, int size) {
    if (bytes.length + chunk.length > size) {
      throw StateError('Asset download exceeds its declared size.');
    }
    bytes.add(chunk);
  }

  static void require(Uri uri, int size) {
    if (!uri.isScheme('https') || size <= 0) {
      throw StateError('Invalid private asset download.');
    }
  }
}
