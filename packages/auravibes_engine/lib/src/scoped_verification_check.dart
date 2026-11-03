import 'package:auravibes_engine/src/scoped_verification_json.dart';

/// An owner-configured argv command. Reported paths remain separate data.
final class ScopedVerificationCheck {
  new({
    required this.id,
    required this.executable,
    List<String> arguments = const [],
    List<String> pathSuffixes = const [],
  }) : arguments = verificationStrings(
         arguments,
         maxEntries: 64,
         maxBytes: 1024,
         allowEmpty: true,
       ),
       pathSuffixes = verificationStrings(
         pathSuffixes,
         maxEntries: 16,
         maxBytes: 128,
       ) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(id)) {
      throw const FormatException('Invalid verification check ID.');
    }
    final _ = verificationString(executable, maxBytes: 1024);
  }

  factory fromJson(Object? value) {
    final json = verificationObject(value, const {
      'id',
      'executable',
      'arguments',
      'pathSuffixes',
    });

    return ScopedVerificationCheck(
      id: verificationString(json['id'], maxBytes: 64),
      executable: verificationString(json['executable'], maxBytes: 1024),
      arguments: verificationStrings(
        json['arguments'],
        maxEntries: 64,
        maxBytes: 1024,
        allowEmpty: true,
      ),
      pathSuffixes: verificationStrings(
        json['pathSuffixes'],
        maxEntries: 16,
        maxBytes: 128,
      ),
    );
  }

  final String id;
  final String executable;
  final List<String> arguments;
  final List<String> pathSuffixes;

  Map<String, Object?> toJson() => {
    'id': id,
    'executable': executable,
    'arguments': arguments,
    'pathSuffixes': pathSuffixes,
  };
}
