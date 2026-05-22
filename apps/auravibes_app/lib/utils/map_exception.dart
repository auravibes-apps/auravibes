sealed class MapException implements Exception {}

class NoKeyMapException implements MapException {
  NoKeyMapException(this.key);
  final String key;

  @override
  String toString() => 'MapNoEntry: map has no key $key';
}

class NoTypeMapException implements MapException {
  NoTypeMapException(this.key, this.type);
  final String key;
  final Type type;

  @override
  String toString() => 'MapNoEntry: map has no key $key with type $type';
}

bool _isNullable<T>() => null is T;

extension MapGetter on Map<String, dynamic> {
  T get<T>(String key) {
    final nullable = _isNullable<T>();
    if (nullable && !containsKey(key)) {
      return null as T;
    }

    if (!containsKey(key)) {
      throw NoKeyMapException(key);
    }
    if (this[key] is! T) {
      throw NoTypeMapException(key, T);
    }
    return this[key] as T;
  }
}
