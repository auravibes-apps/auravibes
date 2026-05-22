import 'package:auravibes_app/services/mcp_service/o_auth_authenticate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OAuthAuthenticate.validateGetCode additional', () {
    test('handles URL with additional query parameters', () {
      final code = OAuthAuthenticate.validateGetCode(
        urlResult: 'test:/?state=abc&code=xyz&extra=param',
        stateParam: 'abc',
      );
      expect(code, 'xyz');
    });

    test('handles URL with fragment', () {
      final code = OAuthAuthenticate.validateGetCode(
        urlResult: 'test:/?state=abc&code=xyz#fragment',
        stateParam: 'abc',
      );
      expect(code, 'xyz');
    });

    test('handles complex error with description', () {
      expect(
        () => OAuthAuthenticate.validateGetCode(
          urlResult:
              'test:/?error=invalid_request&error_description=Missing+parameter',
          stateParam: 'abc',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OAuthAuthenticate construction', () {
    test('stores callbackUrlScheme', () {
      final auth = OAuthAuthenticate(
        callbackUrlScheme: 'myapp',
        clientName: 'MyApp',
      );
      expect(auth.callbackUrlScheme, 'myapp');
    });

    test('stores clientName', () {
      final auth = OAuthAuthenticate(
        callbackUrlScheme: 'myapp',
        clientName: 'MyApp',
      );
      expect(auth.clientName, 'MyApp');
    });
  });
}
