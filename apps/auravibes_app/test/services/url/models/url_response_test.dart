// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
import 'package:auravibes_app/services/url/models/url_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrlResponse', () {
    const okResponse = UrlResponse(
      statusCode: 200,
      body: 'OK',
      headers: {
        'Content-Type': ['text/html'],
      },
      elapsed: Duration(milliseconds: 100),
    );

    const redirectResponse = UrlResponse(
      statusCode: 301,
      body: '',
      headers: {},
      elapsed: Duration(milliseconds: 50),
    );

    const clientErrorResponse = UrlResponse(
      statusCode: 404,
      body: 'Not Found',
      headers: {},
      elapsed: Duration(milliseconds: 75),
    );

    const serverErrorResponse = UrlResponse(
      statusCode: 500,
      body: 'Internal Server Error',
      headers: {},
      elapsed: Duration(seconds: 2),
    );

    group('isOk', () {
      test('true for 200', () {
        expect(okResponse.isOk, isTrue);
      });

      test('true for 299', () {
        const response = UrlResponse(
          statusCode: 299,
          body: '',
          headers: {},
          elapsed: Duration.zero,
        );
        expect(response.isOk, isTrue);
      });

      test('false for 300', () {
        expect(redirectResponse.isOk, isFalse);
      });

      test('false for 404', () {
        expect(clientErrorResponse.isOk, isFalse);
      });
    });

    group('isRedirect', () {
      test('true for 301', () {
        expect(redirectResponse.isRedirect, isTrue);
      });

      test('true for 399', () {
        const response = UrlResponse(
          statusCode: 399,
          body: '',
          headers: {},
          elapsed: Duration.zero,
        );
        expect(response.isRedirect, isTrue);
      });

      test('false for 200', () {
        expect(okResponse.isRedirect, isFalse);
      });

      test('false for 400', () {
        expect(clientErrorResponse.isRedirect, isFalse);
      });
    });

    group('isClientError', () {
      test('true for 404', () {
        expect(clientErrorResponse.isClientError, isTrue);
      });

      test('true for 400', () {
        const response = UrlResponse(
          statusCode: 400,
          body: '',
          headers: {},
          elapsed: Duration.zero,
        );
        expect(response.isClientError, isTrue);
      });

      test('true for 499', () {
        const response = UrlResponse(
          statusCode: 499,
          body: '',
          headers: {},
          elapsed: Duration.zero,
        );
        expect(response.isClientError, isTrue);
      });

      test('false for 200', () {
        expect(okResponse.isClientError, isFalse);
      });

      test('false for 500', () {
        expect(serverErrorResponse.isClientError, isFalse);
      });
    });

    group('isServerError', () {
      test('true for 500', () {
        expect(serverErrorResponse.isServerError, isTrue);
      });

      test('true for 502', () {
        const response = UrlResponse(
          statusCode: 502,
          body: '',
          headers: {},
          elapsed: Duration.zero,
        );
        expect(response.isServerError, isTrue);
      });

      test('false for 200', () {
        expect(okResponse.isServerError, isFalse);
      });

      test('false for 404', () {
        expect(clientErrorResponse.isServerError, isFalse);
      });
    });

    test('properties are correct', () {
      expect(okResponse.statusCode, 200);
      expect(okResponse.body, 'OK');
      expect(okResponse.headers, {
        'Content-Type': ['text/html'],
      });
      expect(okResponse.elapsed, const Duration(milliseconds: 100));
    });
  });
}
