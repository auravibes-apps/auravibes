import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toHumanReadable', () {
    test('converts snake_case to human readable', () {
      expect('read_file'.toHumanReadable(), 'Read File');
      expect('my_server_name'.toHumanReadable(), 'My Server Name');
    });

    test('converts camelCase to human readable', () {
      expect('readFile'.toHumanReadable(), 'Read File');
      expect('sendMessage'.toHumanReadable(), 'Send Message');
    });

    test('converts PascalCase to human readable', () {
      expect('MyServer'.toHumanReadable(), 'My Server');
    });

    test('converts kebab-case to human readable', () {
      expect('read-file'.toHumanReadable(), 'Read File');
      expect('my-server-name'.toHumanReadable(), 'My Server Name');
    });

    test('converts UPPER_SNAKE_CASE to human readable', () {
      expect('READ_FILE'.toHumanReadable(), 'Read File');
    });

    test('handles empty string', () {
      expect(''.toHumanReadable(), '');
    });

    test('handles string with mixed separators', () {
      expect('my-server_name'.toHumanReadable(), 'My Server Name');
    });

    test('handles already formatted string', () {
      expect('Hello'.toHumanReadable(), 'Hello');
      expect('Hello World'.toHumanReadable(), 'Hello World');
    });

    test('handles single word', () {
      expect('word'.toHumanReadable(), 'Word');
    });
  });
}
