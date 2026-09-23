import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Compatibility access to API keys stored by releases before database
/// encryption was introduced.
class LegacyApiKeyStorage {
  static final RegExp _legacyReferencePattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-'
    r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  LegacyApiKeyStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  bool isLegacyReference(String value) =>
      _legacyReferencePattern.hasMatch(value);

  Future<String?> read(String reference) =>
      _secureStorage.read(key: _storageKey(reference));

  Future<void> delete(String reference) =>
      _secureStorage.delete(key: _storageKey(reference));

  String _storageKey(String reference) => 'api_key_$reference';
}
