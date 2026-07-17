import '../object_store.dart';

class InMemoryObjectStore implements ObjectStore {
  final objects = <String, ObjectMetadata>{};

  @override
  Future<void> delete(String key) async => objects.remove(key);

  @override
  Future<ObjectMetadata?> head(String key) async => objects[key];

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
  }) async => _signed(key, expiresIn);

  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required Duration expiresIn,
  }) async => _signed(key, expiresIn);

  SignedObjectRequest _signed(String key, Duration expiresIn) {
    final expiresAt = DateTime.now().toUtc().add(expiresIn);
    return SignedObjectRequest(
      url: Uri.parse('https://object.test/$key'),
      headers: const {},
      expiresAt: expiresAt,
    );
  }
}
