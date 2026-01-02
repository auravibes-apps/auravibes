import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Service for secure storage of API keys using UUID references
class SecureStorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: .first_unlock,
    ),
    mOptions: MacOsOptions(accessibility: .first_unlock),
  );

  static const String _apiKeyPrefix = 'api_key_';

  /// Generates a new UUID for storing an API key
  static String generateKeyUUID() {
    const uuid = Uuid();
    return uuid.v4();
  }

  /// Stores an API key securely using a UUID reference
  /// Returns the UUID that can be stored in the database
  static Future<String> storeApiKey(String apiKey) async {
    final keyUUID = generateKeyUUID();
    final secureKey = _apiKeyPrefix + keyUUID;

    try {
      await _secureStorage.write(key: secureKey, value: apiKey);
      return keyUUID;
    } catch (e) {
      throw SecureStorageException('Failed to store API key: $e');
    }
  }

  /// Retrieves an API key using its UUID reference
  /// Returns the API key if found, null otherwise
  static Future<String?> getApiKey(String keyUUID) async {
    if (keyUUID.isEmpty) return null;

    final secureKey = _apiKeyPrefix + keyUUID;

    try {
      final apiKey = await _secureStorage.read(key: secureKey);
      return apiKey;
    } catch (e) {
      throw SecureStorageException('Failed to retrieve API key: $e');
    }
  }

  /// Updates an existing API key using its UUID reference
  /// Returns true if successful, false if key not found
  static Future<bool> updateApiKey(String keyUUID, String newApiKey) async {
    if (keyUUID.isEmpty) return false;

    final secureKey = _apiKeyPrefix + keyUUID;

    try {
      // Check if key exists first
      final existingKey = await _secureStorage.read(key: secureKey);
      if (existingKey == null) return false;

      await _secureStorage.write(key: secureKey, value: newApiKey);
      return true;
    } catch (e) {
      throw SecureStorageException('Failed to update API key: $e');
    }
  }

  /// Deletes an API key using its UUID reference
  /// Returns true if successful, false if key not found
  static Future<bool> deleteApiKey(String keyUUID) async {
    if (keyUUID.isEmpty) return false;

    final secureKey = _apiKeyPrefix + keyUUID;

    try {
      // Check if key exists first
      final existingKey = await _secureStorage.read(key: secureKey);
      if (existingKey == null) return false;

      await _secureStorage.delete(key: secureKey);
      return true;
    } catch (e) {
      throw SecureStorageException('Failed to delete API key: $e');
    }
  }

  /// Checks if an API key exists for the given UUID
  static Future<bool> hasApiKey(String keyUUID) async {
    if (keyUUID.isEmpty) return false;

    final secureKey = _apiKeyPrefix + keyUUID;

    try {
      final apiKey = await _secureStorage.read(key: secureKey);
      return apiKey != null;
    } catch (e) {
      throw SecureStorageException('Failed to check API key existence: $e');
    }
  }

  /// Deletes all API keys from secure storage
  /// Use with caution - this will remove all stored API keys
  static Future<void> deleteAllApiKeys() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to delete all API keys: $e');
    }
  }

  /// Gets all stored API key UUIDs (without exposing the actual keys)
  static Future<List<String>> getAllApiKeyUUIDs() async {
    try {
      final allKeys = await _secureStorage.readAll();
      return allKeys.keys
          .where((key) => key.startsWith(_apiKeyPrefix))
          .map((key) => key.substring(_apiKeyPrefix.length))
          .toList();
    } catch (e) {
      throw SecureStorageException('Failed to retrieve API key UUIDs: $e');
    }
  }

  /// Validates if a string is a valid UUID
  static bool isValidUUID(String uuid) {
    try {
      return Uuid.isValidUUID(fromString: uuid);
    } on FormatException {
      return false;
    }
  }
}

/// Exception thrown when secure storage operations fail
class SecureStorageException implements Exception {
  const SecureStorageException(this.message);
  final String message;

  @override
  String toString() => 'SecureStorageException: $message';
}
