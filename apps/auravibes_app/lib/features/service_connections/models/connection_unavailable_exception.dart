/// The requested connection or its required credential type no longer exists.
class ConnectionUnavailableException implements Exception {
  const new();

  String get localizationKey => 'connection_setup.connection_missing';

  @override
  String toString() => 'ConnectionUnavailableException: $localizationKey';
}
