import '../object_store.dart';

class InMemoryObjectStore implements ObjectStore {
  final objects = <String, ObjectMetadata>{};

  @override
  Future<void> registerFreshKey({
    required String key,
    required String registrationId,
  }) async {}

  @override
  Future<void> delete(String key, {String? registrationId}) async =>
      objects.remove(key);

  @override
  Future<ObjectMetadata?> head(String key, {String? registrationId}) async =>
      objects[key];

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
    String? registrationId,
  }) async => _signed(key, expiresIn);

  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
    String? registrationId,
  }) async => _signedUntil(key, expiresAt);

  SignedObjectRequest _signed(String key, Duration expiresIn) {
    return _signedUntil(key, DateTime.now().toUtc().add(expiresIn));
  }

  SignedObjectRequest _signedUntil(String key, DateTime expiresAt) {
    return SignedObjectRequest(
      url: Uri.parse('https://object.test/$key'),
      headers: const {},
      expiresAt: expiresAt,
    );
  }

  @override
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
    String? registrationId,
  }) async => true;
}
