import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

UrlResponse _responseForStatus(int statusCode) {
  return UrlResponse(
    statusCode: statusCode,
    body: '',
    headers: const {},
    elapsed: Duration.zero,
  );
}

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

    test('classifies response status boundaries', () {
      const okCases = [(200, true), (299, true), (300, false), (404, false)];
      const redirectCases = [
        (301, true),
        (399, true),
        (200, false),
        (400, false),
      ];
      const clientErrorCases = [
        (404, true),
        (400, true),
        (499, true),
        (200, false),
        (500, false),
      ];
      const serverErrorCases = [
        (500, true),
        (502, true),
        (200, false),
        (404, false),
      ];

      for (final (statusCode, expected) in okCases) {
        expect(
          _responseForStatus(statusCode).isOk,
          expected,
          reason: 'isOk at $statusCode',
        );
      }
      for (final (statusCode, expected) in redirectCases) {
        expect(
          _responseForStatus(statusCode).isRedirect,
          expected,
          reason: 'isRedirect at $statusCode',
        );
      }
      for (final (statusCode, expected) in clientErrorCases) {
        expect(
          _responseForStatus(statusCode).isClientError,
          expected,
          reason: 'isClientError at $statusCode',
        );
      }
      for (final (statusCode, expected) in serverErrorCases) {
        expect(
          _responseForStatus(statusCode).isServerError,
          expected,
          reason: 'isServerError at $statusCode',
        );
      }
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
