// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.

import 'package:auravibes_app/services/tools/native_tool_service.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NativeToolService', () {
    test('getTypes returns url type', () {
      final types = NativeToolService.getTypes();
      expect(types, hasLength(1));
      expect(types, contains(NativeToolType.url));
    });

    test('getTool returns tool for url type', () {
      final tool = NativeToolService.getTool(NativeToolType.url);
      expect(tool, isNotNull);
      expect(tool!.type, NativeToolType.url);
    });

    test('hasTypeString returns true for url', () {
      expect(NativeToolService.hasTypeString('url'), isTrue);
    });

    test('hasTypeString returns false for unknown', () {
      expect(NativeToolService.hasTypeString('nonexistent'), isFalse);
    });
  });

  group('NativeToolType', () {
    test('has url value', () {
      expect(NativeToolType.url.value, 'url');
    });

    test('fromValue returns enum for valid value', () {
      expect(NativeToolType.fromValue('url'), NativeToolType.url);
    });

    test('fromValue returns null for invalid value', () {
      expect(NativeToolType.fromValue('nonexistent'), isNull);
    });
  });
}
