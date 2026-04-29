import 'package:auravibes_app/services/mcp_service/oauth_authenticate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OauthAuthenticate.validateGetCode additional', () {
    late OauthAuthenticate auth;

    setUp(() {
      auth = OauthAuthenticate(
        callbackUrlScheme: 'test',
        clientName: 'TestApp',
      );
    });

    test('handles URL with additional query parameters', () {
      final code = OauthAuthenticate.validateGetCode(
        urlResult: 'test:/?state=abc&code=xyz&extra=param',
        stateParam: 'abc',
      );
      expect(code, 'xyz');
    });

    test('handles URL with fragment', () {
      final code = OauthAuthenticate.validateGetCode(
        urlResult: 'test:/?state=abc&code=xyz#fragment',
        stateParam: 'abc',
      );
      expect(code, 'xyz');
    });

    test('handles complex error with description', () {
      expect(
        () => OauthAuthenticate.validateGetCode(
          urlResult:
              'test:/?error=invalid_request&error_description=Missing+parameter',
          stateParam: 'abc',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OauthAuthenticate construction', () {
    test('stores callbackUrlScheme', () {
      final auth = OauthAuthenticate(
        callbackUrlScheme: 'myapp',
        clientName: 'MyApp',
      );
      expect(auth.callbackUrlScheme, 'myapp');
    });

    test('stores clientName', () {
      final auth = OauthAuthenticate(
        callbackUrlScheme: 'myapp',
        clientName: 'MyApp',
      );
      expect(auth.clientName, 'MyApp');
    });
  });
}
