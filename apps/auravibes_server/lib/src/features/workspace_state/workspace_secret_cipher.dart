import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

class const EncryptedWorkspaceSecret({
  required final ByteData ciphertext,
  required final ByteData nonce,
  required final ByteData authenticationTag,
});

class const WorkspaceSecretCipher() {
  Future<EncryptedWorkspaceSecret> encrypt(
    Session session,
    String value, {
    required int workspaceId,
    required String resourceId,
  }) async {
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(value),
      secretKey: SecretKey(_key(session)),
      aad: _aad(workspaceId, resourceId),
    );
    return EncryptedWorkspaceSecret(
      ciphertext: _byteData(box.cipherText),
      nonce: _byteData(box.nonce),
      authenticationTag: _byteData(box.mac.bytes),
    );
  }

  Future<String> decrypt(Session session, WorkspaceSecret secret) async {
    if (secret.algorithm != 'AES-256-GCM' || secret.keyVersion != 1) {
      throw StateError('Unsupported workspace secret encryption.');
    }
    final clear = await AesGcm.with256bits().decrypt(
      SecretBox(
        _bytes(secret.ciphertext),
        nonce: _bytes(secret.nonce),
        mac: Mac(_bytes(secret.authenticationTag)),
      ),
      secretKey: SecretKey(_key(session)),
      aad: _aad(secret.workspaceId, secret.resourceId),
    );
    return utf8.decode(clear);
  }

  List<int> _key(Session session) {
    final key = base64Decode(session.passwords['workspaceSecretKey'] ?? '');
    if (key.length != 32) {
      throw StateError('workspaceSecretKey must be 32 bytes');
    }
    return key;
  }

  List<int> _aad(int workspaceId, String resourceId) =>
      utf8.encode('$workspaceId:$resourceId');

  ByteData _byteData(List<int> value) =>
      ByteData.sublistView(Uint8List.fromList(value));

  Uint8List _bytes(ByteData value) => value.buffer.asUint8List(
    value.offsetInBytes,
    value.lengthInBytes,
  );
}
